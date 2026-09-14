# tech-challenge-fase3-infra-k8s — Infraestrutura Kubernetes (Terraform)

Provisiona, via **Terraform**, o **cluster Amazon EKS** (com node group) e o **API Gateway** que roteia o tráfego para a Lambda de autenticação e para a aplicação.

## Propósito

Criar e versionar a infraestrutura de orquestração e roteamento:
- **Amazon EKS** (cluster + node group) — onde a aplicação roda;
- **VPC** (módulo `terraform-aws-modules/vpc`) com subnets públicas/privadas e NAT;
- **API Gateway (HTTP API)** com as rotas `POST /auth` (→ Lambda) e `ANY /{proxy+}` (→ Load Balancer do EKS).

> Repositório **sem Dockerfile** — contém apenas código Terraform, sem finalidade técnica para um contêiner.

## Tecnologias

- **Terraform** (provider `hashicorp/aws ~> 5.0`)
- **AWS:** EKS, VPC, API Gateway
- **State remoto:** S3 (`backend.tf`)

## Pré-requisitos

- Terraform 1.5+
- Credenciais AWS (com permissão para EKS/EC2/API Gateway)
- Bucket S3 do state remoto já existente (compartilhado com o `infra-db`)

## Recursos

| Arquivo | Conteúdo |
|---|---|
| `network.tf` | VPC, subnets, NAT (módulo VPC) |
| `eks.tf` | Cluster EKS + node group |
| `api-gateway.tf` | HTTP API + integrações (Lambda e EKS) + rotas |
| `variables.tf` | Variáveis (região, nome do cluster, etc.) |
| `backend.tf` | Estado remoto do Terraform no S3 (ver ADR-004) |

## Execução

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Após aplicar, para acessar o cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name oficina-eks-cluster-v2
kubectl get nodes
```

## Pipeline de CI/CD (GitHub Actions)

Disparada em Pull Request (apenas `plan`) e no merge para `main` (`plan` + `apply`), com a branch `main` protegida:
`init` → **`import`** (traz cluster/nós existentes para o state) → `fmt -check` → `plan` → `apply` (somente no push para `main`).

Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`.

## Arquitetura do componente

```mermaid
flowchart TB
    TF[Terraform] --> VPC[VPC + subnets + NAT]
    TF --> EKS[EKS Cluster + Node Group]
    TF --> GW[API Gateway HTTP API]
    GW -->|/auth| LAMBDA[Lambda auth]
    GW -->|/{proxy+}| ELB[Load Balancer do EKS]
```

## Observações

- **State remoto (S3)** configurado em `backend.tf` (ver **ADR-004**), como no `infra-db`.
- O pipeline **importa o cluster e o node group** existentes para o state. A VPC é criada pelo módulo `vpc`; ao adotar o state remoto sobre uma infra **já existente**, faça um **bootstrap único supervisionado** (import do módulo VPC + revisão do `plan`) com o ambiente aberto, antes de qualquer `apply`.
- A integração `ANY /{proxy+}` do API Gateway aponta para o endereço do **Load Balancer** do Service da aplicação, que pode mudar quando o Service é recriado — reapontar quando necessário.
