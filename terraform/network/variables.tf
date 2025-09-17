variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnets_1a" {
  description = "CIDR blocks for web public subnets"
  type        = string
}

variable "public_subnets_1b" {
  description = "CIDR blocks for web private subnets"
  type        = string
}

variable "public_subnets_1c" {
  description = "CIDR blocks for app private subnets"
  type        = string
}


variable "web_private_subnets_1a" {
  description = "CIDR blocks for web private subnets"
  type        = string
}

variable "web_private_subnets_1b" {
  description = "CIDR blocks for web private subnets"
  type        = string
}

variable "web_private_subnets_1c" {
  description = "CIDR blocks for web private subnets"
  type        = string
}

variable "app_private_subnets_1a" {
  description = "CIDR blocks for app private subnets"
  type        = string
}


variable "app_private_subnets_1b" {
  description = "CIDR blocks for app private subnets"
  type        = string
}

variable "app_private_subnets_1c" {
  description = "CIDR blocks for app private subnets"
  type        = string
}


variable "database_private_subnets_1a" {
  description = "CIDR blocks for database subnets"
  type        = string
}

variable "database_private_subnets_1b" {
  description = "CIDR blocks for database subnets"
  type        = string
}

variable "database_private_subnets_1c" {
  description = "CIDR blocks for database subnets"
  type        = string
}

variable "az1" {
  description = "List of availability zones"
  type        = string
}

variable "az2" {
  description = "List of availability zones"
  type        = string
}

variable "az3" {
  description = "List of availability zones"
  type        = string
}


variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
} 