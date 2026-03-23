terraform {
  backend "s3" {
    bucket         = "sgfdevs-global-tfstate"
    key            = "global/infra.tfstate"
    region         = "us-east-2"
    dynamodb_table = "sgfdevs-global-tflock"
    encrypt        = true
  }
}
