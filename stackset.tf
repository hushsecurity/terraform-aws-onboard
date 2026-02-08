resource "aws_cloudformation_stack_set" "this" {
  count = var.type == "stackset" ? 1 : 0

  name             = "hush-security-${random_id.suffix.hex}"
  permission_model = "SERVICE_MANAGED"
  template_url     = var.stackset_template_url
  call_as          = var.call_as

  dynamic "auto_deployment" {
    for_each = length(var.organizational_unit_ids) > 0 ? [1] : []
    content {
      enabled                          = var.auto_deployment
      retain_stacks_on_account_removal = false
    }
  }

  parameters = {
    UniqueSuffix              = random_id.suffix.hex
    ExternalId                = var.hush_org_id
    CodeArtifactReadonly      = var.codeartifact_readonly ? "true" : "false"
    ECRReadonly               = var.ecr_readonly ? "true" : "false"
    SecretsManagerReadonly    = var.secrets_manager_readonly ? "true" : "false"
    SSMParameterStoreReadonly = var.ssm_parameter_store_readonly ? "true" : "false"
    KMSReadonly               = var.kms_readonly ? "true" : "false"
    S3TFStateReadOnly         = var.s3_tf_state_readonly ? "true" : "false"
    S3TFStateBucketARNs       = join(",", coalesce(var.s3_tf_state_bucket_arns, ["*"]))
    S3TFStateBucketTags       = length(var.s3_tf_state_bucket_tags) > 0 ? jsonencode(var.s3_tf_state_bucket_tags) : ""
    S3TFStateObjectARNs       = join(",", coalesce(var.s3_tf_state_object_arns, []))
    SecurityAudit             = var.security_audit ? "true" : "false"
    SendEvents                = var.send_events ? "true" : "false"
    AllowedRegions            = join(",", coalesce(var.allowed_regions, []))
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]

  lifecycle {
    ignore_changes = [administration_role_arn]
  }
}

resource "aws_cloudformation_stack_set_instance" "this" {
  count = var.type == "stackset" ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.this[0].name
  region         = "us-east-1"

  deployment_targets {
    organizational_unit_ids = length(var.organizational_unit_ids) > 0 ? var.organizational_unit_ids : null
    accounts                = length(var.account_ids) > 0 ? var.account_ids : null
  }

  lifecycle {
    precondition {
      condition     = length(var.organizational_unit_ids) > 0 || length(var.account_ids) > 0
      error_message = "Either organizational_unit_ids or account_ids must be provided for stackset deployment."
    }
  }

  operation_preferences {
    max_concurrent_percentage = 100
    failure_tolerance_count   = 0
    region_concurrency_type   = "SEQUENTIAL"
  }
}
