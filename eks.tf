module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    oficina_nodes = {
      min_size     = 1
      max_size     = 3 # O nosso HPA (Autoscaler) fará o cluster crescer até aqui!
      desired_size = 2

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "tech-challenge"
  }
}