resource "aws_lb" "contagem" {
  name               = "application-load-balancer"
  internal           = true
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  tags = {
    Environment = var.Environment
  }
}

resource "aws_lb_listener" "contagem" {
  load_balancer_arn = aws_lb.contagem.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.lambda_target_group.arn
        weight = 50
      }

      target_group {
        arn    = aws_lb_target_group.ecs_target_group.arn
        weight = 50
      }
    }
  }
}

resource "aws_lb_target_group" "lambda_target_group" {
  name        = "lambda-contagem-tg"
  target_type = "lambda"
  vpc_id      = aws_vpc.private.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb.contagem]
}

resource "aws_lb_target_group" "ecs_target_group" {
  name        = "ecs-contagem-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.private.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb.contagem]
}

resource "aws_lambda_permission" "lb_lambda_invoke_permission" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contagem.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda_target_group.arn
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda_target_group.arn
  target_id        = aws_lambda_function.contagem.arn
  depends_on       = [aws_lambda_permission.lb_lambda_invoke_permission]
}

# resource "aws_lb_target_group_attachment" "ecs" {
#   target_group_arn = aws_lb_target_group.ecs_target_group.arn
#   target_id        = aws_ecs_service.contador.id
#   port = 80
# }
