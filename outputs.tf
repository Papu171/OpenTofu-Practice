output "state_machine_arn" {
  value = aws_sfn_state_machine.banking_processor.arn
}

output "bucket_name" {
  value = aws_s3_bucket.transactions.bucket
}

output "lambda_validate_arn" {
  value = module.lambda_validate.function_arn
}

output "lambda_risk_assess_arn" {
  value = module.lambda_risk_assess.function_arn
}

output "lambda_route_arn" {
  value = module.lambda_route.function_arn
}