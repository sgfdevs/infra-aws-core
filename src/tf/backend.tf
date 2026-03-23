terraform {
  backend "s3" {
    bucket         = "sgfdevs-infra-tf-state"
    key            = "global/infra.tfstate"
    region         = "us-east-2"
    dynamodb_table = "sgfdevs-infra-tflock"
    encrypt        = true
  }
}
