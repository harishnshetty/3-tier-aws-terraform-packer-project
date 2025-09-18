#!/bin/bash
set -e

AWS_REGION="ap-south-1"
AMI_FILE="../../terraform/compute/ami_ids/backend_ami.txt"
LOG_FILE="packer_build.log"

echo "🚀 Building Backend AMI based on Amazon Linux 2023 (kernel 6.1)..."
echo "Source AMI: ami-0533167fcff018a86"
echo "Region: $AWS_REGION"

mkdir -p ../../terraform/compute/ami_ids

# Build the AMI and capture output
packer build -var aws_region=$AWS_REGION backend.json 2>&1 | tee $LOG_FILE

# Extract AMI ID from log file
AMI_ID=$(grep -E 'ap-south-1: ami-' $LOG_FILE | awk '{print $2}' | cut -d: -f2)

if [ -n "$AMI_ID" ]; then
  echo "✅ Backend AMI created successfully: $AMI_ID"
  echo -n "$AMI_ID" > $AMI_FILE
  echo "AMI ID saved to: $AMI_FILE"
  
  # Display AMI details
  echo ""
  echo "📋 AMI Details:"
  echo "   AMI ID: $AMI_ID"
  echo "   Region: $AWS_REGION"
  echo "   Base AMI: Amazon Linux 2023 (kernel 6.1)"
  echo "   Purpose: Backend tier with Apache + PHP"
else
  echo "❌ Failed to build backend AMI"
  echo "Check the log file: $LOG_FILE"
  exit 1
fi