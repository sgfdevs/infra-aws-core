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

## Workflow bootstrap Headscale access

The existing `GitHubActionsInfraVMWorkloadsRole` gets `sts:AssumeRole`
only to
`arn:aws:iam::<LZ_ACCOUNT_ID>:role/SGFDevsBootstrapTailnetParameterReader`.
The new permission requires the existing main GitHub OIDC subject,
`repo:sgfdevs@53604170/infra-vm-workloads@1189754282:ref:refs/heads/main`.
Its GitHub trust and existing workload permissions are unchanged. The source
role gets no direct LZ SSM access or new IAM management permissions.

Set the required `TF_VAR_lz_aws_account_id` to the verified LZ account
owning that reader. The destination role name is defined by
[LZ AWS core](https://github.com/glitchedmob/infra-aws-core). The ARN is
deterministic and needs no remote state or cross-account IAM lookup. SGF's own
account ID still comes from `aws_caller_identity.current.account_id`.
This repository does not publish numeric account IDs. Match this input to
the existing LZ account configuration. The VM repository's
`/vm-workloads/sgfdevs/infra-vm-workloads/lz-aws-account-id` parameter
must identify the same account. Its checked-in `CHANGEME` value is not evidence
of a verified account.

The LZ reader trusts only this workflow role and allows `ssm:GetParameter`
only on `/homelab/headscale/pods/sgfdevs/ingress-gateway-auth-key`.
It is separate from the existing `SGFDevsTailnetParameterReader` Kubernetes
OIDC reader. The parameter's
[owner module](https://github.com/glitchedmob/infra-app-config/blob/34bb24f88d2b75586caf40f81b866f8f7ac303dd/src/tf/modules/headscale/modules/pre-auth-key/main.tf)
uses `SecureString` without `key_id`, so no customer-managed KMS
permissions are added.

Use the existing manual Ansible workflow on main with
`initialize-terraform=true`. The reusable workflow configures the initial
AWS credentials only when that input is true. AWS documents OIDC `sub` as
[available in the original role session](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#condition-keys-wif),
so it can constrain this source session's assume-role request without changing
role trust or relying on a workflow-name context key.

Assume the LZ bootstrap reader on the controller only when the SGF tailnet
Secret is absent. Use the returned short-lived credentials only for its
decrypted SSM lookup, then discard them. Role chaining permits at most a
one-hour session. Existing complete Secrets require no role assumption.
Do not persist credentials or broaden the runtime reader's trust. Requests
from PRs or other branches do not get the new bootstrap permission.

## Operating constraints
- Apply this repo before dependent stacks that use the shared backend and IAM role outputs.
- SGF K3s workload roles must use the core-owned permissions boundary under `/sgfdevs-k3s/`.
- Applies are manual/local; CI runs validation only.
