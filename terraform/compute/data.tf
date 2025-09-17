data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "network/terraform.tfstate"
    region = var.aws_region
  }
}

# RDS Data Source
data "terraform_remote_state" "database" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "database/terraform.tfstate"
    region = var.aws_region
  }
}




# locals.tf
locals {
  # Replace with your actual AMI IDs or use data sources to look them up
  web_ami_id = "ami-02d26659fd82cf299"  # Replace with actual web AMI
  app_ami_id = "ami-02d26659fd82cf299"  # Replace with actual app AMI
}