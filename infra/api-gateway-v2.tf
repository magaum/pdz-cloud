resource "aws_apigatewayv2_api" "contagem" {
  name          = "contagem-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["http://*", "https://*"]
  }
}

resource "aws_apigatewayv2_integration" "contagem" {
  api_id           = aws_apigatewayv2_api.contagem.id
  description      = "contagem with a load balancer"
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.contagem.arn

  integration_method = "GET"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.contagem.id

  response_parameters {
    status_code = 200
    mappings = {
      "overwrite:statuscode" = "204"
    }
  }
}

resource "aws_apigatewayv2_route" "contagem" {
  api_id    = aws_apigatewayv2_api.contagem.id
  route_key = "GET /count/{username}"

  target = "integrations/${aws_apigatewayv2_integration.contagem.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/apigateway/${aws_apigatewayv2_api.contagem.name}"

  retention_in_days = 3
}

resource "aws_apigatewayv2_stage" "contagem" {
  auto_deploy = true
  api_id      = aws_apigatewayv2_api.contagem.id
  default_route_settings {
    data_trace_enabled       = true
    detailed_metrics_enabled = true
    logging_level = "INFO"
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
  name = "count"
}

resource "aws_apigatewayv2_vpc_link" "contagem" {
  name               = "contagem"
  security_group_ids = [aws_security_group.public_contagem.id]
  subnet_ids         = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  tags = {
    Usage = "contagem"
  }
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_api_gateway_account" "api_gateway" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}
