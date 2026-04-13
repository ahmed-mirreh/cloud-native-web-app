# Security Module Outputs

# Security Groups
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

# VPC Endpoint Policy for DynamoDB
output "dynamodb_vpc_endpoint_policy" {
  description = "JSON policy for DynamoDB VPC endpoint"
  value       = data.aws_iam_policy_document.dynamodb_vpc_endpoint.json
}