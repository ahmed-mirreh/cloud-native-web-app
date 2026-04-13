

# NBA Higher Lower Game - Main Infrastructure Configuration

# Step 1: Networking Module - VPC, Subnets, Internet Gateway, Route Tables
module "networking" {
  source = "./modules/networking"

  # Project identification
  project_name = var.project_name
  environment  = var.environment

  # Network configuration
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
}

# Step 2: Storage Module - S3, DynamoDB, IAM Policies
module "storage" {
  source = "./modules/storage"

  # Project identification
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

# Step 3: Security Module - IAM Roles, Security Groups, Parameter Store
module "security" {
  source = "./modules/security"

  # Project identification
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # Networking dependencies (from networking module)
  vpc_id   = module.networking.vpc_id
  vpc_cidr = var.vpc_cidr

  # API Configuration
  rapidapi_key = var.rapidapi_key

  # Storage dependencies (from storage module)
  players_table_arn     = module.storage.players_table_arn
  leaderboard_table_arn = module.storage.leaderboard_table_arn
}

# Step 4: Compute Module - EC2 Auto Scaling Group, Target Group
module "compute" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  instance_type = var.instance_type

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  ec2_security_group_id      = module.security.ec2_security_group_id
  ec2_instance_profile_name  = module.security.ec2_instance_profile_name

  players_table_name     = module.storage.players_table_name
  leaderboard_table_name = module.storage.leaderboard_table_name

  # Auto Scaling Configuration
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity
}

# Step 5: Routing Module - DynamoDB VPC Endpoint, ALB, CloudFront
module "routing" {
  source = "./modules/routing"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id                   = module.networking.vpc_id
  public_subnet_ids        = module.networking.public_subnet_ids
  private_subnet_ids       = module.networking.private_subnet_ids
  private_route_table_ids  = module.networking.private_route_table_ids

  ec2_security_group_id = module.security.ec2_security_group_id
  alb_security_group_id = module.security.alb_security_group_id

  # VPC Endpoint Policy (from security module)
  dynamodb_vpc_endpoint_policy = module.security.dynamodb_vpc_endpoint_policy

  frontend_bucket_id          = module.storage.frontend_bucket_id
  frontend_bucket_arn         = module.storage.frontend_bucket_arn
  frontend_bucket_domain_name = module.storage.frontend_bucket_domain_name

  target_group_arn = module.compute.target_group_arn
}

# Step 6: Monitoring Module - CloudWatch Alarms, SNS Alerts
module "monitoring" {
  source = "./modules/monitoring"

  # Project identification
  project_name = var.project_name
  environment  = var.environment

  # Alert configuration
  alert_email = var.alert_email_address

  # Routing dependencies (from routing module)
  cloudfront_distribution_id = module.routing.cloudfront_distribution_id

  # Compute dependencies (for Auto Scaling alarms)
  autoscaling_group_name = module.compute.autoscaling_group_name
  scale_up_policy_arn    = module.compute.scale_up_policy_arn
  scale_down_policy_arn  = module.compute.scale_down_policy_arn
}

