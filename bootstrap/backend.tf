terraform {
    backend "s3" {
        bucket = "tfstate-flightest-0f93725e"
        key = "bootstrap/terraform.tfstate"
        region = "eu-west-1"
        encrypt = true
        dynamodb_table = "tfstate-lock-flighttest"
    }
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}
provider "aws" {
    region = "eu-west-1"
}
