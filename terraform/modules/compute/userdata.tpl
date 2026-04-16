#!/bin/bash
# EC2 User Data Script for NBA Stats Backend (AMI-based deployment)

echo "NBA Backend Instance Startup Script"
echo "Timestamp: $(date)"
echo "Project: ${project_name}-${environment}"

# CloudWatch Agent Setup (if not already configured in AMI)
echo "Setting up CloudWatch Agent..."
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cloud-init-output.log",
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

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "CloudWatch logging configured. Starting application at $(date)"

# Install uv
echo "=== INSTALLING UV ==="
echo "Downloading uv installer..."
sudo -u ec2-user bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
echo "Setting up uv path..."
export PATH="/home/ec2-user/.local/bin:$PATH"
echo "Path updated: $PATH"

# Install git and clone the backend directory using sparse checkout
yum install -y git
echo "Cloning repository..."
git clone --no-checkout https://github.com/ahmed-mirreh/cloud-native-web-app.git /home/ec2-user/cloud-native-web-app
echo "Setting up sparse checkout..."
cd /home/ec2-user/cloud-native-web-app
git sparse-checkout init --cone
git sparse-checkout set app/backend
git checkout main
chown -R ec2-user:ec2-user /home/ec2-user/cloud-native-web-app

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

if [ -z "$RAPIDAPI_KEY" ]; then
    echo "ERROR: RAPIDAPI_KEY not found in SSM Parameter Store"
    exit 1
else
    echo "RAPIDAPI_KEY retrieved successfully"
fi

# Start the application using the pre-installed environment
echo "Server starting on port 8000 at $(date)"
cd /home/ec2-user/cloud-native-web-app/app/backend && sudo -u ec2-user -E /home/ec2-user/.local/bin/uv run main.py