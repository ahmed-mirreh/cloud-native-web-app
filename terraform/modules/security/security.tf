# Security Module - Main Configuration

# EC2 Security Group - Allow traffic from ALB and outbound internet access
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for EC2 instances - ALB and API access"
  vpc_id      = var.vpc_id

  # Outbound rules - Internet access for API calls
  egress {
    description = "HTTPS for API calls & VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS resolution
  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
    Type = "EC2"
  }
}


data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ALB Security Group - Only allow traffic from CloudFront
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer - CloudFront access only"
  vpc_id      = var.vpc_id

  # Inbound rules - CloudFront IP ranges (still needed for VPC Origins)
  ingress {
    description = "HTTP from CloudFront (VPC Origins still use CF IPs)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  # Outbound rules - Allow communication to EC2 instances
  egress {
    description     = "HTTP to EC2 instances"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
    Type = "ALB"
  }
}

# EC2 Ingress Rule - Allow traffic from ALB
resource "aws_security_group_rule" "ec2_ingress_from_alb" {
  type                     = "ingress"
  description              = "HTTP from ALB"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.alb.id
}


# IAM Role for EC2 instances to access DynamoDB
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}


# Attach SSM managed policy to EC2 role
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent managed policy to EC2 role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-profile"
  }
}

# SSM Parameter for RapidAPI Key
resource "aws_ssm_parameter" "rapidapi_key" {
  name  = "/nba-stats/${var.environment}/rapidapi-key"
  type  = "SecureString"
  value = var.rapidapi_key
  description = "RapidAPI key for NBA statistics API access"

  tags = {
    Name = "${var.project_name}-${var.environment}-rapidapi-key"
    Environment = var.environment
  }
}

# IAM Policy for DynamoDB access (specific table permissions)
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.project_name}-${var.environment}-dynamodb-policy"
  description = "Policy for EC2 to access specific DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read-only access to Players table
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem"
        ]
        Resource = var.players_table_arn
      },
      {
        # Read/Write access to Leaderboard table
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = var.leaderboard_table_arn
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-dynamodb-policy"
  }
}

# Attach DynamoDB policy to EC2 role (from security module)
resource "aws_iam_role_policy_attachment" "ec2_dynamodb" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# VPC Endpoint Policy for DynamoDB - Allow all DynamoDB actions within VPC
data "aws_iam_policy_document" "dynamodb_vpc_endpoint" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["dynamodb:*"]
    resources = ["*"]
  }
}