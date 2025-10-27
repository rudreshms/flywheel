terraform {
  backend "s3" {
    bucket       = "flywheel-terraform-state-bucket"
    key          = "test/database/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}