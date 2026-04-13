project_name = "nba-higher-lower-game"
environment  = "dev"
aws_region   = "us-east-1"

alert_email_address = "you-email@example.com"
rapidapi_key        = "placeholder-will-be-overridden-by-env-var"

instance_type = "t2.micro"

vpc_cidr                = "192.168.0.0/16"
availability_zones      = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs     = ["192.168.83.0/24", "192.168.84.0/24"]
private_subnet_cidrs    = ["192.168.81.0/24", "192.168.82.0/24"]

asg_min_size         = 1
asg_max_size         = 3
asg_desired_capacity = 2
