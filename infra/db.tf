resource "aws_dynamodb_table" "tabela_contagem" {
  name           = var.DynamoTableName
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "username"

  attribute {
    name = "username"
    type = "S"
  }

  tags = {
    Name        = var.DynamoTableName
    Environment = var.Environment
  }
}
