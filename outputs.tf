# IAM role outputs (created in management account for both modes)
output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

# StackSet mode outputs
output "stackset_arn" {
  description = "ARN of the CloudFormation StackSet (stackset mode only)"
  value       = var.type == "stackset" ? aws_cloudformation_stack_set.this[0].arn : null
}

output "stackset_name" {
  description = "Name of the CloudFormation StackSet (stackset mode only)"
  value       = var.type == "stackset" ? aws_cloudformation_stack_set.this[0].name : null
}

# Common output
output "unique_suffix" {
  description = "Unique suffix for role naming (needed for mixer registration in stackset mode)"
  value       = random_id.suffix.hex
}
