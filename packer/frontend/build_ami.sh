#!/bin/bash
set -euo pipefail

AWS_REGION="ap-south-1"
AMI_FILE="../../terraform/compute/ami_ids/frontend_ami.txt"
LOG_FILE="packer_frontend_build.log"
PACKER_TEMPLATE="frontend.json"

echo "🚀 Building Frontend AMI..."
echo "Region: $AWS_REGION"
echo "Template: $PACKER_TEMPLATE"

mkdir -p "$(dirname "$AMI_FILE")"

# Run packer init
packer init "$PACKER_TEMPLATE"

# Build the AMI and capture logs
if ! packer build -var aws_region=$AWS_REGION "$PACKER_TEMPLATE" 2>&1 | tee "$LOG_FILE"; then
  echo "❌ Packer build failed. Check logs: $LOG_FILE"
  exit 1
fi

# Extract AMI ID (robust extraction)
AMI_ID=$(grep -Eo 'ami-[0-9a-f]+' "$LOG_FILE" | tail -n1)

if [ -n "$AMI_ID" ]; then
  echo "✅ Frontend AMI created successfully: $AMI_ID"
  echo -n "$AMI_ID" > "$AMI_FILE"
  echo "📦 AMI ID saved to: $AMI_FILE"
else
  echo "❌ Failed to extract AMI ID"
  echo "Check logs: $LOG_FILE"
  exit 1
fi
