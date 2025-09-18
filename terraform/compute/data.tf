data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "database/terraform.tfstate"
    region = var.aws_region
  }
}

# Add AMI data source
data "local_file" "backend_ami" {
  filename = "${path.module}/ami_ids/backend_ami.txt"
}

