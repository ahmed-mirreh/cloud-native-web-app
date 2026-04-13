# DynamoDB Gateway Endpoint (FREE)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = var.private_route_table_ids

  policy = var.dynamodb_vpc_endpoint_policy

  tags = {
    Name = "${var.project_name}-${var.environment}-dynamodb-endpoint"
    Type = "Gateway"
  }
}

# Application Load Balancer - Private (for CloudFront VPC Origin)
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ALB HTTP Listener (CloudFront to ALB communication)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-http-listener"
  }
}

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "Origin Access Control for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront VPC Origin for ALB
resource "aws_cloudfront_vpc_origin" "alb_vpc_origin" {
  vpc_origin_endpoint_config {
    name                         = "${var.project_name}-${var.environment}-alb-vpc-origin"
    arn                         = aws_lb.main.arn
    http_port                   = 80
    https_port                  = 443
    origin_protocol_policy      = "http-only"
    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-vpc-origin"
  }
}


# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  http_version        = "http2"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }
  
  # S3 Origin (Frontend)
  origin {
    domain_name              = var.frontend_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = "S3-${var.frontend_bucket_id}"
    connection_attempts      = 3
    connection_timeout       = 10
  }

  # ALB Origin (Backend API) with VPC Origin Config
  origin {
    domain_name         = aws_lb.main.dns_name
    origin_id           = "alb-vpc-origin"
    connection_attempts = 3
    connection_timeout  = 10

    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.alb_vpc_origin.id
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  # Default cache behavior (S3 Frontend) - Minimal caching
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.frontend_bucket_id}"
    compress               = false
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 300    # 5 minutes minimal caching
    max_ttl                = 3600   # 1 hour max

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # API behavior (ALB Backend) - Use managed cache policy for better performance
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb-vpc-origin"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "83da9c7e-98b4-4e11-a168-04f0df8e2c65"  # UseOriginCacheControlHeaders
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = var.frontend_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.frontend_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}