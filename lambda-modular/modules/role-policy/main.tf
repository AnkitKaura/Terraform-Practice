resource "aws_iam_role" "lambda_role" {
  name               = var.lambda_role_name
  assume_role_policy = file("../modules/iam/lambda-assume-policy.json")

}



resource "aws_iam_role_policy" "lambda_policy" {
  name = var.lambda_policy_name
  role = aws_iam_role.lambda_role.id

  policy = file("../modules/iam/lambda-policy.json")

}

resource "aws_iam_role_policy_attachment" "basic_lambda_perms" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = var.basicLambdaRole
}


output "role_arn" {
  value = aws_iam_role.lambda_role.arn
}