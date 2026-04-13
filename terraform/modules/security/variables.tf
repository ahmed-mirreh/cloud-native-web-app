# Security Module Variables

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

# Networking variables (passed from root or networking outputs)
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

# API Configuration
variable "rapidapi_key" {
  description = "RapidAPI key for basketball API"
  type        = string
  sensitive   = true
}

# DynamoDB Tables (passed from storage module)
variable "players_table_arn" {
  description = "ARN of the players DynamoDB table"
  type        = string
}

variable "leaderboard_table_arn" {
  description = "ARN of the leaderboard DynamoDB table"
  type        = string
}