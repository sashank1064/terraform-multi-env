# terraform-multi-env

> Multi-environment Terraform — promote the same infrastructure across **dev**, **stage**, and **prod** with isolated state, per-env variables, and zero code duplication.

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)
![HCL](https://img.shields.io/badge/HCL-844FBA?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?logo=amazonaws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?logo=githubactions&logoColor=white)

## What this is

The infrastructure from [`terraform`](https://github.com/sashank1064/terraform), promoted into a proper multi-environment layout. One set of modules, three deployed environments, separate state for each, and a CI pipeline that runs `plan` on PR and `apply` on merge.

The goal: changing `dev` must not be able to accidentally touch `prod`.

## Environment strategy

I use a **directory-per-environment** layout (not workspaces) because:

- Environments are visibly separate in the file tree — new engineers can see at a glance what exists
- Each env has its own state file and backend config → blast radius is physical, not convention
- Per-env policies and variables live next to the env, not in a tangle of `locals { workspace_dispatch = ... }`
- Workspaces are still used internally for short-lived feature branches within `dev`

## Repo layout

```
.
├── modules/                  # shared, reusable modules (no env-specific logic)
│   ├── vpc/
│   ├── ec2/
│   ├── alb/
│   ├── route53/
│   ├── sg/
│   └── iam/
├── envs/
│   ├── dev/
│   │   ├── backend.tf        # S3 bucket + key per env
│   │   ├── provider.tf
│   │   ├── main.tf           # module calls with dev values
│   │   └── terraform.tfvars
│   ├── stage/
│   │   └── ...
│   └── prod/
│       └── ...
├── policies/                 # OPA / Sentinel policies applied to every env
├── .github/workflows/
│   ├── plan.yml              # runs on PR, posts plan as comment
│   └── apply.yml             # runs on merge to main, env-scoped via labels
└── README.md
```

## Per-environment differences

| Setting | dev | stage | prod |
|---|---|---|---|
| Instance type | `t3.small` | `t3.medium` | `m5.large` |
| Multi-AZ DB | no | yes | yes |
| NAT gateway | single | single | per-AZ |
| Backups | 1 day | 7 days | 35 days |
| Deletion protection | off | on | on |
| CloudWatch detailed monitoring | off | on | on |
| Tags.`Environment` | `dev` | `stage` | `prod` |

All differences live in each env's `terraform.tfvars` — modules themselves never branch on environment.

## Running it

```bash
# Move into the environment you want to operate on
cd envs/dev

terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Promotion to stage is the same flow in envs/stage, via a reviewed PR
```

The `main` branch is protected. `apply` only runs after a human has approved the plan comment on the PR.

## CI pipeline

**`.github/workflows/plan.yml`** — on every PR touching `envs/*`:
1. `terraform fmt -check -recursive`
2. `tflint`
3. `terraform init` with the env's backend
4. `terraform plan` — result posted as a collapsible PR comment
5. `checkov` / OPA policy scan

**`.github/workflows/apply.yml`** — on merge to `main`:
1. Re-runs `plan` to guard against drift between PR and merge
2. If identical, runs `apply` against the detected environment
3. Posts apply output back to the original PR

## State management

- **Backend:** S3 with server-side encryption + versioning
- **Locking:** DynamoDB table (`terraform-state-lock`) — prevents concurrent apply
- **Keys:** `envs/<env>/terraform.tfstate` — one file per env, never shared
- **Access:** IAM role assumed by CI, with different roles per env so `dev` credentials cannot write to `prod` state

## What this demonstrates

- **Promotion discipline** — dev → stage → prod is code, not vibes
- **Blast-radius isolation** — state, credentials, and config are all partitioned per env
- **Repeatable review** — `plan` comments on PRs mean every change is visible before it ships
- **Policy as code** — OPA rules enforce "no `0.0.0.0/0` SSH", "RDS must be encrypted", "S3 must have versioning", etc.
- **No copy-paste** — shared modules, env-specific variables, end of story

## Progression

1. [`shell-roboshop`](https://github.com/sashank1064/shell-roboshop)
2. [`ansible-roboshop`](https://github.com/sashank1064/ansible-roboshop)
3. [`ansible-roboshop-roles`](https://github.com/sashank1064/ansible-roboshop-roles)
4. [`terraform`](https://github.com/sashank1064/terraform) — single-env infra
5. **`terraform-multi-env`** ← you are here

---

Part of my DevOps portfolio.
