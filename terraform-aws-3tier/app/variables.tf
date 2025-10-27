variable "region" {
  default = "eu-west-2"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "desired_capacity" {
  default = 2
}

variable "max_size" {
  default = 3
}

variable "min_size" {
  default = 1
}

variable "ssh_key_name" {
  default = "your-ssh-key-name"
}

variable "network_state_bucket" {
  type    = string
  default = "flywheel-terraform-state-bucket"
}

variable "network_state_key" {
  type    = string
  default = "test/network/terraform.tfstate"
}