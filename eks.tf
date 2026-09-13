data "aws_caller_identity" "current" {}

# 1. Cluster EKS Nativo (Ignora o módulo oficial que causa o erro 403)
resource "aws_eks_cluster" "oficina_cluster" {
  name     = "oficina-eks-cluster"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  version  = "1.30"

  vpc_config {
    subnet_ids             = module.vpc.private_subnets
    endpoint_public_access = true
  }
}

# 2. Grupo de Nós (As máquinas virtuais EC2 que rodam os pods)
resource "aws_eks_node_group" "oficina_nodes" {
  cluster_name    = aws_eks_cluster.oficina_cluster.name
  node_group_name = "oficina-node-group"
  node_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  subnet_ids      = module.vpc.private_subnets

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  # Diz ao Terraform para só criar as máquinas DEPOIS que o cluster estiver pronto
  depends_on = [
    aws_eks_cluster.oficina_cluster
  ]
}