resource "aws_vpc" "cd_vpc_peer" {          #vpc생성
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "cd-vpc_peer"
  }
}


resource "aws_subnet" "cd_dbpeer1" {  #서브넷 생성
  vpc_id            = aws_vpc.cd_vpc_peer.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    "Name" = "cd-dbpeer1"
  }
}

resource "aws_subnet" "cd_dbpeer2" {
  vpc_id            = aws_vpc.cd_vpc_peer.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    "Name" = "cd-dbpeer2"
  }
}

data "aws_caller_identity" "current" {}   #aws count id

##peering##
resource "aws_vpc_peering_connection" "vpc_peering" {   #peering connection
  vpc_id = aws_vpc.cd_vpc_peer.id
  peer_owner_id = data.aws_caller_identity.current.id
  peer_vpc_id = aws_vpc.cd_vpc.id
  auto_accept = true

  tags = {
    Name = "vpc-peering"
  }
  depends_on = [
    aws_vpc.cd_vpc, #main vpc
    aws_vpc.cd_vpc_peer #peering vpc
  ]

  requester {
    allow_remote_vpc_dns_resolution = true   #요청권한 
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

#라우트테이블 생성

resource "aws_route" "r1" {#서브vpc-메인 vpc 간의 rt생성
  route_table_id = "${aws_vpc.cd_vpc_peer.main_route_table_id}" 
  destination_cidr_block = "${aws_vpc.cd_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.vpc_peering.id}"
}

resource "aws_route" "r2" {#메인vpc-서브 vpc 간의 rt생성
  route_table_id = "${aws_vpc.cd_vpc.main_route_table_id}"
  destination_cidr_block = "${aws_vpc.cd_vpc_peer.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.vpc_peering.id}"
}

resource "aws_route" "r3" {#메인rt와 서브vpc를 묶음
  route_table_id = aws_route_table.cd_rt.id
  destination_cidr_block = "${aws_vpc.cd_vpc_peer.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.vpc_peering.id}"
}

resource "aws_route" "r4" {#메인ngwrt와 서브 vpc를 묶음
  route_table_id = aws_route_table.cd_ngwrt.id
  destination_cidr_block = "${aws_vpc.cd_vpc_peer.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.vpc_peering.id}"
}


#보안그룹 생성
resource "aws_security_group" "sg_peer_db" {
  name        = "cd-sg-peer-db"
  description = "sg for peer-db"
  vpc_id      = aws_vpc.cd_vpc_peer.id

ingress = [
    {
      description      = "ssh-bastion"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [aws_security_group.sg_bastion.id]
      prefix_list_ids  = null
      self             = null
    },
    {
      description      = "tomcat"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "web"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
        {
      description      = "redis"
      from_port        = 6379
      to_port          = 6379
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "mysql"
      from_port        = 3306
      to_port          = 3306
      protocol         = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]
  egress = [
    {
      description      = ""
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]

  tags = {
    Name = "cd-sg-db"
  }
}