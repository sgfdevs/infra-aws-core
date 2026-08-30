# infra-aws-core

Provisions SGFDEVS shared AWS foundation resources, including remote state backend, CI access roles, and account access baseline.

## Scope
- Owns: S3 + DynamoDB backend resources used by OpenTofu/Terraform state.
- Owns: GitHub Actions OIDC trust and IAM role/policies for infrastructure automation.
- Owns: AWS IAM Identity Center groups, permission sets, and account assignments.
- Owns: SGF K3s workload identity trust and its permissions boundary.

## Structure
- `src/tf/`: OpenTofu resources for backend, IAM/OIDC, and Identity Center.
- `.github/workflows/`: Validation workflow for Terraform/OpenTofu changes.

## Run
```bash
make help
make tf-init
make tf-plan
make tf-apply
make tf-output
```

## Operating constraints
- Apply this repo before dependent stacks that use the shared backend and IAM role outputs.
- SGF K3s workload roles must use the core-owned permissions boundary under `/sgfdevs-k3s/`.
- Applies are manual/local; CI runs validation only.
