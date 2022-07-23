
data "archive_file" "filezip" {
  type        = "zip"
  source_file = "index.js"
  output_path = var.lambda_zip
}


resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = var.lambda_zip
  function_name = var.lambda_function_name
  role          = var.role_arn
  handler       = "index.hello"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("${var.lambda_zip}")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}