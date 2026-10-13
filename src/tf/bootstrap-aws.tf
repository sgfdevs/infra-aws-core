# Keys and their SSM credential parameters are provisioned outside OpenTofu.
resource "aws_iam_user" "k3s_bootstrap_reader" {
  name = "sgfdevs-k3s-bootstrap-reader"

  tags = {
    ManagedBy  = "OpenTofu"
    Repository = "sgfdevs/infra-aws-core"
  }
}

resource "aws_iam_user_policy" "k3s_bootstrap_reader" {
  name = "ReadK3sBootstrapIngressParameters"
  user = aws_iam_user.k3s_bootstrap_reader.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadBootstrapIngressParameters"
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = [
          "arn:aws:ssm:us-east-2:${data.aws_caller_identity.current.account_id}:parameter/vm-workloads/sgfdevs/infra-vm-workloads/cloudflare-sgfdevs-tunnel-token",
          "arn:aws:ssm:us-east-2:${data.aws_caller_identity.current.account_id}:parameter/vm-workloads/sgfdevs/infra-vm-workloads/cloudflare-opensgf-tunnel-token",
          "arn:aws:ssm:us-east-2:${data.aws_caller_identity.current.account_id}:parameter/vm-workloads/sgfdevs/infra-vm-workloads/crowdsec-traefik-bouncer-key",
        ]
      },
    ]
  })
}
