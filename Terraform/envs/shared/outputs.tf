output "ecr_repository_url" {
  value = aws_ecr_repository.octabyte_ecr.repository_url
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "github_deploy_role_arns" {
  value = { for env, role in aws_iam_role.deploy : env => role.arn }
}
