project_name = "nba-higher-lower-game"
environment  = "prod"
aws_region   = "us-east-1"

alert_email_address = "you-email@example.com"
rapidapi_key        = "c9c5c16c19502dd0d94210b75ec8102b"

instance_type = "t3.medium"

vpc_cidr                = "192.170.0.0/16" 
availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs     = ["192.169.84.0/24", "192.169.85.0/24", "192.169.86.0/24"]
private_subnet_cidrs    = ["192.170.81.0/24", "192.170.82.0/24", "192.170.83.0/24"]

asg_min_size         = 2 
asg_max_size         = 10
asg_desired_capacity = 3
