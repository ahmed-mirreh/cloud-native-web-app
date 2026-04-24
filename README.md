# 🏀 **NBA Higher Lower Game - Cloud-Native 3-Tier Architecture**

---

## 📝 **Introduction**

**NBA Higher Lower Game** is a cloud-native statistics game built on **AWS** with a production-ready 3-tier architecture using **S3**, **EC2**, **DynamoDB**, and **Terraform**. This project demonstrates enterprise-grade cloud infrastructure management, ensuring deployments are **secure**, **highly available**, and **cost-optimized**. The application features real NBA player statistics with interactive gameplay hosted on a scalable AWS infrastructure.

The game challenges users to compare NBA player statistics in a higher/lower format, with **API-based data fetching**, **leaderboard tracking**, and **responsive gameplay** powered by a robust cloud backend.

---

## ✨ **Key Features**

### 🏀 **NBA Statistics Game Application**

- **Player Selection**: Choose from NBA players stored in DynamoDB for statistical comparisons
- **Interactive Gameplay**: Higher/lower statistics challenges with real NBA data served by EC2 backend
- **Leaderboard System**: Score tracking and persistence in DynamoDB with auto-scaling for high traffic
- **API Data Integration**: Frontend fetches NBA player statistics via CloudFront-cached API endpoints
- **Responsive Design**: Optimized user experience across desktop and mobile devices

### 🚀 **Infrastructure Automation**

- **3-Tier Architecture**: Clean separation of presentation (S3), application (EC2), and data layers (DynamoDB)
- **Auto-Scaling EC2**: Dynamic scaling (2-6 instances) with health checks and automated replacement
- **CloudFront CDN**: Global edge caching for reduced latency and improved performance
- **Multi-AZ Deployment**: High availability across 3 Availability Zones for fault tolerance
- **Terraform IaC**: Infrastructure as Code with modular, reusable configurations

### 🔐 **Security & Compliance**

- **VPC Isolation**: Private subnets for EC2 instances with no direct internet access
- **CloudFront OAC**: Origin Access Control prevents direct S3 bucket access
- **IAM Role-Based Access**: Service-to-service communication with minimal required permissions
- **HTTPS Enforcement**: SSL/TLS encryption for all client communications
- **Security Groups**: Restrictive firewall rules limiting traffic to essential ports only

### 📈 **Monitoring & Observability**

- **CloudWatch Integration**: Comprehensive monitoring for EC2, DynamoDB, and CloudFront metrics
- **Auto Scaling Policies**: CPU utilization monitoring triggering dynamic scaling actions
- **Health Checks**: Application and infrastructure health monitoring with automated recovery
- **SNS Notifications**: Real-time email alerts for critical infrastructure events and scaling activities
- **Performance Tracking**: Game statistics and user engagement metrics collection

---

## 🛠️ **Technology Stack**

### **Frontend Application**

- **HTML5/CSS3/JavaScript** - Static web application with responsive design
- **CloudFront CDN** - Global content delivery with edge caching
- **S3 Static Hosting** - Secure, scalable static website hosting

### **Backend Infrastructure**

- **EC2 Auto Scaling Group** - Dynamic compute scaling with health monitoring
- **Application Load Balancer** - Layer 7 load balancing with SSL/TLS termination
- **DynamoDB** - NoSQL database with single-digit millisecond latency
- **VPC with Multi-AZ** - Isolated network spanning 3 Availability Zones

### **AWS Infrastructure Components**

- **VPC**: Custom Virtual Private Cloud with public/private subnets across 3 AZs
- **NAT Gateway**: Secure outbound internet access for private subnet instances
- **Security Groups**: Layered firewall rules restricting traffic to ports 80, 443, 22
- **VPC Endpoints**: Cost-efficient private network access to DynamoDB and S3
- **Route Tables**: Custom routing for optimal traffic flow and endpoint access
- **CloudWatch & SNS**: Comprehensive monitoring with automated alerting

### **Infrastructure as Code**

- **Terraform** - Modular infrastructure provisioning and management
- **Launch Templates** - Standardized EC2 configuration with security settings and user data scripts

---

This architecture implements enterprise-grade cloud infrastructure principles:

