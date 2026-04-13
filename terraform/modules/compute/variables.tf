# Compute Module Variables

# Project identification variables (passed from root)
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# Networking variables (passed from networking module outputs)
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets for ASG placement"
  type        = list(string)
}

# Security variables (passed from security module outputs)
variable "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile for IAM role"
  type        = string
}

# AMI Configuration
variable "custom_ami_id" {
  description = "ID of the custom AMI with backend code baked in"
  type        = string
}

# Instance Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# Storage variables (passed from storage module outputs)
variable "players_table_name" {
  description = "Name of the players DynamoDB table"
  type        = string
}

variable "leaderboard_table_name" {
  description = "Name of the leaderboard DynamoDB table"
  type        = string
}

# Auto Scaling Configuration
variable "asg_min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
}

