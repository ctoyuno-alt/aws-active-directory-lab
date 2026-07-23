resource "aws_iam_role_policy" "parameter_store" {
  name = "${var.project_name}-${var.environment}-parameter-store"

  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadDomainCredentials"
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]

        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/ad/corp.lab/*"
        ]
      }
    ]
  })
}
