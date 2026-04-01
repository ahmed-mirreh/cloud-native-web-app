# NBA Higher Lower Game - 3-Tier Web Application

A cloud-native NBA statistics game built on AWS with a 3-tier architecture using S3, EC2, and DynamoDB.

## Architecture

- **Frontend (Tier 1)**: Static website hosted on S3 with CloudFront CDN
- **Backend (Tier 2)**: Auto-scaling EC2 instances behind Application Load Balancer (ALB)
- **Database (Tier 3)**: DynamoDB for player data and game statistics

### Infrastructure Components
- **VPC**: Private networking with public/private subnets across multiple AZs
- **Auto Scaling Group**: EC2 instances in private subnets for high availability
- **Application Load Balancer**: Internal ALB for routing API requests
- **CloudFront**: CDN with VPC Origin for ALB and S3 bucket access
- **DynamoDB**: NoSQL database with VPC Gateway Endpoint for cost-efficient access

## Game Features

- **Player Selection**: Choose from NBA players for comparison
- **Statistics Game**: Higher/lower gameplay with real NBA stats
- **Leaderboard**: Track your best scores
- **Real-time Data**: Uses current NBA player statistics

## Development

For local development and detailed component information, see:
- `app/backend/` - EC2 backend application development
- `app/frontend/` - Frontend development
- `terraform/README.md` - Infrastructure details

## Security

- Frontend files are served via CloudFront with HTTPS
- EC2 instances deployed in private subnets with no direct internet access
- API endpoints accessed through internal ALB with CloudFront VPC Origin
- Database access is controlled via IAM roles and VPC endpoints
- Security groups restrict traffic to necessary ports only
- No sensitive data is stored in frontend code

## Monitoring

The application includes:
- CloudWatch logs for EC2 application logs
- Auto Scaling policies with CloudWatch alarms
- CloudFront access logs and metrics
- DynamoDB metrics and alarms
- SNS email alerts for critical issues


## Prerequisites

### Required Software
- **Terraform**: `>= 1.0` → [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI**: `>= 2.0` → [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### AWS Region Requirement
- **All resources must be deployed in `us-east-1`** (Virginia)
- The pre-built AMI is only available in us-east-1

### Version Check
```bash
terraform version
aws --version
```

### AWS Authentication
```bash
aws configure
```

You'll need:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `us-east-1`)

## Deployment

### 1. Set Up Remote State Storage

Create an S3 bucket for Terraform state management:

```bash
# Create a unique bucket name (replace 'your-initials' with your actual initials)
export STATE_BUCKET="nba-game-terraform-state-your-initials-$(date +%s)"

# Create the S3 bucket for state storage
aws s3 mb s3://${STATE_BUCKET} --region us-east-1

# Enable versioning for state backup
aws s3api put-bucket-versioning --bucket ${STATE_BUCKET} --versioning-configuration Status=Enabled --region us-east-1

# Enable encryption for security
aws s3api put-bucket-encryption --bucket ${STATE_BUCKET} --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}' --region us-east-1

# Display your bucket name (save this for next step)
echo "Your Terraform state bucket: ${STATE_BUCKET}"
```

### 2. Configure Terraform State Backend

Update the `terraform/remote-state.tf` file with your bucket name

### 3. Deploy Infrastructure with Terraform

Update `environments/dev.tfvars` with your email address for alerts, then deploy the infrastructure:

```bash
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

### 4. Get Deployment Information

After Terraform deployment completes, note these outputs:

- `s3_bucket_name`: For uploading frontend files
- `cloudfront_domain`: For API configuration
- `aws_region`: Deployment region

### 5. Upload Frontend Files to S3

Navigate to the app directory and set environment variables:
```bash
cd ../app/

# Set these from terraform output
export BUCKET_NAME="your-s3-bucket-name"
export CLOUDFRONT_DOMAIN="your-cloudfront-domain"
export REGION="us-east-1"  # or your chosen region
```

Upload all frontend files:
```bash
cd frontend/

# Upload HTML, CSS, and JS files
aws s3 cp index.html s3://${BUCKET_NAME}/index.html --content-type text/html --region ${REGION}
aws s3 cp styles.css s3://${BUCKET_NAME}/styles.css --content-type text/css --region ${REGION}
aws s3 cp script.js s3://${BUCKET_NAME}/script.js --content-type application/javascript --region ${REGION}
aws s3 cp error.html s3://${BUCKET_NAME}/error.html --content-type text/html --region ${REGION}

# Create and upload config file with API endpoint
echo "window.API_BASE_URL = 'https://${CLOUDFRONT_DOMAIN}/api';" > config.js
aws s3 cp config.js s3://${BUCKET_NAME}/config.js --content-type application/javascript --region ${REGION}
```

### 6. Upload Player Data to DynamoDB

```bash
cd ../database/

# Upload initial player data
aws dynamodb batch-write-item --request-items file://players_data.json --region ${REGION}
```

## Access Your Application

Once deployment is complete, access your application at:
```
https://your-cloudfront-domain
```

The domain will be shown in the terraform output as `app_domain`.

## 📁 Project Structure

```
project-1/
├── app/
│   ├── backend/          # backend code compiled within ami
│   ├── frontend/         # Static web files
│   └── database/         # DynamoDB seed data
└── terraform/           # Infrastructure as Code
    ├── modules/         # Reusable Terraform modules
    └── environments/    # Environment-specific configs
```

## 🧹 Cleanup

To avoid ongoing AWS charges, clean up all resources when done:

### 1. Empty S3 Bucket
```bash
cd app/
# Get bucket name from terraform output
cd ../terraform/
export BUCKET_NAME=$(terraform output -raw s3_bucket_name)

# Empty the S3 bucket completely
aws s3 rm s3://${BUCKET_NAME} --recursive --region us-east-1

# Verify bucket is empty
aws s3 ls s3://${BUCKET_NAME} --region us-east-1
```

### 2. Destroy Infrastructure
```bash
# Destroy all AWS resources
terraform destroy -var-file=environments/dev.tfvars -auto-approve
```

### 3. Clean Up State Bucket (Optional)
```bash
# If you want to remove the Terraform state bucket too
export STATE_BUCKET="your-terraform-state-bucket-name"
aws s3 rb s3://${STATE_BUCKET} --force --region us-east-1
```

**Important**: Always empty the S3 bucket before running `terraform destroy` to avoid errors.