#### 🔒 **Security**
- **Defense in Depth**: EC2 instances in private subnets with no direct internet access
- **Encryption**: HTTPS-only traffic via CloudFront, DynamoDB encryption at rest
- **Access Control**: IAM roles for service-to-service communication, restrictive Security Groups
- **Network Security**: VPC isolation, private subnets, controlled routing via NAT Gateway
- **Origin Protection**: CloudFront OAC prevents direct S3 access, internal ALB blocks external traffic

#### 🛡️ **Reliability**
- **Multi-AZ Deployment**: Resources distributed across 3 Availability Zones for fault tolerance
- **Auto Scaling**: Dynamic EC2 scaling (2-6 instances) with health checks and automatic replacement
- **Load Balancing**: ALB distributes traffic with health monitoring and failover capabilities
- **Data Durability**: DynamoDB point-in-time recovery, S3 99.999999999% (11 9's) durability
- **Self-Healing**: Auto Scaling replaces unhealthy instances automatically

#### 💰 **Cost Optimization**
- **Right-Sizing**: Auto Scaling prevents over-provisioning, scales down during low usage
- **VPC Endpoints**: Gateway endpoints eliminate NAT Gateway charges for DynamoDB/S3 access
- **On-Demand Billing**: DynamoDB pay-per-request model, no idle capacity costs
- **CDN Efficiency**: CloudFront reduces origin server load and bandwidth costs
- **Reserved Capacity**: Potential for Reserved Instance savings on predictable baseline load


---

## 🚀 **Getting Started**

### ✅ **Prerequisites**

- **AWS Account** with appropriate IAM permissions for EC2, S3, DynamoDB, CloudFront, and VPC
- **Terraform** (v1.0+) → [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI** (v2.0+) → [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **RapidAPI Key**: Free NBA statistics API access → [Get API Key](https://rapidapi.com/collection/nba-stat-api)

### 🔧 **Version Check**
```bash
terraform version    # Should be >= 1.0
aws --version        # Should be >= 2.0
```

### 🔑 **AWS Authentication**
```bash
aws configure
```
*Configure with your AWS Access Key ID, Secret Access Key, and default region (us-east-1)*

---

### 🏗️ **Deployment Instructions**

#### **1️⃣ Clone Repository & Set Up Remote State**

📚 **Reference**: For detailed S3 backend setup guidance, see [Terraform State & Backends: Setup, Migration & Troubleshooting (2026)](https://scalr.com/learning-center/practical-guide-to-terraform-init-backend-config/)

```bash
# Clone the repository
git clone https://github.com/ahmed-mirreh/cloud-native-web-app.git
cd cloud-native-web-app/terraform

# Generate unique S3 bucket name for Terraform state management
export STATE_BUCKET="nba-game-terraform-state-your-unique-identifier"

# Check if bucket name is available (404 = available, 403 = taken)
aws s3api head-bucket --bucket ${STATE_BUCKET}

# If you get 403 error (bucket name taken), try another name until you find one that's unique

# Create S3 bucket for state storage
aws s3 mb s3://${STATE_BUCKET} --region us-east-1
aws s3api put-bucket-versioning --bucket ${STATE_BUCKET} --versioning-configuration Status=Enabled --region us-east-1
aws s3api put-bucket-encryption --bucket ${STATE_BUCKET} --server-side-encryption-configuration '{
  "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
}' --region us-east-1

echo "Terraform state bucket: ${STATE_BUCKET}"
```

---

#### **2️⃣ Configure Terraform Backend**

Update the `terraform/remote-state.tf` file with your bucket name:

- Open `terraform/remote-state.tf`
- Change line 3 from: `bucket = "nba-higher-lower-game-terraform-state"`
- To: `bucket = "nba-game-terraform-state-your-initials-1649123456"` (use your actual bucket name)

**Example:**
```hcl
terraform {
  backend "s3" {
    bucket       = "nba-game-terraform-state-your-unique-identifier"  # Your bucket name here
    key          = "cloud-native-web-app/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

---

#### **3️⃣ Deploy Development Infrastructure**

```bash
# Initialize and validate Terraform configuration
terraform init
terraform fmt
terraform validate

# Deploy infrastructure
# Note: Terraform will prompt you to enter your alert email and RapidAPI key
# The RapidAPI key input will be hidden for security
terraform plan -var-file=environments/dev.tfvars -out tfplan
terraform apply tfplan
```

**✅ Provisions the following infrastructure:**
- 🌐 **VPC** with public/private subnets across 3 AZs plus NAT Gateways
- 📦 **EC2 Auto Scaling Group** with Application Load Balancer (internal)
- 🔒 **DynamoDB** tables with VPC Gateway Endpoint for cost optimization
- 🌍 **CloudFront CDN** with S3 static hosting and VPC Origin for ALB
- 📊 **CloudWatch** monitoring with SNS email alerts and auto-scaling policies

---

#### **4️⃣ Get Deployment Information**

After Terraform deployment completes, note these outputs:

- `s3_bucket_name`: For uploading frontend files
- `cloudfront_domain`: For API configuration

```bash
# View all Terraform outputs
terraform output
```

---

#### **5️⃣ Deploy Application**

```bash
# Navigate to application directory
cd ../app

# Set these values from terraform output
export BUCKET_NAME="your-s3-bucket-name"
export CLOUDFRONT_DOMAIN="your-cloudfront-domain"

# Upload NBA player data to DynamoDB
cd database/
aws dynamodb batch-write-item --request-items file://player_data.json --region us-east-1

# Upload frontend files to S3
cd ../frontend/
aws s3 cp index.html s3://${BUCKET_NAME}/ --content-type text/html
aws s3 cp styles.css s3://${BUCKET_NAME}/ --content-type text/css
aws s3 cp script.js s3://${BUCKET_NAME}/ --content-type application/javascript

# Create and upload API configuration
echo "window.API_BASE_URL = 'https://${CLOUDFRONT_DOMAIN}/api';" > config.js
aws s3 cp config.js s3://${BUCKET_NAME}/ --content-type application/javascript


```

---

#### **6️⃣ Access the Application**

🎮 **The NBA Higher Lower Game is now live!**

```bash
# Get the application URL
cd ../terraform
terraform output app_domain
```

Open the displayed CloudFront domain in your browser to start playing!

---

## 📁 **Project Structure**

```
cloud-native-web-app/
├── app/
│   ├── backend/          # EC2 backend application code
│   ├── frontend/         # Static web application files
│   └── database/         # NBA player data for DynamoDB seeding
├── terraform/           # Infrastructure as Code
│   ├── modules/         # Reusable Terraform components
│   ├── environments/    # Environment-specific configurations
│   └── remote-state.tf  # S3 backend configuration
└── README.md           # Project documentation
```

---

## 🏆 **Project Highlights**

This project demonstrates **enterprise-grade cloud architecture** including:

- **Infrastructure as Code** with modular, scalable Terraform configurations
- **3-Tier Architecture** with clear separation of concerns across presentation, application, and data layers
- **Security-first design** with VPC isolation, private subnets, and encrypted communications
- **High availability** with multi-AZ deployment and auto-scaling capabilities
- **Cost optimization** through VPC endpoints, on-demand billing, and intelligent caching

---

## 🧹 **Cleanup**

To avoid ongoing AWS charges, clean up resources when testing is complete:

#### **1️⃣ Empty Frontend S3 Bucket**
```bash
cd terraform/

# Remove all files from S3 bucket
aws s3 rm s3://${BUCKET_NAME} --recursive --region us-east-1
```

#### **2️⃣ Destroy Infrastructure**
```bash
# Remove all AWS infrastructure
terraform destroy -var-file=environments/dev.tfvars -auto-approve
```

#### **3️⃣ Remove State Bucket (Optional)**
```bash
# Clean up Terraform state storage
aws s3 rb s3://${STATE_BUCKET} --force --region us-east-1
```

**⚠️ Important**: Always empty the S3 bucket before running `terraform destroy` to prevent deletion errors.

---

## 📊 **Development**

For local development and detailed component information:
- `app/backend/` - EC2 backend application development
- `app/frontend/` - Frontend development and testing
- `terraform/README.md` - Detailed infrastructure documentation
