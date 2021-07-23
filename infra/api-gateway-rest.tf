resource "aws_api_gateway_account" "contagem" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
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

resource "aws_api_gateway_api_key" "contagem" {
  name = "x-api-key"
}

resource "aws_api_gateway_rest_api" "contagem" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "contagem"
      version = "1.0"
    }
    paths = {
      "/" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "http://${aws_lb.contagem.dns_name}"
          }
        }
      }
    }
  })

  name = "contagens"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "contagem" {
  rest_api_id = aws_api_gateway_rest_api.contagem.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.contagem.body))
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
  }
}