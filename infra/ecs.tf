# resource "aws_ecs_cluster" "contador" {
#   name = "pdz"

#   setting {
#     name  = "containerInsights"
#     value = "enabled"
#   }
# }

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
  name                     = "contador-api"
  cluster                  = aws_ecs_cluster.contador_cluster.id
  task_definition          = aws_ecs_task_definition.contador.arn
  desired_count            = 1
  # launch_type              = "FARGATE"
  # network_mode             = "awsvpc"
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "contador"
    container_port   = 80
  }

  # network_configuration {
  #   subnets         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  #   security_groups = [aws_security_group.contagem.id]
  # }
  depends_on = [aws_lb_target_group.ecs_target_group]
}

resource "aws_ecs_task_definition" "contador" {
  family = "service"
  # requires_compatibilities = ["FARGATE"]
  # network_mode = "awsvpc"
  container_definitions = jsonencode([
    {
      name      = "contador"
      image     = "contador-service-image"
      cpu       = 10
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }
}
