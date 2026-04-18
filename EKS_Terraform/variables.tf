variable "project_name" {
  default = "myproject"
}

variable "region" {
  default = "eu-west-3"
}

variable "azs" {
  default = ["eu-west-3a", "eu-west-3b"]
}

variable "ssh_key_name" {
  description = "SSH key for node access"
  type        = string
  default     = "1"
}
