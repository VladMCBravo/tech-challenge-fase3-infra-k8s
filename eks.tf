data "aws_caller_identity" "current" {}

# 1. Cluster EKS — usa as subnets privadas REFERENCIADAS (data source em network.tf).
resource "aws_eks_cluster" "oficina_cluster" {
  name     = "oficina-eks-cluster-v2"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  # Casa com o cluster JÁ existente (importado). O default do provider é `true`,
  # e a diferença false->true FORÇA a recriação do cluster. Fixamos em false.
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids             = data.aws_subnets.private_subnets.ids
    endpoint_public_access = true
  }

  # SEGURANÇA: nunca destruir o cluster por drift/replace inesperado, e ignorar
  # atributos gerenciados pela AWS (evitam plano querendo recriar/alterar internamente).
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      bootstrap_self_managed_addons,
      access_config,
      kubernetes_network_config,
      upgrade_policy,
    ]
  }
}

# 2. Grupo de Nós (EC2) — mesmas subnets privadas referenciadas.
resource "aws_eks_node_group" "oficina_nodes" {
  cluster_name    = aws_eks_cluster.oficina_cluster.name
  node_group_name = "oficina-node-group"
  node_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  subnet_ids      = data.aws_subnets.private_subnets.ids

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_eks_cluster.oficina_cluster
  ]

  # SEGURANÇA: não destruir os nós por replace inesperado; desired_size pode
  # variar (escala), então ignoramos essa diferença.
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}
