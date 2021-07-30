resource "aws_api_gateway_rest_api" "contagem" {
  name = "contagens"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "contagem" {
  rest_api_id = aws_api_gateway_rest_api.contagem.id
  parent_id   = aws_api_gateway_rest_api.contagem.root_resource_id
  path_part   = "{username}"
}

resource "aws_api_gateway_method" "contagem" {
  rest_api_id   = aws_api_gateway_rest_api.contagem.id
  resource_id   = aws_api_gateway_resource.contagem.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.username" = true
  }
}

resource "aws_api_gateway_integration" "contagem" {
  http_method             = aws_api_gateway_method.contagem.http_method
  integration_http_method = "GET"
  resource_id             = aws_api_gateway_resource.contagem.id
  rest_api_id             = aws_api_gateway_rest_api.contagem.id
  type                    = "HTTP_PROXY"
  timeout_milliseconds    = 29000
  uri                     = "http://${aws_lb.contagem.dns_name}/{username}"

  request_parameters = {
    "integration.request.path.username" = "method.request.path.username"
  }

  depends_on = [
    aws_api_gateway_method.contagem
  ]
}

resource "aws_api_gateway_deployment" "contagem" {
  rest_api_id = aws_api_gateway_rest_api.contagem.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.contagem.id,
      aws_api_gateway_method.contagem.id,
      aws_api_gateway_integration.contagem.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "contagem" {
  deployment_id = aws_api_gateway_deployment.contagem.id
  rest_api_id   = aws_api_gateway_rest_api.contagem.id
  stage_name    = "contagem"
}

resource "aws_api_gateway_method_settings" "contagem" {
  rest_api_id = aws_api_gateway_rest_api.contagem.id
  stage_name  = aws_api_gateway_stage.contagem.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_account" "contagem" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_role.arn
}

resource "aws_iam_role" "api_gateway_role" {
  name = "api_gateway_role"

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
  name = "cloudwatch_api_gateway"
  role = aws_iam_role.api_gateway_role.id

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
