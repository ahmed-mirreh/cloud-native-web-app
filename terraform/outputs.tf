output "app_domain" {
  description = "Main application domain - use this to access your NBA Higher Lower Game"
  value       = "https://${module.routing.cloudfront_distribution_domain_name}"
}

# CloudFront domain (for API configuration in frontend)
output "cloudfront_domain" {
  description = "CloudFront distribution domain name (without https://) for API configuration"
  value       = module.routing.cloudfront_distribution_domain_name
}

# S3 bucket name for AWS CLI uploads
output "s3_bucket_name" {
  description = "S3 bucket name for frontend file uploads via AWS CLI"
  value       = module.storage.frontend_bucket_id
}

# AWS region for all resources
output "aws_region" {
  description = "AWS region where all resources are deployed"
  value       = var.aws_region
}

