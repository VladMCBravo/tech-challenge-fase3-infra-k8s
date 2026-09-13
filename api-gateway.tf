# api-gateway.tf

# 1. Variável para receber a URL do Load Balancer do EKS
variable "eks_lb_url" {
  description = "URL do Load Balancer gerado pelo Kubernetes"
  type        = string
  default     = "http://example.com"
}

# 2. (Opcional) Bloco da Lambda de Autenticação removido/comentado pois a Lambda foi resetada na AWS.
# Se precisar reativar no futuro, descomente o data e as rotas abaixo junto com a Lambda.

# 3. Cria o API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "oficina_api" {
  name          = "oficina-api-gateway"
  protocol_type = "HTTP"
}

# 4. ROTA PRINCIPAL: Integração do API Gateway com o EKS (Proxy)
resource "aws_apigatewayv2_integration" "eks_integration" {
  api_id             = aws_apigatewayv2_api.oficina_api.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "http://a0b6f753bd37b43969ae65bb02b3ce00-1235088358.us-east-1.elb.amazonaws.com/{proxy}"
  integration_method = "ANY"
}

resource "aws_apigatewayv2_route" "eks_route" {
  api_id    = aws_apigatewayv2_api.oficina_api.id
  route_key = "ANY /{proxy+}" # Manda todo o tráfego para o NestJS no EKS
  target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

# 5. Publica o API Gateway (Stage padrão)
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.oficina_api.id
  name        = "$default"
  auto_deploy = true
}

# 6. Imprime a URL do API Gateway no final para você usar no Postman
output "api_gateway_url" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}