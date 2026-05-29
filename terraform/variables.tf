variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "royalwheels-eks"
}

variable "ecr_repository_name" {
  description = "ECR repository name for the Docker image"
  type        = string
  default     = "royalwheels-web"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "royalwheels"
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "royaladmin"
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "db_backup_retention_period" {
  description = "Backup retention period for the PostgreSQL RDS instance"
  type        = number
  default     = 0
}

variable "node_instance_type" {
  description = "AWS EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired EKS node group capacity"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum EKS node group capacity"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum EKS node group capacity"
  type        = number
  default     = 1
}
