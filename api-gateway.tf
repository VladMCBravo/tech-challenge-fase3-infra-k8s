# api-gateway.tf

# 1. URL do Load Balancer do EKS (Service oficina-backend-svc), SEM barra no final.
#    O ELB muda quando o Service é recriado no cluster — se isso acontecer,
#    atualize este default (kubectl get svc oficina-backend-svc -> EXTERNAL-IP).
variable "eks_lb_url" {
  description = "URL do Load Balancer do Service oficina-backend-svc"
  type        = string
  default     = "http://a856a7f4070a44d5db3300e8778b4204-1644348812.us-east-1.elb.amazonaws.com"
}

# 2. Busca a Lambda de Autenticação criada pelo repo serverless-auth
data "aws_lambda_function" "auth_lambda" {
  function_name = "oficina-auth-stack-AuthFunction-zxFaZdpy5es7"
}

# 3. Cria o API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "oficina_api" {
  name          = "oficina-api-gateway"
  protocol_type = "HTTP"
}

# 4. ROTA DE LOGIN: API Gateway -> Lambda (POST /auth)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.oficina_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = data.aws_lambda_function.auth_lambda.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_route" {
  api_id    = aws_apigatewayv2_api.oficina_api.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Permissão para o API Gateway invocar a Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id_prefix = "AllowExecutionFromAPI-"
  action              = "lambda:InvokeFunction"
  function_name       = data.aws_lambda_function.auth_lambda.function_name
  principal           = "apigateway.amazonaws.com"
  source_arn          = "${aws_apigatewayv2_api.oficina_api.execution_arn}/*/*"
}

# 5. ROTA PRINCIPAL: API Gateway -> EKS (Load Balancer do app), todo o resto do trafego
resource "aws_apigatewayv2_integration" "eks_integration" {
  api_id             = aws_apigatewayv2_api.oficina_api.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "${var.eks_lb_url}/{proxy}"
  integration_method = "ANY"
}

resource "aws_apigatewayv2_route" "eks_route" {
  api_id    = aws_apigatewayv2_api.oficina_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

# 6. Publica o API Gateway (stage padrao, auto-deploy)
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.oficina_api.id
  name        = "$default"
  auto_deploy = true
}

# 7. Imprime a URL do API Gateway (usar no Swagger/Postman)
output "api_gateway_url" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}
