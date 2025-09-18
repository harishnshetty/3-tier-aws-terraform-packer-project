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


# Backend instance resource
resource "aws_instance" "backend" {
  # ... your existing instance configuration ...
  
  user_data = templatefile("app_user_data.sh", {
    db_host     = data.terraform_remote_state.database.outputs.rds_address
    db_name     = data.terraform_remote_state.database.outputs.rds_database_name
    db_user     = data.terraform_remote_state.database.outputs.rds_username
    db_password = var.db_password  # This should be the same password used for RDS
  })
  
  depends_on = [aws_db_instance.main]  # Ensure RDS is created first
}


# # locals.tf
# locals {
#   # Replace with your actual AMI IDs or use data sources to look them up
#   web_ami_id = "ami-02d26659fd82cf299"  # Replace with actual web AMI
#   app_ami_id = "ami-02d26659fd82cf299"  # Replace with actual app AMI
# }