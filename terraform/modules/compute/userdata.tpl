#!/bin/bash
# EC2 User Data Script for NBA Stats Backend (AMI-based deployment)
# This script runs on EC2 instance startup with pre-baked AMI

set -e  # Exit on any error

# Create named pipe for streaming logs to CloudWatch only
echo "=== CREATING LOG PIPE ==="
mkfifo /tmp/app-startup.log

# Redirect all output to log file from the very beginning
exec > >(tee -a /tmp/app-startup.log)
exec 2>&1

echo "=== NBA BACKEND INSTANCE STARTUP SCRIPT ==="
echo "Timestamp: $(date)"
echo "Project: ${project_name}-${environment}"
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

# CloudWatch Agent Setup (if not already configured in AMI)
echo "=== SETTING UP CLOUDWATCH AGENT ==="

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

echo "CloudWatch agent config file created"

# Install uv
echo "=== INSTALLING UV ==="
echo "Downloading uv installer..."
curl -LsSf https://astral.sh/uv/install.sh | sh
if [ $? -eq 0 ]; then
    echo "✓ UV installer downloaded and executed successfully"
else
    echo "✗ ERROR: UV installation failed"
    exit 1
fi

echo "Setting up uv path..."
export PATH="/home/ec2-user/.local/bin:$PATH"
echo "Path updated: $PATH"

# Verify uv installation
if [ -f "/home/ec2-user/.local/bin/uv" ]; then
    echo "✓ UV binary found at /home/ec2-user/.local/bin/uv"
    /home/ec2-user/.local/bin/uv --version
else
    echo "✗ ERROR: UV binary not found after installation"
    exit 1
fi

# Clone only the backend folder from GitHub
echo "=== CLONING BACKEND CODE ==="
echo "Installing git..."
yum install -y git
if [ $? -eq 0 ]; then
    echo "✓ Git installed successfully"
else
    echo "✗ ERROR: Git installation failed"
    exit 1
fi

echo "Cloning repository..."
git clone --no-checkout https://github.com/ahmed-mirreh/cloud-native-web-app.git /home/ec2-user/cloud-native-web-app
if [ $? -eq 0 ]; then
    echo "✓ Repository cloned successfully"
else
    echo "✗ ERROR: Repository clone failed"
    exit 1
fi

echo "Setting up sparse checkout..."
cd /home/ec2-user/cloud-native-web-app
git sparse-checkout init --cone
git sparse-checkout set app/backend
git checkout main
if [ $? -eq 0 ]; then
    echo "✓ Sparse checkout completed successfully"
else
    echo "✗ ERROR: Sparse checkout failed"
    exit 1
fi

echo "Setting file ownership..."
chown -R ec2-user:ec2-user /home/ec2-user/cloud-native-web-app

# Verify backend files
echo "=== VERIFYING BACKEND FILES ==="
echo "Backend directory contents:"
ls -la /home/ec2-user/cloud-native-web-app/app/backend/

# Verify expected files exist
if [ -f "/home/ec2-user/cloud-native-web-app/app/backend/main.py" ]; then
    echo "✓ main.py found"
else
    echo "✗ ERROR: main.py not found"
    exit 1
fi

if [ -f "/home/ec2-user/cloud-native-web-app/app/backend/pyproject.toml" ]; then
    echo "✓ pyproject.toml found"
else
    echo "✗ ERROR: pyproject.toml not found"
    exit 1
fi

if [ -f "/home/ec2-user/cloud-native-web-app/app/backend/uv.lock" ]; then
    echo "✓ uv.lock found"
else
    echo "✗ ERROR: uv.lock not found"
    exit 1
fi

# Start CloudWatch agent
echo "=== STARTING CLOUDWATCH AGENT ==="
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
if [ $? -eq 0 ]; then
    echo "✓ CloudWatch agent started successfully"
else
    echo "✗ WARNING: CloudWatch agent start failed (continuing anyway)"
fi
echo "CloudWatch logging configured. Starting application at $(date)"

# Set environment variables from Terraform
echo "=== SETTING ENVIRONMENT VARIABLES ==="
export AWS_REGION="${aws_region}"
export PLAYERS_TABLE="${players_table_name}"
export LEADERBOARD_TABLE="${leaderboard_table_name}"

echo "Environment variables set:"
echo "AWS_REGION: $AWS_REGION"
echo "PLAYERS_TABLE: $PLAYERS_TABLE"
echo "LEADERBOARD_TABLE: $LEADERBOARD_TABLE"

# Get RapidAPI key from SSM Parameter Store
echo "=== RETRIEVING RAPIDAPI KEY ==="
echo "Retrieving RapidAPI key from SSM..."
export RAPIDAPI_KEY=$(aws ssm get-parameter --name "/nba-stats/${environment}/rapidapi-key" --with-decryption --query "Parameter.Value" --output text --region ${aws_region} 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$RAPIDAPI_KEY" ]; then
    echo "✓ RapidAPI key retrieved successfully"
    echo "Key length: ${#RAPIDAPI_KEY} characters"
else
    echo "✗ ERROR: Failed to retrieve RapidAPI key from SSM"
    exit 1
fi

# Start the FastAPI application
echo "=== STARTING FASTAPI APPLICATION ==="
echo "Current working directory: $(pwd)"
echo "Changing to backend directory..."
cd /home/ec2-user/cloud-native-web-app/app/backend

echo "Backend directory contents after cd:"
ls -la

echo "Starting FastAPI server with main.py"
echo "Using uv path: /home/ec2-user/.local/bin/uv"
echo "Command: sudo -u ec2-user -E /home/ec2-user/.local/bin/uv run main.py"

# Start the application
sudo -u ec2-user -E /home/ec2-user/.local/bin/uv run main.py >> /tmp/app-startup.log 2>&1 &
APP_PID=$!

echo "✓ FastAPI application started with PID: $APP_PID"
echo "=== STARTUP SCRIPT COMPLETED ==="
echo "Application should be running on port 8000"
