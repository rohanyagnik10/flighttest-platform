data "aws_caller_identity" "current" {}

locals {
    admins = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/terraform-user",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/jenkins-deployer",
    ]
}

module "network" {
  source   = "../../modules/network"
  vpc_cidr = "10.3.0.0/16"
  name     = "preprod"
}

module "eks" {
    source = "../../modules/eks"
    name = "preprod"
    subnet_ids = module.network.private_subnet_ids
    admin_arns = local.admins
}
