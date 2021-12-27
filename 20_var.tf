variable "web" {
  type = list
  default = ["aws_instance.hb_web1.id","aws_instance.hb_web2.id"]
}

variable "was_cidr" {
  type = list
  default = ["10.0.4.0/24","10.0.5.0/24"]
}