data "aws_caller_identity" "current" {}

# 1. Cluster EKS Nativo
resource "aws_eks_cluster" "oficina_cluster" {
  name     = "oficina-eks-cluster"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  

  vpc_config {
    subnet_ids             = module.vpc.private_subnets
    endpoint_public_access = true
  }
}

# 2. Grupo de Nós (As máquinas virtuais EC2)
resource "aws_eks_node_group" "oficina_nodes" {
  cluster_name    = aws_eks_cluster.oficina_cluster.name
  node_group_name = "oficina-node-group"
  node_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  subnet_ids      = module.vpc.private_subnets

  instance_types = ["t3.medium"]
  ami_type       = "AL2_x86_64"

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_eks_cluster.oficina_cluster
  ]
}