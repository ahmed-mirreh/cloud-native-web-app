# Routing Module Variables

# Project identification variables (passed from root)
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# Networking variables (passed from networking module outputs)
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets for ALB placement"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets for private ALB placement"
  type        = list(string)
}

# Security variables (passed from security module outputs)
variable "ec2_security_group_id" {
  description = "ID of the EC2 security group for ALB egress rules"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group from security module"
  type        = string
}

# VPC Endpoint Policy (from security module)
variable "dynamodb_vpc_endpoint_policy" {
  description = "JSON policy document for DynamoDB VPC endpoint"
  type        = string
}

# Compute variables (passed from compute module outputs)
variable "target_group_arn" {
  description = "ARN of the target group for ALB listener"
  type        = string
}

# Storage variables (passed from storage module outputs)
variable "frontend_bucket_id" {
  description = "ID of the frontend S3 bucket"
  type        = string
}

variable "frontend_bucket_domain_name" {
  description = "Domain name of the frontend S3 bucket"
  type        = string
}

variable "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  type        = string
}

# Missing variables for DynamoDB VPC endpoint
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "private_route_table_ids" {
  description = "IDs of the private route tables for VPC endpoint"
  type        = list(string)
}


# VPC Origin is now created in Terraform, no external variable needed