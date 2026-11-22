# Hush Security AWS Onboarding Terraform Module

Terraform module to integrate your AWS account(s) with Hush Security.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 6.0, < 7.0 |

## Deployment Modes

This module supports two deployment modes:

- **Single Account** (default): Creates an IAM role directly via Terraform for a single AWS account.
- **StackSet**: Creates a CloudFormation StackSet for multi-account deployment across AWS Organizations.

## Usage

### Single Account (Default)

```hcl
module "hush_security" {
  source  = "hushsecurity/onboard/aws"
  version = "~> 2.0"

  hush_org_id = "org-us1234567890abc"  # Your organization's unique ID, shown as the External ID in the Hush onboarding flow
}
```

### Single Account - Customized

```hcl
module "hush_security" {
  source  = "hushsecurity/onboard/aws"
  version = "~> 2.0"

  hush_org_id = "org-us1234567890abc"  # Your organization's unique ID, shown as the External ID in the Hush onboarding flow

  # Disable features you don't need
  codeartifact_readonly = false

  # Restrict to specific regions
  allowed_regions = ["us-east-1", "us-west-2", "eu-west-1"]

  # Restrict S3 TF state access to specific buckets
  s3_tf_state_bucket_arns = [
    "arn:aws:s3:::mycompany-terraform-state"
  ]

  # Restrict S3 TF state access to buckets by tags (requires ABAC enabled on the buckets)
  s3_tf_state_bucket_tags = {
    "hush" = "true"
  }

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
  source  = "hushsecurity/onboard/aws"
  version = "~> 2.0"

  type        = "stackset"
  hush_org_id = "org-us1234567890abc"  # Your organization's unique ID, shown as the External ID in the Hush onboarding flow

  organizational_unit_ids = ["ou-xxxx-xxxxxxxx"]
}
```

**Deploy to specific accounts:**
```hcl
module "hush_security" {
  source  = "hushsecurity/onboard/aws"
  version = "~> 2.0"

  type        = "stackset"
  hush_org_id = "org-us1234567890abc"  # Your organization's unique ID, shown as the External ID in the Hush onboarding flow

  account_ids = ["111111111111", "222222222222"]
}
```

**Note:** StackSet mode requires delegated administrator access for CloudFormation StackSets, or management account access.

## Inputs

