# flighttest-platform

Terraform for a flight test data platform on AWS (eu-west-1). Three environments, each with its own VPC and EKS cluster. Jenkins runs on the uat cluster, runs this Terraform and deploys the [website](https://github.com/rohanyagnik10/cambridge-aerospace-website).

## Layout

```
bootstrap/          state bucket
modules/network/    vpc, subnets, nat gateway, s3 endpoint, security groups
modules/eks/        eks cluster, node group, access entries
environments/       uat, preprod, prod
Jenkinsfile         init, validate, plan, approve, apply
```

## Environments

| env     | cidr        | nodes                        |
|---------|-------------|------------------------------|
| uat     | 10.0.0.0/16 | 2 x t3.small (runs jenkins)      |
| preprod | 10.3.0.0/16 | 1 x t3.small                 |
| prod    | 10.4.0.0/16 | 1 x t3.small                 |

Ranges don't overlap so they can be connected later. Full account plan is in account-plan.txt.

## Build order

1. bootstrap - the state bucket. Created by hand first, then imported.
2. uat - has to go first because it creates the jenkins-deployer role that the preprod and prod clusters trust.
   ```
   cd environments/uat
   terraform init
   terraform apply -target=module.eks
   terraform apply
   ```
   The first apply only builds the cluster because the helm provider needs the cluster to exist.
3. preprod and prod
   ```
   terraform init
   terraform apply
   ```

## Jenkins

- Installed with Helm from Terraform (environments/uat/jenkins.tf)
- Controller has 0 executors. Builds run in pods that get deleted after
- Jobs are created from config with job-dsl, nothing is set up by clicking
- Agent pods get AWS access through EKS Pod Identity, no access keys stored anywhere
- The load balancer only lets in GitHub webhook IPs. For the UI use port-forward:
  ```
  kubectl -n jenkins port-forward svc/jenkins 8080:8080
  kubectl -n jenkins get secret jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
  ```

## What I would change for real

- Jenkins role has AdministratorAccess, it should be scoped down
- Jenkins should be in the devops account, not uat
- One NAT gateway per environment. Prod should have one per AZ
- uat RDS has no backups and no multi-az
- Jenkins has no persistent volume so build history is lost on restart
- Webhook is http not https
