variable "type" {
  description = "Deployment type: 'single' for one account, 'stackset' for multi-account via CloudFormation StackSet."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "stackset"], var.type)
    error_message = "type must be 'single' or 'stackset'."
  }
}

variable "hush_org_id" {
  description = "Your Hush Security organization ID, used as the external ID for cross-account role assumption."
  type        = string

  validation {
    condition     = can(regex("^org-[a-zA-Z0-9]+$", var.hush_org_id)) && length(var.hush_org_id) >= 8 && length(var.hush_org_id) <= 30
    error_message = "hush_org_id must be a valid Hush organization ID (e.g., org-us1234567890abc)."
  }
}

variable "hush_account_id" {
  description = "Hush Security AWS account ID to trust for cross-account access."
  type        = string
  default     = "976193264428"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.hush_account_id))
    error_message = "hush_account_id must be a 12-digit AWS account ID."
  }
}

variable "codeartifact_readonly" {
  description = "Enable CodeArtifact read-only access."
  type        = bool
  default     = true
}

variable "ecr_readonly" {
  description = "Enable ECR read-only access for container image scanning."
  type        = bool
  default     = true
}

variable "secrets_manager_readonly" {
  description = "Enable Secrets Manager read-only access."
  type        = bool
  default     = true
}

variable "ssm_parameter_store_readonly" {
  description = "Enable SSM Parameter Store read-only access."
  type        = bool
  default     = true
}

variable "kms_readonly" {
  description = "Enable KMS read-only access."
  type        = bool
  default     = true
}

variable "s3_tf_state_readonly" {
  description = "Enable S3 read-only access for Terraform state file scanning."
  type        = bool
  default     = true
}

variable "s3_tf_state_bucket_arns" {
  description = "List of S3 bucket ARNs containing Terraform state files. Null allows all buckets."
  type        = list(string)
  default     = null
}

variable "s3_tf_state_object_arns" {
  description = "List of specific S3 object ARNs for Terraform state files. Null uses default pattern (*.tfstate)."
  type        = list(string)
  default     = null
}

variable "security_audit" {
  description = "Attach the AWS SecurityAudit managed policy for IAM enumeration."
  type        = bool
  default     = true
}

variable "send_events" {
  description = "Whether to send AWS resource change events to Hush via EventBridge."
  type        = bool
  default     = true
}

variable "allowed_regions" {
  description = "List of AWS regions to restrict access to. Null allows all regions."
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to created resources."
  type        = map(string)
  default     = {}
}

# StackSet mode variables

variable "stackset_template_url" {
  description = "S3 URL of the CloudFormation template for StackSet deployment."
  type        = string
  default     = "https://hush-security-public.s3.eu-west-1.amazonaws.com/cf_templates/aws_onboarding.yaml"
}

variable "organizational_unit_ids" {
  description = "List of AWS Organizations OU IDs to deploy the StackSet to."
  type        = list(string)
  default     = []
}

variable "account_ids" {
  description = "List of AWS account IDs to deploy the StackSet to."
  type        = list(string)
  default     = []
}

variable "auto_deployment" {
  description = "Automatically deploy to new accounts added to the target OUs."
  type        = bool
  default     = true
}

variable "call_as" {
  description = "Whether to run as the management account (SELF) or delegated administrator (DELEGATED_ADMIN)."
  type        = string
  default     = "DELEGATED_ADMIN"
}
