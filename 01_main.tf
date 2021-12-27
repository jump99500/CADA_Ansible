provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "cd_vpc" {
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "cd-vpc"
  }
}