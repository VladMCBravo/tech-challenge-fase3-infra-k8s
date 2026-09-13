# api-gateway.tf

# 1. Variável para receber a URL do Load Balancer do EKS
variable "eks_lb_url" {
  description = "URL do Load Balancer gerado pelo Kubernetes"
  type        = string
  default     = "http://example.com" # <-- Alterado de localhost para passar na validação
}

# 2. Busca a Lambda de Autenticação criada pelo Repo 1
data "aws_lambda_function" "auth_lambda" {
  function_name = "oficina-auth-stack-AuthFunction-tehjPDXSbk5y" 
}

# 3. Cria o API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "oficina_api" {
  name          = "oficina-api-gateway"
  protocol_type = "HTTP"
}

# 4. ROTA DE LOGIN: Integração do API Gateway com a Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.oficina_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = data.aws_lambda_function.auth_lambda.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_route" {
  api_id    = aws_apigatewayv2_api.oficina_api.id
  route_key = "POST /auth" # Quando chamarem POST /auth, vai para a Lambda
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Dá permissão para o API Gateway invocar a Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.auth_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.oficina_api.execution_arn}/*/*"
}

# 5. ROTA PRINCIPAL: Integração do API Gateway com o EKS (Proxy)
resource "aws_apigatewayv2_integration" "eks_integration" {
  api_id             = aws_apigatewayv2_api.oficina_api.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "${var.eks_lb_url}/{proxy}"
  integration_method = "ANY"
}

resource "aws_apigatewayv2_route" "eks_route" {
  api_id    = aws_apigatewayv2_api.oficina_api.id
  route_key = "ANY /{proxy+}" # Manda todo o resto do tráfego para o NestJS
  target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

# 6. Publica o API Gateway (Stage padrão)
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.oficina_api.id
  name        = "$default"
  auto_deploy = true
}

# 7. Imprime a URL do API Gateway no final para você usar no Swagger/Postman
output "api_gateway_url" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}