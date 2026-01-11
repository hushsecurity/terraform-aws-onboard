output "role_arn" {
  description = "ARN of the IAM role created for Hush Security"
  value       = aws_iam_role.hush_security.arn
}

output "role_name" {
  description = "Name of the IAM role created for Hush Security"
  value       = aws_iam_role.hush_security.name
}
