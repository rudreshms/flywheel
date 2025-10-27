data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.network_state_bucket
    key    = var.network_state_key
    region = var.region
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "tf-db-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.db_subnet_ids
  tags       = { Name = "tf-db-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "tf-postgres"
  engine                 = "postgres"
  engine_version         = "15" # change if desired
  instance_class         = var.db_instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [data.terraform_remote_state.network.outputs.db_sg_id]
  multi_az               = var.multi_az
  skip_final_snapshot    = true
  publicly_accessible    = false
  deletion_protection    = false
  tags                   = { Name = "tf-postgres" }
}
output "db_endpoint" { value = aws_db_instance.postgres.address }
output "db_port" { value = aws_db_instance.postgres.port }