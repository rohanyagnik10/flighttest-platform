variable "name" {
    type = string
    description = "Name of the environment"
}

variable "subnet_ids" {
    type = list(string)
    description = "Subnets for the cluster and nodes"
}

variable "k8s_version" {
    type = string
    default = "1.37"
}

variable "instance_type" {
    type = string
    default = "t3.small"
}

variable "node_count" {
    type = number
    default = 1
}

variable "admin_arns" {
    type = list(string)
    description = "Users and roles that get admin on the cluster"
}
