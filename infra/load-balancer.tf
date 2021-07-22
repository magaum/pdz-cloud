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
    type = "redirect"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = "contagem-lb-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.private.id
}

resource aws_lambda_permission lb_lambda_invoke_permission {
  statement_id = "AllowExecutionFromALB"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contagem.function_name
  principal = "elasticloadbalancing.amazonaws.com"
  source_arn = aws_lb_target_group.lb_target_group.arn
}
resource aws_lb_target_group_attachment main {
  target_group_arn = aws_lb_target_group.lb_target_group.arn
  target_id = aws_lambda_function.contagem.arn
  depends_on = [ aws_lambda_permission.lb_lambda_invoke_permission ]
}