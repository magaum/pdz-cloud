resource "aws_lb" "example" {
  name               = "application-load-balancer"
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.private.*.id

  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}