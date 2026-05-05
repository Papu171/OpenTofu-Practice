terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── S3 Bucket ────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "transactions" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "transactions" {
  bucket = aws_s3_bucket.transactions.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ─── ZIPs de las Lambdas ──────────────────────────────────────────────────────
data "archive_file" "validate" {
  type        = "zip"
  source_file = "${path.module}/lambdas/validate/lambda_function.py"
  output_path = "${path.module}/lambdas/validate/lambda.zip"
}

data "archive_file" "risk_assess" {
  type        = "zip"
  source_file = "${path.module}/lambdas/risk_assess/lambda_function.py"
  output_path = "${path.module}/lambdas/risk_assess/lambda.zip"
}

data "archive_file" "route" {
  type        = "zip"
  source_file = "${path.module}/lambdas/route/lambda_function.py"
  output_path = "${path.module}/lambdas/route/lambda.zip"
}

# ─── Módulo Lambda ────────────────────────────────────────────────────────────
module "lambda_validate" {
  source        = "./modules/lambda_function"
  function_name = "${var.project_name}-validate"
  filename      = data.archive_file.validate.output_path
  role_arn      = aws_iam_role.lambda_role.arn
}

module "lambda_risk_assess" {
  source        = "./modules/lambda_function"
  function_name = "${var.project_name}-risk-assess"
  filename      = data.archive_file.risk_assess.output_path
  role_arn      = aws_iam_role.lambda_role.arn
}

module "lambda_route" {
  source        = "./modules/lambda_function"
  function_name = "${var.project_name}-route"
  filename      = data.archive_file.route.output_path
  role_arn      = aws_iam_role.lambda_role.arn
  environment_variables = {
    BUCKET_NAME = aws_s3_bucket.transactions.bucket
  }
}