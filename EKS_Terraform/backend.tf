terraform {
  backend "s3" {
    bucket = "backend-863421994712-ap-south-1-an"
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
}