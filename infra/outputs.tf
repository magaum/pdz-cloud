output "lb_dns_name" {
  value = aws_lb.contagem.dns_name
}

output "ecr_repository" {
  value = aws_ecr_repository.contagem.repository_url
}