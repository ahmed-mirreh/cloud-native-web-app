# Storage Module - Main Configuration

# S3 Bucket for Frontend Static Files (Private - CloudFront OAC access only)
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-${var.environment}-frontend-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend"
    Environment = var.environment
    Type        = "Frontend"
  }
}

# Random suffix for bucket names to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Frontend bucket versioning
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Frontend bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for frontend bucket (CloudFront OAC will access it)
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# DynamoDB Table - Players (Read-only for EC2)
resource "aws_dynamodb_table" "players" {
  name           = "${var.project_name}-${var.environment}-players"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "player_name"

  attribute {
    name = "player_name"
    type = "S"  # String for player name
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-players"
    Environment = var.environment
    Type        = "Players"
  }
}

# DynamoDB Table - Leaderboard (Read/Write for EC2)
resource "aws_dynamodb_table" "leaderboard" {
  name           = "${var.project_name}-${var.environment}-leaderboard"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_name"

  attribute {
    name = "user_name"
    type = "S"  # String for username
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-leaderboard"
    Environment = var.environment
    Type        = "Leaderboard"
  }
}