# terraform-multi-env

Two ways to run the same Terraform across dev and prod, side by side, so you can see the trade-offs: **per-environment tfvars files** vs **Terraform workspaces**.

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)
![HCL](https://img.shields.io/badge/HCL-844FBA?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?logo=amazonaws&logoColor=white)

## Overview

When you spin up the same infrastructure in more than one environment, you have a choice: feed environment-specific values through separate `*.tfvars` files, or use `terraform workspace` and branch on `terraform.workspace` inside your config. Both work. They fail differently under pressure.

This repo runs the same EC2 + SG setup (Roboshop-style) under both patterns so the differences are visible in code, not in slide decks.

## Repo layout

```
.
├── tf-vars/                 # approach 1: one tfvars file per environment
│   ├── provider.tf
│   ├── ec2.tf
│   ├── varibles.tf
│   ├── dev/
│   │   ├── dev.tfvars       # dev-specific values
│   │   └── backend.tfvars   # dev-specific backend config
│   └── prod/
│       ├── prod.tfvars
│       └── backend.tfvars
└── workspaces/              # approach 2: terraform workspaces + lookup()
    ├── provider.tf
    ├── ec2.tf               # uses terraform.workspace in names and tags
    └── varibles.tf          # instance_type is a map keyed by workspace
```

## Approach 1: per-environment tfvars

```bash
cd tf-vars

# Init with the env-specific backend (separate state per env)
terraform init -backend-config=dev/backend.tfvars

# Plan and apply against that env's values
terraform plan -var-file=dev/dev.tfvars -out=tfplan
terraform apply tfplan

# Prod is the same flow with prod/ files
```

**Good for:** teams that want the env differences to be visible in the file tree. New engineers can read `dev/dev.tfvars` and know exactly what's different about dev.

**Trade-off:** every `init`, `plan`, `apply` needs the right `-var-file` and `-backend-config`. Easy to forget, which is why the wrapper script or CI has to enforce it.

## Approach 2: Terraform workspaces

```bash
cd workspaces

terraform init
terraform workspace new dev
terraform workspace new prod

# Switch and apply
terraform workspace select dev
terraform plan -out=tfplan
terraform apply tfplan
```

The config branches on `terraform.workspace`:

```hcl
resource "aws_instance" "roboshop" {
  instance_type = lookup(var.instance_type, terraform.workspace)
  tags = {
    Name        = "${var.Project}-${var.instances[count.index]}-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
```

**Good for:** quick, low-ceremony separation when envs share one backend.

**Trade-off:** all workspaces live under one state bucket key prefix, so access control is coarser. Easier to accidentally run against the wrong workspace. I reach for this inside `dev` for short-lived feature stacks, not across dev/prod.

## Why both in one repo

To make the choice defensible. When a team asks "which pattern should we use?", the honest answer is usually "separate directories and state per env (tf-vars style) for dev/stage/prod; workspaces only for short-lived sandboxes inside an env." Having both side by side makes that easy to explain in a code review.

## Related repos

1. [`terraform`](https://github.com/sashank1064/terraform): Terraform patterns reference
2. [`terraform-aws-vpc`](https://github.com/sashank1064/terraform-aws-vpc), [`terraform-aws-securitygroup`](https://github.com/sashank1064/terraform-aws-securitygroup), [`terraform-aws-instance`](https://github.com/sashank1064/terraform-aws-instance): published reusable modules
3. [`terraform-aws-roboshop`](https://github.com/sashank1064/terraform-aws-roboshop): component-level infra
4. [`roboshop-infra-dev`](https://github.com/sashank1064/roboshop-infra-dev): layered RoboShop deployment
