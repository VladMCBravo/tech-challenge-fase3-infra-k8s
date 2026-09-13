data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "oficina-eks-cluster"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # --- AWS ACADEMY WORKAROUNDS INÍCIO ---
  
  # 1. Impede o Terraform de tentar ler a role voclabs (Evita o Erro 403 GetRole)
  enable_cluster_creator_admin_permissions = false

  # 2. Desativa criação do KMS (AWS Academy bloqueia)
  create_kms_key            = false
  cluster_encryption_config = {}

  # 3. Desativa logs do CloudWatch para poupar créditos da AWS Academy
  cluster_enabled_log_types   = []
  create_cloudwatch_log_group = false

  # 4. Força o uso da LabRole no Cluster
  create_iam_role = false
  iam_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  # 5. Força o uso da LabRole nos Node Groups (Máquinas virtuais do K8s)
  eks_managed_node_groups = {
    oficina_nodes = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.medium"]

      create_iam_role = false
      iam_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
    }
  }

  # 6. Garante que você tenha acesso de Admin no cluster usando a role padrão de aluno
  access_entries = {
    voclabs_admin = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs"
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  # --- AWS ACADEMY WORKAROUNDS FIM ---
}