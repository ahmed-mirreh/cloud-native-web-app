#!/bin/bash
# EC2 User Data Script for NBA Stats Backend (AMI-based deployment)
# This script runs on EC2 instance startup with pre-baked AMI

# Create named pipe for streaming logs to CloudWatch only
mkfifo /tmp/app-startup.log

# Redirect all output to log file from the very beginning
exec > >(tee -a /tmp/app-startup.log)
exec 2>&1

echo "NBA Backend Instance Startup Script"
echo "Timestamp: $(date)"
echo "Project: ${project_name}-${environment}"

# CloudWatch Agent Setup (if not already configured in AMI)

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/tmp/app-startup.log",
            "log_group_name": "/aws/ec2/${project_name}-${environment}/application",
            "log_stream_name": "{instance_id}-application",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWEOF

# Install uv

echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
source /home/ec2-user/.bashrc
export PATH="/home/ec2-user/.local/bin:$PATH"

# Clone only the backend folder from GitHub

echo "Cloning backend code..."
yum install -y git
git clone --no-checkout https://github.com/ahmed-mirreh/cloud-native-web-app.git /home/ec2-user/cloud-native-web-app
cd /home/ec2-user/cloud-native-web-app
git sparse-checkout init --cone
git sparse-checkout set app/backend
git checkout main

chown -R ec2-user:ec2-user /home/ec2-user/cloud-native-web-app

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
echo "CloudWatch logging configured. Starting application at $(date)"

# Set environment variables from Terraform
export AWS_REGION="${aws_region}"
export PLAYERS_TABLE="${players_table_name}"
export LEADERBOARD_TABLE="${leaderboard_table_name}"

echo "Environment variables set:"
echo "AWS_REGION: $AWS_REGION"
echo "PLAYERS_TABLE: $PLAYERS_TABLE"
echo "LEADERBOARD_TABLE: $LEADERBOARD_TABLE"

# Get RapidAPI key from SSM Parameter Store
echo "Retrieving RapidAPI key from SSM..."
export RAPIDAPI_KEY=$(aws ssm get-parameter --name "/nba-stats/${environment}/rapidapi-key" --with-decryption --query "Parameter.Value" --output text --region ${aws_region})

# Start the FastAPI application (installed in AMI at /home/ec2-user)
echo "Starting FastAPI server from pre-installed AMI..."

# Start the application using the pre-installed environment
echo "Server starting on port 8000"
cd /home/ec2-user/cloud-native-web-app/app/backend && sudo -u ec2-user -E /home/ec2-user/.local/bin/uv run main.py >> /tmp/app-startup.log 2>&1 &
