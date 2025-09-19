#!/bin/bash
set -euo pipefail

AWS_REGION="ap-south-1"
AMI_FILE="../../terraform/compute/ami_ids/backend_ami.txt"
LOG_FILE="packer_build.log"
PACKER_TEMPLATE="backend.json"

echo "🚀 Building Backend AMI..."
echo "Region: $AWS_REGION"
echo "Template: $PACKER_TEMPLATE"

mkdir -p "$(dirname "$AMI_FILE")"

# Build the AMI and capture output
if ! packer build -var aws_region=$AWS_REGION "$PACKER_TEMPLATE" 2>&1 | tee "$LOG_FILE"; then
  echo "❌ Packer build failed. Check the log file: $LOG_FILE"
  exit 1
fi

# Extract AMI ID (works for both Amazon Linux & Ubuntu builds)
AMI_ID=$(grep -Eo 'ami-[0-9a-f]+' "$LOG_FILE" | tail -n1)

if [ -n "$AMI_ID" ]; then
  echo "✅ Backend AMI created successfully: $AMI_ID"
  echo -n "$AMI_ID" > "$AMI_FILE"
  echo "📦 AMI ID saved to: $AMI_FILE"
  
  echo ""
  echo "📋 AMI Details:"
  echo "   AMI ID: $AMI_ID"
  echo "   Region: $AWS_REGION"
  echo "   Purpose: Backend tier (Flask or PHP depending on backend.json)"
else
  echo "❌ Failed to extract AMI ID"
  echo "Check the log file: $LOG_FILE"
  exit 1
fi
