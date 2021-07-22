resource "aws_apigatewayv2_api" "contagem" {
  name          = "contagem-http-api"
  protocol_type = "HTTP"

  # depends_on = [
  #   aws_apigatewayv2_domain_name.contagem
  # ]
}

# resource "aws_apigatewayv2_api_mapping" "contagem" {
#   api_id      = aws_apigatewayv2_api.contagem.id
#   domain_name = aws_apigatewayv2_domain_name.contagem.id
#   stage       = aws_apigatewayv2_stage.contagem.id
# }

# resource "aws_apigatewayv2_domain_name" "contagem" {
#   domain_name = var.domain_name

#   domain_name_configuration {
#     certificate_arn = aws_acm_certificate.contagem.arn
#     endpoint_type   = "REGIONAL"
#     security_policy = "TLS_1_2"
#   }

#   timeouts {
#     create = "10m"
#   }
# }

# resource "aws_acm_certificate" "contagem" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   tags = {
#     Environment = var.Environment
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_zone" "contagem" {
#   name = var.domain_name

#   tags = {
#     Environment = var.Environment
#   }
# }


# resource "aws_route53_record" "contagem" {
#   name    = aws_apigatewayv2_domain_name.contagem.domain_name
#   type    = "A"
#   zone_id = aws_route53_zone.contagem.zone_id

#   alias {
#     name                   = aws_apigatewayv2_domain_name.contagem.domain_name_configuration[0].target_domain_name
#     zone_id                = aws_apigatewayv2_domain_name.contagem.domain_name_configuration[0].hosted_zone_id
#     evaluate_target_health = false
#   }
# }

resource "aws_apigatewayv2_integration" "contagem" {
  api_id           = aws_apigatewayv2_api.contagem.id
  description      = "contagem with a load balancer"
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.contagem.arn

  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.contagem.id

  # tls_config {
  #   server_name_to_verify = var.domain_name
  # }

  # request_parameters = {
  #   "append:header.authforintegration" = "$context.authorizer.authorizerResponse"
  #   "overwrite:path"                   = "staticValueForIntegration"
  # }

  # response_parameters {
  #   status_code = 403
  #   mappings = {
  #     "append:header.auth" = "$context.authorizer.authorizerResponse"
  #   }
  # }

  response_parameters {
    status_code = 200
    mappings = {
      "overwrite:statuscode" = "204"
    }
  }
}

# resource "aws_apigatewayv2_model" "contagem" {
#   api_id       = aws_apigatewayv2_api.contagem.id
#   content_type = "application/json"
#   name         = "contagem"

#   schema = <<EOF
# {
#   "$schema": "http://json-schema.org/draft-04/schema#",
#   "title": "contagemModel",
#   "type": "object",
#   "properties": {
#     "id": { "type": "string" }
#   }
# }
# EOF
# }

resource "aws_apigatewayv2_route" "contagem" {
  api_id    = aws_apigatewayv2_api.contagem.id
  route_key = "GET /count/{username}"

  target = "integrations/${aws_apigatewayv2_integration.contagem.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.contagem.name}"

  retention_in_days = 3
}

# resource "aws_apigatewayv2_route_response" "contagem" {
#   api_id             = aws_apigatewayv2_api.contagem.id
#   route_id           = aws_apigatewayv2_route.contagem.id
#   route_response_key = "$default"
# }

resource "aws_apigatewayv2_stage" "contagem" {
  auto_deploy = true
  api_id = aws_apigatewayv2_api.contagem.id
  name   = "count"
}

resource "aws_apigatewayv2_vpc_link" "contagem" {
  name               = "contagem"
  security_group_ids = [aws_security_group.contagem.id]
  subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  tags = {
    Usage = "contagem"
  }
}