variable "region" {
  description = "Região da AWS"
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nome do Cluster Kubernetes"
  default     = "oficina-eks-cluster"
}

variable "db_password" {
  description = "Senha da Base de Dados RDS"
  type        = string
  sensitive   = true
  default     = "OficinaFiap2026!" # Em produção, isto viria de um cofre (Secrets Manager)
}