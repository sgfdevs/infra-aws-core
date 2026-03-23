# SGF Devs AWS Core Infrastructure

OpenTofu configuration for SGF Devs global AWS bootstrap resources. This is a local-only stack; all applies run from a workstation, not CI/CD.

## Scope

- OpenTofu in `src/tf/` provisions global backend resources and AWS Identity Center configuration.

The stack includes:

- S3 bucket `sgfdevs-infra-tf-state` for remote state storage
- DynamoDB table `sgfdevs-infra-tflock` for state locking
- AWS Identity Center groups, permission sets, and account assignments
- GitHub Actions OIDC provider and IAM role

## Usage

### Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.11 (version pinned in `src/tf/.tofu-version`)
- AWS credentials configured locally

### Local Operations

```bash
make help
make tf-init
make tf-plan
make tf-show ARGS=tfplan
make tf-output
make tf-apply
make tf-validate
make tf-format
make tf-lint-fix
```

## CI Checks

On pull requests and pushes to `main`, CI runs validation only:

- `tofu validate`
- `tofu fmt -check`

## Outputs

| Output | Description |
|--------|-------------|
| `backend_bucket_name` | S3 bucket for Terraform state |
| `backend_table_name` | DynamoDB table for state locking |
| `github_actions_role_arn` | IAM role ARN for GitHub Actions (sensitive) |

## Operational Notes

- Apply this stack before other SGF Terraform stacks that depend on remote state.
- Backend state key remains `global/infra.tfstate` for this first migration pass.
- GitHub role SSM permissions are scoped to specific parameter paths.
