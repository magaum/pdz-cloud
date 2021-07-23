resource "aws_dynamodb_table" "tabela-contagem" {
  name           = "contagem"
  billing_mode   = "PROVISIONED"
  read_capacity  = 15
  write_capacity = 15
  hash_key       = "username"

  attribute {
    name = "username"
    type = "S"
  }
  
  tags = {
    Name        = "tabela-contagem"
    Environment = var.Environment
  }
}