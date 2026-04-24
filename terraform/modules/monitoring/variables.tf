# Monitoring Module Variables

# Project identification variables (passed from root)
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# Alert configuration
variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  sensitive   = true
}

# ALB configuration (passed from routing module)
variable "alb_arn_suffix" {
  description = "ALB ARN suffix for monitoring (e.g., app/my-alb/1234567890123456)"
  type        = string
}

# Auto Scaling configuration (passed from compute module)
variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  type        = string
}

variable "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  type        = string
}