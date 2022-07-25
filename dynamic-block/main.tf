terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

/**
without dynamic block we need to write same block each time
*/

resource "aws_security_group" "my_sg" {
  name = "dynamic_sample_sg"

  dynamic "ingress" {
    for_each = var.sg_groups
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}