### Common Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| type | Deployment type: `single` or `stackset`. | `string` | `"single"` | no |
| hush_org_id | Unique identifier for your organization, shown as the External ID in the Hush Security onboarding flow. | `string` | n/a | yes |
| role_prefix | Prefix of the IAM role's and StackSet's names. See [Role naming](#role-naming). | `string` | `"hush-security-"` | no |
| codeartifact_readonly | Enable CodeArtifact read-only access. | `bool` | `true` | no |
| ecr_readonly | Enable ECR read-only access. | `bool` | `true` | no |
| secrets_manager_readonly | Enable Secrets Manager read-only access. | `bool` | `true` | no |
| ssm_parameter_store_readonly | Enable SSM Parameter Store read-only access. | `bool` | `true` | no |
| kms_readonly | Enable KMS read-only access. | `bool` | `true` | no |
| kms_decrypt | Allow `kms:Decrypt` on the account's keys, for secrets under customer-managed keys. | `bool` | `true` | no |
| s3_tf_state_readonly | Enable S3 read-only access for Terraform state files. | `bool` | `true` | no |
| s3_tf_state_bucket_arns | S3 bucket ARNs for Terraform state. | `list(string)` | `null` | no |
| s3_tf_state_bucket_tags | S3 bucket tags for Terraform state. <br>Requires [Bucket ABAC](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security_iam_service-with-iam.html#security_iam_service-with-iam-tags) to be enabled. | `map(string)` | `{}` | no |
| s3_tf_state_object_arns | Specific S3 object ARNs for Terraform state files. | `list(string)` | `null` | no |
| security_audit | Attach AWS SecurityAudit managed policy. | `bool` | `true` | no |
| send_events | Whether to send AWS resource change events via EventBridge. | `bool` | `true` | no |
| agent_discovery_readonly | Enable Bedrock Agents and AgentCore agent discovery. | `bool` | `true` | no |
| mcp_discovery_readonly | Enable discovery of the AgentCore gateways exposed as MCP servers. | `bool` | `true` | no |
| agent_activity_readonly | Enable the agent activity feed (CloudWatch Logs reads on the AgentCore span and gateway log groups). Null follows `agent_discovery_readonly`. | `bool` | `null` | no |
| allowed_regions | Restrict access to specific AWS regions. Null allows all. | `list(string)` | `null` | no |
| tags | Additional tags. | `map(string)` | `{}` | no |

### StackSet Mode Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organizational_unit_ids | AWS Organizations OU IDs to deploy to. | `list(string)` | `[]` | * |
| account_ids | AWS account IDs to deploy to. | `list(string)` | `[]` | * |
| stackset_template_url | S3 URL of the CloudFormation template. | `string` | (hosted URL) | no |
| stackset_region | Region to deploy the StackSet instances to. | `string` | `"us-east-1"` | no |
| auto_deployment | Auto-deploy to new accounts added to target OUs. | `bool` | `true` | no |

\* At least one of `organizational_unit_ids` or `account_ids` must be provided for stackset mode.

## Outputs

### Single Account Mode

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role created for Hush Security |
| role_name | Name of the IAM role |
| role_prefix | Prefix of the IAM role's name |
| unique_suffix | Unique suffix used for role naming |

### StackSet Mode

| Name | Description |
|------|-------------|
| stackset_arn | ARN of the CloudFormation StackSet |
| stackset_name | Name of the CloudFormation StackSet |
| role_prefix | Prefix of the IAM role's name (needed for registration) |
| unique_suffix | Unique suffix for role naming (needed for registration) |

## Integration

### Single Account

After deploying:

1. Copy the `role_arn` output
2. In the Hush Security dashboard, go to Integrations > AWS
3. Create a new integration using the role ARN

### StackSet Mode

After deploying:

1. Copy the `stackset_arn`, `role_prefix` and `unique_suffix` outputs
2. In the Hush Security dashboard, go to Integrations > AWS
3. Create a new integration using the StackSet ARN, role prefix and unique suffix

Hush Security will automatically discover all accounts where the StackSet has deployed roles.

## Upgrading

From 2.3.0, agent discovery, MCP discovery and agent activity default to on,
as they do in the CloudFormation template. If you never set these toggles,
your next apply adds their read-only statements to the role (in place, and in
stackset mode as a StackSet update to every account). Agent activity reads the
AgentCore span and gateway log groups, which hold agent prompts, tool
arguments and tool results. To keep any of them off, set it to `false`; with
agent discovery off, agent activity stays off unless you set it.

## Role naming

The role in every account is named `<role_prefix><unique_suffix>`, e.g.
`hush-security-0123456789abcdef` by default, or `acme-hush-0123456789abcdef`
with `role_prefix = "acme-hush-"`. The random suffix keeps several onboardings
in one account apart. In stackset mode the StackSet is named the same way, with
any character other than a letter, digit or hyphen in the prefix replaced by a
hyphen, and Hush Security finds each account's role by its name. The prefix is
therefore fixed once the integration is created: changing it creates new roles,
and the integration has to be created again with the new prefix.

Beyond its name, Hush Security relies on the role as the module creates it:

- the trust policy, which lets Hush Security's account assume the role with
  your `hush_org_id` as the External ID, and lets EventBridge assume it to send
  events
- the inline policy's statement `Sid`s, which tell Hush Security which features
  the role grants
- the SecurityAudit managed policy, which also lets Hush Security read the
  inline policy
- the `Version` and `CreatedBy` tags

Changing any of these can turn features off or put the integration in error.

## License

Copyright Hush Security. All rights reserved.
