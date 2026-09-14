# network.tf — Rede REFERENCIADA (não criada).
#
# Antes este repo criava a VPC via módulo `terraform-aws-modules/vpc`.
# Agora ele REFERENCIA a VPC e as subnets privadas já existentes por ID,
# exatamente como o `infra-db` faz (ver data.tf do infra-db).
#
# Por quê: a VPC já existe (foi criada num apply anterior). Recriá-la a cada
# execução do pipeline causaria duplicidade de rede e poderia forçar mudança
# nas subnets do cluster EKS já provisionado. Referenciando por ID, o `apply`
# fica idempotente e não toca na rede nem no cluster.
#
# NOTA: os IDs abaixo são os MESMOS usados pelo infra-db (VPC onde EKS/RDS vivem
# e as 2 subnets privadas). Se algum dia a rede for recriada, atualize os IDs.

data "aws_vpc" "oficina_vpc" {
  id = "vpc-04819097f65faf999"
}

data "aws_subnets" "private_subnets" {
  filter {
    name = "subnet-id"
    values = [
      "subnet-0b868a33706dd184a",
      "subnet-0e66981f57714d07c",
    ]
  }
}
