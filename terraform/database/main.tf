# ----------------------------
# DB Subnet Group
# ----------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [
    data.terraform_remote_state.network.outputs.database_private_subnet_1a_id,
    data.terraform_remote_state.network.outputs.database_private_subnet_1b_id,
    data.terraform_remote_state.network.outputs.database_private_subnet_1c_id
  ]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
    Tier        = "database"
  }
}

# ----------------------------
# RDS Instance
# ----------------------------
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class

  # Storage
  allocated_storage      = var.db_allocated_storage
  storage_type           = var.db_storage_type
  max_allocated_storage  = 100   # autoscaling up to 100 GB

  # Database details
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  # Networking
  vpc_security_group_ids = [data.terraform_remote_state.network.outputs.rds_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  # High availability and access
  multi_az               = false
  publicly_accessible    = false

  # Maintenance & backups
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Other options
  skip_final_snapshot    = true
  deletion_protection    = false
  apply_immediately      = true
  performance_insights_enabled = false

  tags = {
    Name        = "${var.project_name}-db"
    Project     = var.project_name
    Environment = var.environment
    Tier        = "database"
  }
}
