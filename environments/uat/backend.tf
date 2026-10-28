terraform {
    backend "s3" {
        bucket = "tfstate-flightest-0f93725e"
        key = "platform/uat/terraform.tfstate"
        region = "eu-west-1"
        encrypt = true
        dynamodb_table = "tfstate-lock-flighttest"
    }
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.70"
        }
        helm = {
            source = "hashicorp/helm"
            version = "~> 2.17"
        }
    }
}
provider "aws" {
    region = "eu-west-1"
}

data "aws_eks_cluster_auth" "uat" {
    name = module.eks.cluster_name
}

provider "helm" {
    kubernetes {
        host = module.eks.endpoint
        cluster_ca_certificate = base64decode(module.eks.ca)
        token = data.aws_eks_cluster_auth.uat.token
    }
}
