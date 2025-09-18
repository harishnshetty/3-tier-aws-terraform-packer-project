#!/bin/bash
set -e

AWS_REGION="ap-south-1"
AMI_FILE="../../terraform/compute/ami_ids/backend_ami.txt"

mkdir -p ../../terraform/compute/ami_ids

packer init .
AMI_ID=$(packer build -machine-readable -var aws_region=$AWS_REGION backend.json | awk -F, '$0 ~/artifact,0,id/ {print $6}' | cut -d: -f2)

if [ -n "$AMI_ID" ]; then
  echo "Backend AMI created: $AMI_ID"
  echo -n "$AMI_ID" > $AMI_FILE
else
  echo "Failed to build backend AMI"
  exit 1
fi