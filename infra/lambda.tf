resource "aws_iam_role" "lambda_permission" {
  name = "lambda_permission"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "contagem" {
  type = "zip"

  source_dir  = "${path.module}./lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "pdz-lambda-contagem"

  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_object" "contagem" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "contagem.zip"
  source = data.archive_file.contagem.output_path

  etag = filemd5(data.archive_file.contagem.output_path)
}


resource "aws_lambda_function" "contagem" {
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.contagem.key
  function_name = var.lambda_name
  source_code_hash = data.archive_file.contagem.output_base64sha256
  role          = aws_iam_role.lambda_permission.arn
  handler       = "index.handler"

  runtime = "nodejs12.x"

  vpc_config {
    subnet_ids         = [aws_subnet.public_subnet_a.id]
    security_group_ids = [aws_security_group.public_contagem.id]
  }

  environment {
    variables = {
      Name = "contagem",
      Environment = var.Environment
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.contagem,
  ]
}

resource "aws_cloudwatch_log_group" "contagem" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 3
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
# "Resource": "arn:aws:logs:*:*:*",
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_permission.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}