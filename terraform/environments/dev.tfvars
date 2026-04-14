project_name = "nba-higher-lower-game"
environment  = "dev"
aws_region   = "us-east-1"

# Sensitive values - will be prompted interactively
# alert_email_address = "prompt-during-apply"
# rapidapi_key        = "prompt-during-apply"

instance_type = "t2.micro"

vpc_cidr                = "192.168.0.0/16"
availability_zones      = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs     = ["192.168.83.0/24", "192.168.84.0/24"]
private_subnet_cidrs    = ["192.168.81.0/24", "192.168.82.0/24"]

asg_min_size         = 1
asg_max_size         = 3
asg_desired_capacity = 2
