# Estado remoto no S3 — mesma abordagem adotada no infra-db (ver ADR-004).
# Sem isto, cada execução do pipeline "esquece" o que já existe e tenta recriar
# o cluster/nós (erro "already exists"). Com o state no S3, o Terraform passa a
# ter memória entre execuções e o apply fica idempotente.
#
# ⚠️ O bucket precisa existir ANTES do primeiro "terraform init"
#    (o mesmo já criado para o infra-db):
#      aws s3 mb s3://tf-state-oficina-538889416411-use1 --region us-east-1
terraform {
  backend "s3" {
    bucket = "tf-state-oficina-538889416411-use1"
    key    = "infra-k8s/terraform.tfstate"
    region = "us-east-1"
  }
}
