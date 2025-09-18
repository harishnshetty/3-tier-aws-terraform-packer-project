#!/bin/bash
set -e

AWS_REGION="ap-south-1"
AMI_FILE="../../terraform/compute/ami_ids/backend_ami.txt"

# Ensure AMI folder exists
mkdir -p ../../terraform/compute/ami_ids

# Init Packer plugins
echo "Initializing Packer plugins..."
packer init .

# ================================================================
# 1. Gather Terraform Outputs
# ================================================================

# VPC & Subnet
VPC_ID=$(terraform -chdir=../../terraform/network output -raw vpc_id)
SUBNET_ID=$(terraform -chdir=../../terraform/network output -raw public_subnet_1a_id)


# RDS
DB_HOST=$(terraform -chdir=../../terraform/database output -raw rds_address)
DB_PORT=$(terraform -chdir=../../terraform/database output -raw rds_port)
DB_USER=$(terraform -chdir=../../terraform/database output -raw rds_username)
DB_PASSWORD=$(terraform -chdir=../../terraform/database output -raw rds_password)
DB_NAME=$(terraform -chdir=../../terraform/database output -raw rds_database_name)
RDS_SG_ID=$(terraform -chdir=../../terraform/database output -raw rds_instance_id || true)

if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID" ]; then
    echo "❌ Could not retrieve VPC or Subnet from Terraform state"
    exit 1
fi

if [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
    echo "❌ Could not retrieve RDS details from Terraform state"
    exit 1
fi

echo "✅ Using VPC: $VPC_ID"
echo "✅ Using Subnet: $SUBNET_ID"
echo "✅ Using DB Host: $DB_HOST"
echo "✅ Using DB Name: $DB_NAME"

# ================================================================
# 2. Create Temporary SG for Packer
# ================================================================
echo "Creating temporary SG for Packer..."
PACKER_SG_ID=$(aws ec2 create-security-group \
  --group-name "packer-sg-$(date +%s)" \
  --description "Temporary SG for Packer build" \
  --vpc-id "$VPC_ID" \
  --region "$AWS_REGION" \
  --query 'GroupId' --output text)

# Allow SSH from local + MySQL to RDS
aws ec2 authorize-security-group-ingress \
  --group-id "$PACKER_SG_ID" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$AWS_REGION"

aws ec2 authorize-security-group-ingress \
  --group-id "$PACKER_SG_ID" \
  --protocol tcp --port 3306 \
  --source-group "$PACKER_SG_ID" \
  --region "$AWS_REGION"

echo "✅ Created SG: $PACKER_SG_ID"

# ================================================================
# 3. Get Latest AL2023 AMI
# ================================================================
SOURCE_AMI=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023.*-x86_64" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --region "$AWS_REGION" --output text)

echo "✅ Using source AMI: $SOURCE_AMI"

# ================================================================
# 4. Build AMI with Packer
# ================================================================
echo "🚀 Building Backend AMI..."
PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build \
  -var "aws_region=$AWS_REGION" \
  -var "source_ami=$SOURCE_AMI" \
  -var "subnet_id=$SUBNET_ID" \
  -var "security_group_id=$PACKER_SG_ID" \
  -var "db_host=$DB_HOST" \
  -var "db_port=$DB_PORT" \
  -var "db_username=$DB_USER" \
  -var "db_password=$DB_PASSWORD" \
  -var "db_name=$DB_NAME" \
  backend.json | tee >(grep -Eo 'ami-[a-z0-9]{17}' | tail -n1 > $AMI_FILE)

# ================================================================
# 5. Cleanup SG
# ================================================================
echo "🧹 Cleaning up SG..."
aws ec2 delete-security-group --group-id "$PACKER_SG_ID" --region "$AWS_REGION" || true

echo "✅ Backend AMI saved to $AMI_FILE"
