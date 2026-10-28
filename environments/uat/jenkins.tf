resource "aws_iam_role" "jenkins" {
    name = "jenkins-deployer"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "pods.eks.amazonaws.com" }
            Action = ["sts:AssumeRole", "sts:TagSession"]
        }]
    })
}

resource "aws_iam_role_policy_attachment" "jenkins" {
    role = aws_iam_role.jenkins.name
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_eks_pod_identity_association" "jenkins" {
    cluster_name = module.eks.cluster_name
    namespace = "jenkins"
    service_account = "jenkins-agent"
    role_arn = aws_iam_role.jenkins.arn
}

resource "helm_release" "jenkins" {
    name = "jenkins"
    repository = "https://charts.jenkins.io"
    chart = "jenkins"
    version = "5.9.73"
    namespace = "jenkins"
    create_namespace = true
    timeout = 900

    values = [file("${path.module}/jenkins-values.yaml")]

    set_sensitive {
        name = "controller.admin.password"
        value = data.aws_ssm_parameter.jenkins_password.value
    }

    depends_on = [module.eks]
}

data "aws_ssm_parameter" "jenkins_password" {
    name = "/jenkins/admin-password"
}
