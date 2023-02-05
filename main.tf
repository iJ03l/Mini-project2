terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# variable "my-access-key" {}
# variable "my-secret-key" {}

provider "aws" {
  region  = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
#  access_key = "my-access-key"
#  secret_key = "my-secret-key"
}

#resource "aws_key_pair" "deployer" {
#  key_name   = "deployer"
#  public_key = file("/vagrant/Terraform-exe/ijo3l.pem")
#}

resource "aws_instance" "app_server" {
  count = 3

  ami           = "ami-0778521d914d23bc1"
  instance_type = "t2.micro"
  key_name      = "deployer"

  tags = {
    Name = "UbuntuInstance"
  }
}


resource "aws_elb" "ij03l_min-lb" {
  name            = "ubuntu-elb"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

    health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances = aws_instance.app_server.*.id
}

resource "aws_route53_record" "example" {
  zone_id = "Z01087833PNJ5PMZ43TR"
  name    = "teraform-test"
  type    = "CNAME"
  alias {
    name                   = "${aws_elb.ij03l_min-lb.dns_name}"
    zone_id               = "${aws_elb.ij03l_min-lb.zone_id}"
    evaluate_target_health = true
  }
}


data "template_file" "host-inventory" {
  template = "${join("\n", aws_instance.app_server.*.public_ip)}"
}

output "host-inventory" {
  value = "${data.template_file.host-inventory.rendered}"
}

# resource "local_file" "instance_ips" {
#  content  = "${data.template_file.instance_ips.rendered}"
#  filename = "host-inventory"
# }
