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



module "role_creator" {
  source             = "../modules/role-policy"
  lambda_role_name   = "lambda_role"
  lambda_policy_name = "lambda_policy"
  basicLambdaRole    = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "lambda_creator" {
  source   = "../modules/lambda"
  role_arn = module.role_creator.role_arn # this is the issue
}
