##############################################
# RDS Instance Outputs
##############################################

output "rds_address" {
  description = "The address of the RDS instance (hostname)"
  value       = aws_db_instance.main.address
}

output "rds_endpoint" {
  description = "The full connection endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "rds_username" {
  description = "The master username for the RDS instance"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "rds_password" {
  description = "The master password for the RDS instance"
  value       = var.db_password
  sensitive   = true
}

output "rds_database_name" {
  description = "The name of the database"
  value       = aws_db_instance.main.db_name
}



##############################################
# Metadata Outputs
##############################################

output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "rds_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_subnet_group_id" {
  description = "The ID of the DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "The ARN of the DB subnet group"
  value       = aws_db_subnet_group.main.arn
}
output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

