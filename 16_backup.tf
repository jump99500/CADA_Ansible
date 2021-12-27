resource "aws_iam_role" "cd_dlm_lf_role" {
  name = "cd-dlm-lf-role"
 
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
 
resource "aws_iam_role_policy" "cd_dlm_lf_policy" {
  name = "cd-dlm-lf-policy"
  role = "${aws_iam_role.cd_dlm_lf_role.id}"
 
  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateSnapshot",
            "ec2:DeleteSnapshot",
            "ec2:DescribeInstances",
            "ec2:DescribeVolumes",
            "ec2:DescribeSnapshots"
         ],
         "Resource": "*"
      },
      {
         "Effect": "Allow",
         "Action": [
            "ec2:CreateTags"
         ],
         "Resource": "arn:aws:ec2:*::snapshot/*"
      }
   ]
}
EOF
}
 
resource "aws_dlm_lifecycle_policy" "cd_dlm_lf" {
  description        = "DLM lifecycle policy"
  execution_role_arn = "${aws_iam_role.cd_dlm_lf_role.arn}"
  state              = "ENABLED"
 
  policy_details {
    resource_types = ["VOLUME"]
 
    schedule {
      name = "2 weeks of daily snapshots"
 
      create_rule {
        interval      = 3
        interval_unit = "HOURS"
        times         = ["23:45"]
      }
 
      retain_rule {
        count = 5
      }
 
      tags_to_add = {
        SnapshotCreator = "DLM"
      }
 
      copy_tags = false
    }
 
    target_tags = {
      Name = "cd-ebs"
    }
  }
}