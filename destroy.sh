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
check_command aws
check_command jq

# ================================================================
# Variables
# ================================================================
export AWS_REGION="ap-south-1"
export TF_VAR_aws_region=$AWS_REGION
export TF_VAR_key_name="new-keypair"

AMI_DIR="terraform/compute/ami_ids"
FRONTEND_AMI_FILE="$AMI_DIR/frontend_ami.txt"
BACKEND_AMI_FILE="$AMI_DIR/backend_ami.txt"

# ================================================================
# 1. Compute (EC2, ALBs, ASGs)
# ================================================================
print_section "Destroying Compute infrastructure"
cd terraform/compute
terraform destroy -auto-approve -input=false \
  -var="key_name=$TF_VAR_key_name"
cd ../..

# ================================================================
# 2. Database (RDS)
# ================================================================
print_section "Destroying Database infrastructure"
cd terraform/database
terraform destroy -auto-approve -input=false
cd ../..

# ================================================================
# 3. Storage (S3 / EFS / Endpoints)
# ================================================================
print_section "Destroying Storage infrastructure"
cd terraform/storage
terraform destroy -auto-approve -input=false
cd ../..

# ================================================================
# 4. Network (VPC, Subnets, SGs)
# ================================================================
print_section "Destroying Network infrastructure"
cd terraform/network
terraform destroy -auto-approve -input=false
cd ../..

# ================================================================
# 5. Cleanup AMIs + Snapshots
# ================================================================
print_section "Cleaning up Packer AMIs and Snapshots"

delete_ami_and_snapshots() {
    local ami_file=$1

    if [ -f "$ami_file" ]; then
        local ami_id
        ami_id=$(cat "$ami_file")

        if [ -n "$ami_id" ]; then
            echo "Deregistering AMI: $ami_id"
            aws ec2 deregister-image --image-id "$ami_id" --region "$AWS_REGION" || true

            echo "Finding and deleting associated snapshots..."
            snapshot_ids=$(aws ec2 describe-images \
                --image-ids "$ami_id" \
                --region "$AWS_REGION" \
                --query "Images[0].BlockDeviceMappings[].Ebs.SnapshotId" \
                --output text 2>/dev/null)

            for snap_id in $snapshot_ids; do
                if [ -n "$snap_id" ]; then
                    echo "Deleting snapshot: $snap_id"
                    aws ec2 delete-snapshot --snapshot-id "$snap_id" --region "$AWS_REGION" || true
                fi
            done
        fi

        rm -f "$ami_file"
    fi
}

delete_ami_and_snapshots "$FRONTEND_AMI_FILE"
delete_ami_and_snapshots "$BACKEND_AMI_FILE"

# ================================================================
# Done
# ================================================================
print_section "Cleanup completed successfully!"
echo "🧹 All Terraform resources, AMIs, and snapshots have been destroyed."
echo "You can now safely delete the project directory if desired."
echo "Thank you for using the 3-tier Terraform + Packer project!"

echo "╔══════════════════ Stay Connected ═════════════════════════════╗"
echo "║ 🎥  YouTube:   https://www.youtube.com/@devopsharishnshetty   ║"
echo "║ 📁  Projects:  https://harishnshetty.github.io/projects.html  ║"
echo "║ 👔  LinkedIn:  https://in.linkedin.com/in/harishnshetty       ║"
echo "║ 🐱  GitHub:    https://github.com/harishnshetty               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo "Goodbye! 👋"