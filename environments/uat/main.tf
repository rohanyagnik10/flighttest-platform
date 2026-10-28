data "aws_caller_identity" "current" {}

locals {
    admins = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/terraform-user",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/jenkins-deployer",
    ]
}

module "network" {
  source   = "../../modules/network"
  vpc_cidr = "10.0.0.0/16"
  name     = "uat"
}

module "eks" {
    source = "../../modules/eks"
    name = "uat"
    subnet_ids = module.network.private_subnet_ids
    instance_type = "t3.medium"
    node_count = 2
    admin_arns = local.admins

    depends_on = [aws_iam_role.jenkins]
}
