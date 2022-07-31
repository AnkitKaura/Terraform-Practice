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

variable "lambda_zip" {
  default = "lambda_function_payload.zip"
}

variable "lambda_function_name" {
  default = "tf-lambda-modular_v1"
}

resource "random_string" "r" {
  length = 16
  special = false
}

data "archive_file" "filezip" {
  type        = "zip"
  source_dir  = "lambda"
  output_path = "dist/lambda-archive.zip"
  depends_on = [
    random_string.r
  ]
}

resource "aws_iam_role" "lambda_role" {
  name = "test_lambda_v1"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "lambda_policy" {
  name = "test_policy_v1"
  role = aws_iam_role.lambda_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1655960029514",
      "Action": "cloudwatch:*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "basic_lambda_perms" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  filename = data.archive_file.filezip.output_path
  source_code_hash =  data.archive_file.filezip.output_base64sha256

  runtime = "nodejs14.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}