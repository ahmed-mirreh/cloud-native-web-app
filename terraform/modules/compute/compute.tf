# CloudWatch Log Group for Application Logging (created before instances)
resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}/application"
  retention_in_days = 1  # Keep logs for 1 day only to control costs

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-logs"
  }
}

# Launch Template for EC2 instances
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  description   = "Launch template for NBA Higher Lower Game backend"
  image_id      = var.custom_ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [var.ec2_security_group_id]
  
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }
  
  # User data script from template file
  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    project_name              = var.project_name
    environment              = var.environment
    players_table_name       = var.players_table_name
    leaderboard_table_name   = var.leaderboard_table_name
    aws_region              = var.aws_region
  }))
  
  # Storage configuration
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
      volume_type = "gp3"
      encrypted   = true
      delete_on_termination = true
    }
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-backend"
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-lt"
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    path                = "/api/health"
    matcher             = "200"
    port                = 8000
    protocol            = "HTTP"
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier = var.private_subnet_ids  # Launch instances in private subnets across AZs
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"  
  
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  
  health_check_grace_period = 180
  
  default_instance_warmup = 120
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = false
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "SimpleScaling"
}