resource "aws_ecr_repository" "contagem" {
  name = var.repository_name
}

resource "aws_ecs_cluster" "contador_cluster" {
  name = "pdz"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.kms_ecs.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.contador_logs.name
      }
    }
  }
}

resource "aws_kms_key" "kms_ecs" {
  description             = "contagem"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "contador_logs" {
  name = "contagem"
}

resource "aws_ecs_service" "contador" {
  name            = "contador-api"
  cluster         = aws_ecs_cluster.contador_cluster.id
  task_definition = aws_ecs_task_definition.contador.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "contador"
    container_port   = 80
  }

  network_configuration {
    security_groups = [aws_security_group.private_contagem.id]
    subnets         = [aws_subnet.private_subnet_a.id]
  }

  depends_on = [aws_lb_target_group.ecs_target_group]
}

resource "aws_cloudwatch_log_group" "contador" {
  name = "ecs-log-group"

  tags = {
    Environment = var.Environment
  }
}

resource "aws_ecs_task_definition" "contador" {
  family = "contador"
  container_definitions = jsonencode([
    {
      name        = "contador"
      image       = "aws_ecr_repository.contador.repository_url"
      cpu         = 10
      networkMode = "awsvpc"
      memory      = 256
      essential   = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group : aws_cloudwatch_log_group.contador.name,
          awslogs-region : var.region,
          awslogs-stream-prefix : "web"
        }
      }
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_execution_role.arn
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  EOF
}

resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
  EOF
  role   = aws_iam_role.ecs_execution_role.id
}
