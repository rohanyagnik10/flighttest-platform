resource "aws_iam_role" "cluster" {
    name = "${var.name}-eks-cluster"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "eks.amazonaws.com" }
            Action = ["sts:AssumeRole", "sts:TagSession"]
        }]
    })
}

resource "aws_iam_role_policy_attachment" "cluster" {
    role = aws_iam_role.cluster.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "main" {
    name = "${var.name}-cluster"
    version = var.k8s_version
    role_arn = aws_iam_role.cluster.arn

    vpc_config {
        subnet_ids = var.subnet_ids
    }

    access_config {
        authentication_mode = "API"
        bootstrap_cluster_creator_admin_permissions = false
    }

    depends_on = [aws_iam_role_policy_attachment.cluster]
}

resource "aws_iam_role" "node" {
    name = "${var.name}-eks-node"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "node" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    ])

    role = aws_iam_role.node.name
    policy_arn = each.value
}

resource "aws_eks_node_group" "main" {
    cluster_name = aws_eks_cluster.main.name
    node_group_name = "${var.name}-nodes"
    node_role_arn = aws_iam_role.node.arn
    subnet_ids = var.subnet_ids
    instance_types = [var.instance_type]

    scaling_config {
        desired_size = var.node_count
        min_size = 1
        max_size = 3
    }

    depends_on = [aws_iam_role_policy_attachment.node]
}

resource "aws_eks_addon" "pod_identity" {
    cluster_name = aws_eks_cluster.main.name
    addon_name = "eks-pod-identity-agent"

    depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_access_entry" "admin" {
    for_each = toset(var.admin_arns)

    cluster_name = aws_eks_cluster.main.name
    principal_arn = each.value
}

resource "aws_eks_access_policy_association" "admin" {
    for_each = toset(var.admin_arns)

    cluster_name = aws_eks_cluster.main.name
    principal_arn = each.value
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    access_scope {
        type = "cluster"
    }

    depends_on = [aws_eks_access_entry.admin]
}
