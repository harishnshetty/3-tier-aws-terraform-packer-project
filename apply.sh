#!/bin/bash

set -e  # Exit on any error

# ================================================================
# Utility Functions
# ================================================================

print_section() {
    echo "================================================"
    echo " $1"
    echo "================================================"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 is required but not installed."
        exit 1
    fi
}

# ================================================================
# Pre-checks
# ================================================================
check_command terraform
check_command packer
check_command aws
check_command jq

# ================================================================
# Variables
# ================================================================
export AWS_REGION="ap-south-1"
export TF_VAR_aws_region=$AWS_REGION
export TF_VAR_key_name="new-keypair"   # 👈 existing AWS key pair

# ================================================================
# 1. Network (VPC, Subnets, SGs, etc.)
# ================================================================
print_section "Creating Network infrastructure"
cd terraform/network
terraform init -input=false
terraform apply -auto-approve -input=false
cd ../..

# ================================================================
# 2. Storage (S3 / EFS / Endpoints)
# ================================================================
print_section "Creating Storage infrastructure"
cd terraform/storage
terraform init -input=false
terraform apply -auto-approve -input=false
cd ../..

# ================================================================
# 3. Database (RDS)
# ================================================================
print_section "Creating Database (RDS)"
cd terraform/database
terraform init -input=false
terraform apply -auto-approve -input=false
cd ../..

# ================================================================
# 4. AMI Creation (Frontend + Backend)
# ================================================================
print_section "Creating AMIs"

check_ami_exists() {
    local ami_id=$1
    if [ ! -z "$ami_id" ]; then
        aws ec2 describe-images \
            --image-ids "$ami_id" \
            --query 'Images[0].State' \
            --output text 2>/dev/null | grep -q "available"
        return $?
    fi
    return 1
}

# --- Frontend AMI ---
print_section "Checking Frontend AMI"
FRONTEND_AMI_ID=""
if [ -f "terraform/compute/ami_ids/frontend_ami.txt" ]; then
    FRONTEND_AMI_ID=$(cat terraform/compute/ami_ids/frontend_ami.txt)
fi

if check_ami_exists "$FRONTEND_AMI_ID"; then
    echo "✅ Frontend AMI $FRONTEND_AMI_ID already exists"
else
    echo "🚀 Building new Frontend AMI..."
    cd packer/frontend
    ./build_ami.sh
    cd ../..
fi

# --- Backend AMI ---
print_section "Checking Backend AMI"
BACKEND_AMI_ID=""
if [ -f "terraform/compute/ami_ids/backend_ami.txt" ]; then
    BACKEND_AMI_ID=$(cat terraform/compute/ami_ids/backend_ami.txt)
fi

if check_ami_exists "$BACKEND_AMI_ID"; then
    echo "✅ Backend AMI $BACKEND_AMI_ID already exists"
else
    echo "🚀 Building new Backend AMI..."
    cd packer/backend
    ./build_ami.sh
    cd ../..
fi

# ================================================================
# 5. Compute (EC2, ALBs, ASGs)
# ================================================================
print_section "Creating Compute infrastructure"
cd terraform/compute
terraform init -input=false
terraform apply -auto-approve -input=false \
  -var="key_name=$TF_VAR_key_name"
cd ../..

# ================================================================
# Done
# ================================================================

echo "╔══════════════════ Stay Connected ═════════════════════════════╗"
echo "║ 🎥  YouTube:   https://www.youtube.com/@devopsharishnshetty   ║"
echo "║ 📁  Projects:  https://harishnshetty.github.io/projects.html  ║"
echo "║ 👔  LinkedIn:  https://in.linkedin.com/in/harishnshetty       ║"
echo "║ 🐱  GitHub:    https://github.com/harishnshetty               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"

print_section "Infrastructure setup completed successfully!"
echo "🌍 Access your application at the Web ALB DNS name shown in compute outputs."