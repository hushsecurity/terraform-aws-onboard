# Hush Security AWS Onboarding Terraform Module

Terraform module to integrate your AWS account(s) with Hush Security.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 4.0, < 6.0 |

## Deployment Modes

This module supports two deployment modes:

- **Single Account** (default): Creates an IAM role directly via Terraform for a single AWS account.
- **StackSet**: Creates a CloudFormation StackSet for multi-account deployment across AWS Organizations.

## Usage

### Single Account (Default)

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/aws"

  hush_org_id = "org-us1234567890abc"  # From Hush Security dashboard
}
```

### Single Account - Customized

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

### Multi-Account via StackSet

For organizations with multiple AWS accounts, use StackSet mode to deploy across accounts.

**Deploy to OUs:**
```hcl
module "hush_security" {
  source = "hushsecurity/onboard/aws"

  type        = "stackset"
  hush_org_id = "org-us1234567890abc"

  organizational_unit_ids = ["ou-xxxx-xxxxxxxx"]
}
```

**Deploy to specific accounts:**
```hcl
module "hush_security" {
  source = "hushsecurity/onboard/aws"

  type        = "stackset"
  hush_org_id = "org-us1234567890abc"

  account_ids = ["111111111111", "222222222222"]
}
```

**Note:** StackSet mode requires delegated administrator access for CloudFormation StackSets, or management account access.

## Inputs

### Common Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| type | Deployment type: `single` or `stackset`. | `string` | `"single"` | no |
| hush_org_id | Your Hush Security organization ID. | `string` | n/a | yes |
| codeartifact_readonly | Enable CodeArtifact read-only access. | `bool` | `true` | no |
| ecr_readonly | Enable ECR read-only access. | `bool` | `true` | no |
| secrets_manager_readonly | Enable Secrets Manager read-only access. | `bool` | `true` | no |
| ssm_parameter_store_readonly | Enable SSM Parameter Store read-only access. | `bool` | `true` | no |
| kms_readonly | Enable KMS read-only access. | `bool` | `true` | no |
| s3_tf_state_readonly | Enable S3 read-only access for Terraform state files. | `bool` | `true` | no |
| s3_tf_state_bucket_arns | S3 bucket ARNs for Terraform state. Null allows all. | `list(string)` | `null` | no |
| s3_tf_state_object_arns | Specific S3 object ARNs for Terraform state files. | `list(string)` | `null` | no |
| security_audit | Attach AWS SecurityAudit managed policy. | `bool` | `true` | no |
| send_events | Whether to send AWS resource change events via EventBridge. | `bool` | `true` | no |
| allowed_regions | Restrict access to specific AWS regions. Null allows all. | `list(string)` | `null` | no |
| tags | Additional tags. | `map(string)` | `{}` | no |

### StackSet Mode Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organizational_unit_ids | AWS Organizations OU IDs to deploy to. | `list(string)` | `[]` | * |
| account_ids | AWS account IDs to deploy to. | `list(string)` | `[]` | * |
| stackset_template_url | S3 URL of the CloudFormation template. | `string` | (hosted URL) | no |
| auto_deployment | Auto-deploy to new accounts added to target OUs. | `bool` | `true` | no |

\* At least one of `organizational_unit_ids` or `account_ids` must be provided for stackset mode.

## Outputs

### Single Account Mode

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role created for Hush Security |
| role_name | Name of the IAM role |
| unique_suffix | Unique suffix used for role naming |

### StackSet Mode

| Name | Description |
|------|-------------|
| stackset_arn | ARN of the CloudFormation StackSet |
| stackset_name | Name of the CloudFormation StackSet |
| unique_suffix | Unique suffix for role naming (needed for registration) |

## Integration

### Single Account

After deploying:

1. Copy the `role_arn` output
2. In the Hush Security dashboard, go to Integrations > AWS
3. Create a new integration using the role ARN

### StackSet Mode

After deploying:

1. Copy the `stackset_arn` and `unique_suffix` outputs
2. In the Hush Security dashboard, go to Integrations > AWS
3. Create a new integration using the StackSet ARN and unique suffix

Hush Security will automatically discover all accounts where the StackSet has deployed roles.

## License

Copyright Hush Security. All rights reserved.
