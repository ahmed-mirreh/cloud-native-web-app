project_name = "nba-higher-lower-game"
environment  = "stage"
aws_region   = "us-east-1"

# Sensitive values - will be prompted interactively
# alert_email_address = "prompt-during-apply"
# rapidapi_key        = "prompt-during-apply"

instance_type = "t3.small"

vpc_cidr                = "192.169.0.0/16"
availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs     = ["192.169.84.0/24", "192.169.85.0/24", "192.169.86.0/24"]
private_subnet_cidrs    = ["192.169.81.0/24", "192.169.82.0/24", "192.169.83.0/24"]

asg_min_size         = 1
asg_max_size         = 5
asg_desired_capacity = 2
