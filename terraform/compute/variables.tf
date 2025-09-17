variable "aws_region" {
  description = "The AWS region to create resources in."
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

variable "key_name" {
  description = "Name of the key pair to use for web EC2 instances"
  type        = string
}

variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
  
}
# web variables

variable "web_instance_type" {
  description = "Instance type for web instances"
  type        = string
  default     = "t3.micro"
}

variable "web_desired_capacity" {
  description = "Desired number of web instances"
  type        = number
  default     = 2
}

variable "web_max_size" {
  description = "Maximum number of web instances"
  type        = number
  default     = 4
}

variable "web_min_size" {
  description = "Minimum number of web instances"
  type        = number
  default     = 1
}


# app variables


variable "app_instance_type" {
  description = "Instance type for app instances"
  type        = string
  default     = "t3.micro"
}

variable "app_desired_capacity" {
  description = "Desired number of app instances"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum number of app instances"
  type        = number
  default     = 4
}

variable "app_min_size" {
  description = "Minimum number of app instances"
  type        = number
  default     = 1
}

# Terraform State Bucket
variable "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
} 