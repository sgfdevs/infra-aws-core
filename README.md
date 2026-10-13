# infra-aws-core

Provisions SGFDEVS shared AWS foundation resources, including remote state backend, CI access roles, and account access baseline.

## Scope
- Owns: S3 + DynamoDB backend resources used by OpenTofu/Terraform state.
- Owns: GitHub Actions OIDC trust and IAM role/policies for infrastructure automation.
- Owns: AWS IAM Identity Center groups, permission sets, and account assignments.
- Owns: The narrow IAM user and inline policy for static K3s ingress bootstrap reads.
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

## Static ingress bootstrap credentials

OpenTofu creates `sgfdevs-k3s-bootstrap-reader` and one inline policy.
The nonsecret `k3s_bootstrap_reader_user_name` output identifies the user for
operator key issuance. Its only permission is `ssm:GetParameter` on these
exact parameters in this AWS account, in `us-east-2`:

- `/vm-workloads/sgfdevs/infra-vm-workloads/cloudflare-sgfdevs-tunnel-token`
- `/vm-workloads/sgfdevs/infra-vm-workloads/cloudflare-opensgf-tunnel-token`
- `/vm-workloads/sgfdevs/infra-vm-workloads/crowdsec-traefik-bouncer-key`

There is no wildcard, parameter listing, write access, Headscale access or
role assumption. This user cannot read its own credential parameters.
Existing Kubernetes OIDC runtime roles, trust and workflow workload-prefix
SSM permissions are unchanged. Ansible uses that existing workflow access to
retrieve the bootstrap credentials, not the bootstrap user.

The ingress parameters currently use the default SSM encryption key.
No customer-managed KMS permissions are added. Confirm that the parameters
and the credential parameters below use the default `alias/aws/ssm` key.
If their encryption changes, stop and review exact decrypt and key-policy
requirements separately rather than broadening this policy.

### Issue credentials outside OpenTofu

After applying the IAM user and policy in the verified account, an authorized
operator creates an access key for the output user name outside OpenTofu.
The operator needs IAM access-key administration for that user and SSM write
access to these two paths in the same account and `us-east-2`:

- `/vm-workloads/sgfdevs/infra-vm-workloads/bootstrap-aws/access-key-id`
- `/vm-workloads/sgfdevs/infra-vm-workloads/bootstrap-aws/secret-access-key`

Store both values as `SecureString` parameters outside OpenTofu. Do not add
access-key resources, credential parameter resources or credential data
sources to Terraform. Neither credential belongs in state, Git or outputs.
Use a secure operator process that does not print values or put them in shell
history, command arguments, CI logs, plan files or temporary plaintext files.
The secret access key is available only at issuance. If it is lost before
secure storage, revoke that uninstalled key and issue another.

Ansible reads these paths with explicit `us-east-2` and decryption, then uses
the existing create-only helper to seed only
`kube-system/bootstrap-aws-credentials`, with keys `access-key-id` and
`secret-access-key`. A complete existing Secret is untouched; an incomplete
Secret fails and requires operator repair. A normal Ansible rerun does not
rotate or repair credentials.

The namespace-local `kube-system/bootstrap-aws-ssm` SecretStore uses these
Secret keys directly with ParameterStore in `us-east-2`. It stays statically
authenticated after bootstrap. Do not send these credentials through ESO,
the normal secret cache or a JWT store. All other stores remain JWT
authenticated.

### Apply and migration checkpoints

1. Review a plan in the verified local account and apply AWS core first.
   For this redesign, expect only the dedicated user, inline policy and
   nonsecret output relative to main. If the earlier bootstrap PR was applied,
   expect removal of its obsolete bootstrap-only IAM additions too. Confirm
   they have no active callers before removal. Do not remove existing runtime
   permissions, OIDC roles, trust, state backend or Identity Center resources.
   LZ and SGF provision independently; there is no new cross-account input.
2. Issue and securely store the credential pair above. Confirm both paths
   exist and the key is active without exposing values. Confirm the existing
   VM workflow can retrieve them. For the manual main Ansible workflow,
   use `initialize-terraform=true` to configure its AWS credentials.
3. Follow the matching Kubernetes prepare/transfer/cleanup migration docs.
   Apply prepare protections before transferring resource ownership. Deploy
   the redesigned VM and Kubernetes prepare revisions together before a cold
   bootstrap. A healthy legacy rerun may still work; old main is not a cold
   recovery path.
4. Ansible prepares AWS runtime and admission, seeds the credential Secret,
   installs Argo/operators and applies the platform. Check the early
   `bootstrap-ingress-config` Application at wave -4, its static store and
   Cloudflare/bouncer ExternalSecrets before foundation. Preserve existing
   target Secret identities and UIDs during ownership transfer.
5. Check foundation CA/certificate prerequisites at wave -3, the matching
   public issuer at -2, then JWT AWS configuration/store conditions at -1 and
   apps. Public OIDC and ACME checks must use public DNS. Do not wait on
   Tailscale connectivity, LZ private DNS or whole Traefik pod readiness before
   the issuer. Missing Tailscale credentials do not mean the tailnet is healthy.
6. Transfer ownership only after the prepare checkpoint is healthy. Restore
   pruning in cleanup only after the moved resources and unchanged target
   Secret UIDs are verified. Keep SGF SeaweedFS missing-only seeds separate.

Stop at a failed checkpoint. Retry failed IAM or SSM provisioning before
running dependent bootstrap. If only one credential parameter was written,
finish or restore a matching pair before running Ansible. A complete cluster
Secret remains authoritative until an explicit operator rotation; changing
SSM alone will not update it. Repair incomplete cluster credentials securely,
without deleting ingress target Secrets or removing migration protections.
If ingress or issuer reconciliation fails, keep the prepare protections and
diagnose that stage before transfer/cleanup. Do not switch the store back to
JWT or widen IAM to get past a bootstrap failure.

### Rotate credentials outside OpenTofu

Keep the current key active while an operator issues a second key. Store the
new matching pair in the two SSM parameters using the same protected process,
then securely update both keys of the existing
`kube-system/bootstrap-aws-credentials` Secret in place. Preserve its UID.
Do not delete it or rely on Ansible's create-only helper to replace it.
Pause bootstrap runs while updating the pair so none can read mixed versions.

Verify the static SecretStore is Ready and each ingress ExternalSecret
successfully refreshes with the new key, without inspecting secret values.
Readiness left over from the previous key is not sufficient. Verify public
ingress and the issuer checkpoint before deactivating the old key, then
confirm reconciliation again before deleting that key. IAM permits only two
keys per user; retire a stale unused key deliberately if both slots are full.

If rotation fails, keep the old key active and restore its matching pair in
SSM and the cluster Secret before retrying. Do not revoke the last working
key. If the old key was deactivated but not deleted, reactivate it for that
recovery. If no usable key remains, issue a replacement and repair both stores
out of band before rerunning bootstrap.

## Operating constraints
- Apply this repo before dependent stacks that use the shared backend and IAM role outputs.
- SGF K3s workload roles must use the core-owned permissions boundary under `/sgfdevs-k3s/`.
- Applies are manual/local; CI runs validation only.
