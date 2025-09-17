aws_region = "ap-south-1"
environment = "dev"
project_name = "three-tier-app"

# Database Configuration
db_instance_class = "db.t3.small"
db_engine = "mysql"
db_engine_version = "8.0"
db_name = "appdb"
db_username = "admin"
db_password = "password"
db_allocated_storage = 20
db_storage_type = "gp2"

# Terraform State Bucket
terraform_state_bucket = "three-tier-terrafrom-s3-8745" 