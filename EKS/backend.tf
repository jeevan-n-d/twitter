terraform {
  backend "s3" {
    bucket = "myproject-terraform-state-2026-devsecops"
    key    = "twitter/eks/terraform.tfstate"
    region = "ap-south-2"
  }
}