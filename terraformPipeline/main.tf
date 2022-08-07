terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "provision_role" {
  source = "../modules/provision_role"
  aws_account_number_devops = var.aws_account_number_devops
}
/*This s3 bucket is used to store artifacts like tfstate files etc*/
resource "aws_s3_bucket" "output" {
  bucket = "ankit-pipeline-bucket-testing-v2"
  acl    = "private"
}

/*
    create Assume Code build role policy and add it to build role 
*/
data "aws_iam_policy_document" "assume_cbd__provision_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cbd_build_role" {
  name               = "cbd_build_stage_role_testing_v2"
  assume_role_policy = data.aws_iam_policy_document.assume_cbd__provision_role.json
}

resource "aws_iam_role" "cbd_provision" {
  name               = "cbd_provision_stage_role_testing_v2"
  assume_role_policy = data.aws_iam_policy_document.assume_cbd__provision_role.json
}

/***********************************************************************************
    create Assume code pipeline role policy 
*************************************************************************************/
# Create json doc for assume role

data "aws_iam_policy_document" "assume_cpl_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}


#create json doc for codepipeline to access code build and provision role
data "aws_iam_policy_document" "cpl_access" {
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      aws_codebuild_project.build.arn,
      aws_codebuild_project.provision.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      module.provision_role.provision_role_arn //var.dev_deployment_role # refers to provision_role folder   module.dev_deployment_role.
    ]
  }
}

# create new role for code pipeline and assume role with code pipeline permission
resource "aws_iam_role" "cpl_role" {
  name               = "code_pipline_role_testing_v2"
  assume_role_policy = data.aws_iam_policy_document.assume_cpl_role.json
}

# create a policy to access cpl and add json doc
resource "aws_iam_policy" "cpl_access" {
  name   = "code_pipeline_policy_testing_v2"
  policy = data.aws_iam_policy_document.cpl_access.json
}

# attach the above policy to above created role (attaching policy with codepipeline role)
resource "aws_iam_role_policy_attachment" "cpl_access" {
  role       = aws_iam_role.cpl_role.name
  policy_arn = aws_iam_policy.cpl_access.arn
}

/*
    create Regular access control for all builds
*/

data "aws_iam_policy_document" "cbd_build" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [aws_s3_bucket.output.arn, "${aws_s3_bucket.output.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "cbd_build" {
  name        = "code_build_policy_testing_v2"
  description = "Standard build access for code build"
  policy      = data.aws_iam_policy_document.cbd_build.json
}

resource "aws_iam_role_policy_attachment" "cbd_build_access" {
  role       = aws_iam_role.cbd_build_role.name
  policy_arn = aws_iam_policy.cbd_build.arn
}

resource "aws_iam_role_policy_attachment" "cbd_provision_access" {
  role       = aws_iam_role.cbd_provision.name
  policy_arn = aws_iam_policy.cbd_build.arn
}

resource "aws_iam_role_policy_attachment" "cdb_cpl_access" {
  role       = aws_iam_role.cbd_provision.name
  policy_arn = aws_iam_policy.cpl_access.arn
}
/* providing build  permission access to code pipeline */
resource "aws_iam_role_policy_attachment" "cpl_build_access" {
  role       = aws_iam_role.cpl_role.name
  policy_arn = aws_iam_policy.cbd_build.arn
}



/****************************************************************
    create code pipeline
****************************************************************/

resource "aws_codestarconnections_connection" "my_codestar" {
  name = "test-ankit-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "code_pipline_using_terraform_tf_testing_v2"
  role_arn = aws_iam_role.cpl_role.arn
  artifact_store {
    location = aws_s3_bucket.output.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["sourceOutput"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.my_codestar.arn
        FullRepositoryId = "Terraform-Practice"
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["sourceOutput"]
      output_artifacts = ["buildOutput"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Provision"
    action  {
      name            = "Provision"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["sourceOutput", "buildOutput"]
      version         = "1"
      configuration = {
        ProjectName   = aws_codebuild_project.provision.name
        PrimarySource = "sourceOutput"
      }
    }
  }
}

/**********************************************************************
            CODE BUILD PHASE
***********************************************************************/

resource "aws_codebuild_project" "build" {
  name          = "code_build_testing_v2"
  description   = "code build"
  build_timeout = "120"
  service_role  = aws_iam_role.cbd_build_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.output.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "GITHUB_BRANCH"
      value = "master"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/build/code_build_testing_v2"
      stream_name = "code_build_testing_v2"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/buildspec.yml"
  }
}

/**********************************************************************
            CODE PROVISION PHASE
***********************************************************************/

resource "aws_codebuild_project" "provision" {
  name          = "code_provision_testing_v2"
  build_timeout = "120"
  service_role  = aws_iam_role.cbd_provision.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  cache {
    type     = "S3"
    location = aws_s3_bucket.output.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "S3_FOR_TERRAFORM_STATE"
      value = join("", ["s3://", aws_s3_bucket.output.bucket, "/terraform_state"])
    }
    environment_variable {
      name  = "TERRAFORM_DEPLOYMENT_ROLE"
      value = module.provision_role.provision_role_arn
    }
    environment_variable {
      name  = "TERRAFORM_WORKSPACE"
      value = "dev"
    }


  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/provisioning/code_provision_testing_v2"
      stream_name = "code_provision_testing_v2"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/buildspecTerraform.yml"
  }
}