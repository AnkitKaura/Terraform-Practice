data  "aws_iam_policy_document" "assume_dev_deploy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "AWS"
            identifiers = ["arn:aws:iam::${var.aws_account_number_devops}:root"]
        }
    }
}

data "aws_iam_policy_document" "dev_deploy" {
    statement {
        effect = "Allow"
        actions = ["lambda:*"]
        resources = [
            "arn:aws:lambda:us-east-1:${var.aws_account_number_devops}:function:tf-lambda-modular_v1",
            "arn:aws:lambda:us-east-1:${var.aws_account_number_devops}:function:tf-lambda-modular_v1:*"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "iam:GetRole",
            "iam:PassRole"
        ]
        resources = [
            "arn:aws:iam::${var.aws_account_number_devops}:role/test_lambda_v1"
        ] 
    }
    statement {
        effect = "Allow"
        resources = [
            "arn:aws:logs:us-east-1:${var.aws_account_number_devops}:log-group:*:log-stream:*"
        ]
        actions = ["*"]
    }
    statement {
        effect = "Allow"
        actions = [
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DescribeAlarm",
            "cloudwatch:ListTagsForResource",
            "cloudwatch:DeleteAlarms"
        ]
        resources = [
            "arn:aws:cloudwatch:us-east-1:${var.aws_account_number_devops}:alarm:*"
        ]
    }
    # statement {
    #     effect = "Allow"
    #     actions = [
    #         "sns:ListTopics",
    #         "sns:Subscribe",
    #         "sns:GetSubscriptionAttributes",
    #         "sns:Unsubscribe",
    #         "sns:SetSubscriptionAttributes"
    #     ]
    #     resources = [
    #         "arn:aws:sns:us-east-1:${var.aws_account_number_devops}:*"
    #     ]

    # }
    # statement {
    #     effect ="Allow"
    #     actions = ["sqs:*"]
    #     resources = [
    #         "arn:aws:sqs:us-east-1:${var.aws_account_number_devops}:"
    #     ]
    # }
}

resource "aws_iam_role" "dev_deploy" {
    name = "test_version_2_role"
    assume_role_policy = data.aws_iam_policy_document.assume_dev_deploy.json
}

resource "aws_iam_policy" "dev_deployment01" {
    name = "test_provision_role_policy_v2"
    policy = data.aws_iam_policy_document.dev_deploy.json
}

resource "aws_iam_role_policy_attachment" "dev_deploy_01" {
    role = aws_iam_role.dev_deploy.name
    policy_arn = aws_iam_policy.dev_deployment01.arn
}

output "provision_role_arn" {
    value = aws_iam_role.dev_deploy.arn
}