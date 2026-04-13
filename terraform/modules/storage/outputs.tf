# Storage Module Outputs

# S3 Buckets
output "frontend_bucket_id" {
  description = "ID of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_domain_name" {
  description = "Domain name of the frontend S3 bucket suitable for CloudFront OAC"
  value       = "${aws_s3_bucket.frontend.bucket}.s3.${var.aws_region}.amazonaws.com"
}

# DynamoDB Tables
output "players_table_name" {
  description = "Name of the players DynamoDB table"
  value       = aws_dynamodb_table.players.name
}

output "players_table_arn" {
  description = "ARN of the players DynamoDB table"
  value       = aws_dynamodb_table.players.arn
}

output "leaderboard_table_name" {
  description = "Name of the leaderboard DynamoDB table"
  value       = aws_dynamodb_table.leaderboard.name
}

output "leaderboard_table_arn" {
  description = "ARN of the leaderboard DynamoDB table"
  value       = aws_dynamodb_table.leaderboard.arn
}