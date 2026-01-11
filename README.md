# Hush Security AWS Onboarding Terraform Module

Terraform module to integrate your AWS account with Hush Security.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 4.0, < 6.0 |

## Usage

### Basic

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/aws"

  hush_org_id = "org-us1234567890abc"  # From Hush Security dashboard
}
```

### Customized

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/aws"

  hush_org_id = "org-us1234567890abc"

  # Disable features you don't need
  codeartifact_readonly = false

  # Restrict to specific regions
  allowed_regions = ["us-east-1", "us-west-2", "eu-west-1"]

  # Restrict S3 TF state access to specific buckets
  s3_tf_state_bucket_arns = [
    "arn:aws:s3:::mycompany-terraform-state"
  ]

  tags = {
    Environment = "production"
  }
}
```

### Multi-Account

Use Terraform workspaces or `for_each` to deploy across multiple accounts:

```hcl
module "hush_security" {
  for_each = var.aws_accounts
  source   = "hushsecurity/onboard/aws"

  hush_org_id = var.hush_org_id

  providers = {
    aws = aws.accounts[each.key]
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| hush_org_id | Your Hush Security organization ID. | `string` | n/a | yes |
| codeartifact_readonly | Enable CodeArtifact read-only access. | `bool` | `true` | no |
| ecr_readonly | Enable ECR read-only access. | `bool` | `true` | no |
| secrets_manager_readonly | Enable Secrets Manager read-only access. | `bool` | `true` | no |
| ssm_parameter_store_readonly | Enable SSM Parameter Store read-only access. | `bool` | `true` | no |
| kms_readonly | Enable KMS read-only access. | `bool` | `true` | no |
| s3_tf_state_readonly | Enable S3 read-only access for Terraform state files. | `bool` | `true` | no |
| s3_tf_state_bucket_arns | S3 bucket ARNs for Terraform state. Null allows all. | `list(string)` | `null` | no |
| s3_tf_state_object_arns | Specific S3 object ARNs for Terraform state files. Null uses default pattern (*.tfstate). | `list(string)` | `null` | no |
| security_audit | Attach AWS SecurityAudit managed policy. | `bool` | `true` | no |
| send_events | Whether to send AWS resource change events via EventBridge. | `bool` | `true` | no |
| allowed_regions | Restrict access to specific AWS regions. Null allows all. | `list(string)` | `null` | no |
| tags | Additional tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role created for Hush Security |
| role_name | Name of the IAM role |

## Integration

After deploying:

1. Copy the `role_arn` output
2. In the Hush Security dashboard, go to Integrations > AWS
3. Create a new integration using the role ARN

## License

Copyright Hush Security. All rights reserved.
