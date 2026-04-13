# Compute Module Outputs

# Target Group (for ALB in routing module)
output "target_group_arn" {
  description = "ARN of the target group for ALB attachment"
  value       = aws_lb_target_group.app.arn
}

# Auto Scaling Group (for monitoring)
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

# Auto Scaling Policies (for monitoring alarms)
output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "ARN of the scale down policy"
  value       = aws_autoscaling_policy.scale_down.arn
}

