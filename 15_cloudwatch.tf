# 정책을 위한 역할 생성
resource "aws_iam_role" "cd_role" {
    name = "cd-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid    = ""
            Principal = {
                Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
# cloudwatch, ec2, logs, s3위한 정책 생성
resource "aws_iam_role_policy" "cd_policy" {
  name = "cd-policy"
  role = aws_iam_role.cd_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "cloudwatch:PutMetricData",
            "ec2:DescribeVolumes",
            "ec2:DescribeTags",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# cloudwatch 정책 생성
resource "aws_iam_policy" "cloudWatch_logs" {
  name        = "cloudWatch-logs-policy"
  path        = "/"
  description = "cloudWatch logs policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource":[
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
  })
}
# CPUUtilization > 80 이상이면 알람 
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_80" {
  alarm_name                = "terraform-test-ec2-cpu-80"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []
}

# 
resource "aws_cloudwatch_event_rule" "console" {
  name        = "capture-aws-sign-in"
  description = "Capture each AWS Console Sign In"

  event_pattern = <<EOF
{
  "detail-type": [
    "AWS Console Sign In via CloudTrail"
  ]
}
EOF
}
# 
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.console.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_logins.arn
}
# 트리거 : AWS console logins
resource "aws_sns_topic" "aws_logins" {
  name = "aws-console-logins"
}
# 위에 대한 정책
resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.aws_logins.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}
# AWS console logins을 했다고 sns 발송
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.aws_logins.arn]
  }
}

# AWS Cloudwatch Dashboard
# InstanceId 수정, region 수정
# InstanceId 변수처리를 해서 집어넣으면 됌, db의 인스턴스 id는 어떻게 해야 할까?
/*
resource "aws_cloudwatch_dashboard" "web_dashboard" {
  dashboard_name = "web-dashboard"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "i-0708a87dd4e103047"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "ap-northeast-2",
        "title": "EC2 Instance CPU"
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 7,
      "width": 3,
      "height": 3,
      "properties": {
        "markdown": "web-dashboard"
      }
    }
  ]
}
EOF
}
##
resource "aws_cloudwatch_dashboard" "was_dashboard" {
  dashboard_name = "was-dashboard"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "i-009f90b02fd579a86"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "ap-northeast-2",
        "title": "EC2 Instance CPU"
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 7,
      "width": 3,
      "height": 3,
      "properties": {
        "markdown": "was-dashboard"
      }
    }
  ]
}
EOF
}
*/