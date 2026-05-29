output "cluster_name" {
  description = "Name of the created EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Cluster CA certificate data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.web.repository_url
}

output "db_endpoint" {
  description = "PostgreSQL database endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_port" {
  description = "PostgreSQL database port"
  value       = aws_db_instance.postgres.port
}
