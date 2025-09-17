terraform {
  backend "s3" {
    bucket = "three-tier-terrafrom-s3-8745"
    key    = "database/terraform.tfstate"
    region = "ap-south-1"
  }
} 