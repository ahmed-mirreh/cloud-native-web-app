# Routing Module Outputs

# CloudFront Distribution
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

# Application Load Balancer
output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer for CloudWatch monitoring"
  value       = aws_lb.main.arn_suffix
}