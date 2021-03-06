resource "aws_ecs_cluster" "contador_cluster" {
  name = "contador"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.kms_ecs.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.contador.name
      }
    }
  }
}

resource "aws_kms_key" "kms_ecs" {
  description             = "contagem"
  deletion_window_in_days = 7
}

resource "aws_ecs_service" "contador" {
  name             = "contador-api"
  cluster          = aws_ecs_cluster.contador_cluster.id
  task_definition  = aws_ecs_task_definition.contador.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.3.0"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "contador-api"
    container_port   = 80
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_security_group.id]
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    assign_public_ip = true
  }

  depends_on = [aws_lb_target_group.ecs_target_group]
}

resource "aws_cloudwatch_log_group" "contador" {
  name = "ecs-log-group"

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "contador" {
  family                   = "contador"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.contador_ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([
    {
      name        = "contador-api"
      image       = "magaum/asp-pdz-ecs:latest"
      cpu         = 1
      networkMode = "awsvpc"
      memory      = 256
      essential   = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group : aws_cloudwatch_log_group.contador.name,
          awslogs-region : var.region,
          awslogs-stream-prefix : "/aws/ecs"
        }
      }
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      Environment = [
        {
          "Name" : "ASPNETCORE_ENVIRONMENT",
          "Value" : var.environment
        },
        {
          "Name" : "REGION",
          "Value" : var.region
        },
        {
          "Name" : "TABLE_NAME",
          "Value" : var.dynamo_table_name
        }
      ]
    }
  ])
}

resource "aws_iam_role" "task_role" {
  name               = "ecs_task_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "contador_ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.contador_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_policy" {
  name   = "ecs_policy"
  role   = aws_iam_role.task_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "logs:CreateLogStream",
                "logs:GetLogEvents",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "ecs:RunTask"
            ],
            "Resource": [
                "${aws_ecs_task_definition.contador.arn}"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "ecs:StopTask",
                "ecs:DescribeTasks"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}
