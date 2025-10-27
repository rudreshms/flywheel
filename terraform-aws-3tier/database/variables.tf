variable "region" {
  default = "eu-west-2"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  type    = string
  default = "admin@123"
}

variable "db_name" {
  default = "appdb"
}

variable "db_instance_class" {
  default = "db.t3.micro"
} # change to free-tier eligible if needed

variable "allocated_storage" {
  default = 20
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "network_state_bucket" {
  type    = string
  default = "flywheel-terraform-state-bucket"
}

variable "network_state_key" {
  type    = string
  default = "test/network/terraform.tfstate"
} # e.g. "test/database/terraform.tfstate"