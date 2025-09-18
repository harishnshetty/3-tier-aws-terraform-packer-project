# outputs.tf
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}


# Subnet Outputs
output "public_subnet_1a_id" {
  description = "The ID of public subnet 1a"
  value       = aws_subnet.public_subnets_1a.id
}

output "public_subnet_1b_id" {
  description = "The ID of public subnet 1b"
  value       = aws_subnet.public_subnets_1b.id
}

output "public_subnet_1c_id" {
  description = "The ID of public subnet 1c"
  value       = aws_subnet.public_subnets_1c.id
}

output "web_private_subnet_1a_id" {
  description = "The ID of web private subnet 1a"
  value       = aws_subnet.web_private_subnets_1a.id
}

output "web_private_subnet_1b_id" {
  description = "The ID of web private subnet 1b"
  value       = aws_subnet.web_private_subnets_1b.id
}

output "web_private_subnet_1c_id" {
  description = "The ID of web private subnet 1c"
  value       = aws_subnet.web_private_subnets_1c.id
}

output "app_private_subnet_1a_id" {
  description = "The ID of app private subnet 1a"
  value       = aws_subnet.app_private_subnets_1a.id
}

output "app_private_subnet_1b_id" {
  description = "The ID of app private subnet 1b"
  value       = aws_subnet.app_private_subnets_1b.id
}

output "app_private_subnet_1c_id" {
  description = "The ID of app private subnet 1c"
  value       = aws_subnet.app_private_subnets_1c.id
}

output "database_private_subnet_1a_id" {
  description = "The ID of database private subnet 1a"
  value       = aws_subnet.database_private_subnets_1a.id
}

output "database_private_subnet_1b_id" {
  description = "The ID of database private subnet 1b"
  value       = aws_subnet.database_private_subnets_1b.id
}

output "database_private_subnet_1c_id" {
  description = "The ID of database private subnet 1c"
  value       = aws_subnet.database_private_subnets_1c.id
}

# Route Table Outputs
output "public_route_table_id" {
  description = "The ID of public route table"
  value       = aws_route_table.public.id
}

output "web_private_route_table_1a_id" {
  description = "The ID of web private route table 1a"
  value       = aws_route_table.web_private_rt_1a.id
}

output "web_private_route_table_1b_id" {
  description = "The ID of web private route table 1b"
  value       = aws_route_table.web_private_rt_1b.id
}

output "web_private_route_table_1c_id" {
  description = "The ID of web private route table 1c"
  value       = aws_route_table.web_private_rt_1c.id
}

output "app_private_route_table_1a_id" {
  description = "The ID of app private route table 1a"
  value       = aws_route_table.app_private_rt_1a.id
}

output "app_private_route_table_1b_id" {
  description = "The ID of app private route table 1b"
  value       = aws_route_table.app_private_rt_1b.id
}

output "app_private_route_table_1c_id" {
  description = "The ID of app private route table 1c"
  value       = aws_route_table.app_private_rt_1c.id
}

output "database_private_route_table_1a_id" {
  description = "The ID of database private route table 1a"
  value       = aws_route_table.database_private_rt_1a.id
}

output "database_private_route_table_1b_id" {
  description = "The ID of database private route table 1b"
  value       = aws_route_table.database_private_rt_1b.id
}

output "database_private_route_table_1c_id" {
  description = "The ID of database private route table 1c"
  value       = aws_route_table.database_private_rt_1c.id
}

# Security Group Outputs
output "jump_sg_id" {
  description = "The ID of jump server security group"
  value       = aws_security_group.jump_sg.id
}

output "frontend_alb_sg_id" {
  description = "The ID of frontend ALB security group"
  value       = aws_security_group.frontend_alb_sg.id
}

output "web_sg_id" {
  description = "The ID of web security group"
  value       = aws_security_group.web_sg.id
}

output "backend_alb_sg_id" {
  description = "The ID of backend ALB security group"
  value       = aws_security_group.backend_alb_sg.id
}

output "app_sg_id" {
  description = "The ID of app security group"
  value       = aws_security_group.app-sg.id
}

output "rds_sg_id" {
  description = "The ID of RDS security group"
  value       = aws_security_group.rds.id
}
