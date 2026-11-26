resource "aws_cloudformation_stack_set" "this" {
  count = var.type == "stackset" ? 1 : 0

  name             = local.stackset_name
  permission_model = var.permission_model
  template_url     = var.stackset_template_url
  # call_as is for SERVICE_MANAGED only; a self-managed StackSet is always its
  # caller's own
  call_as                 = local.self_managed ? "SELF" : var.call_as
  administration_role_arn = local.self_managed ? var.administration_role_arn : null
  execution_role_name     = local.self_managed ? var.execution_role_name : null

  dynamic "auto_deployment" {
    for_each = !local.self_managed && length(var.organizational_unit_ids) > 0 ? [1] : []
    content {
      enabled                          = var.auto_deployment
      retain_stacks_on_account_removal = false
    }
  }

  # Every template parameter is sent, defaults included: AWS stores a default
  # for any parameter left out, and the next plan would show it as a change
  parameters = {
    RolePrefix                = var.role_prefix
    UniqueSuffix              = random_id.suffix.hex
    ExternalId                = var.hush_org_id
    CodeArtifactReadonly      = var.codeartifact_readonly ? "true" : "false"
    ECRReadonly               = var.ecr_readonly ? "true" : "false"
    SecretsManagerReadonly    = var.secrets_manager_readonly ? "true" : "false"
    SSMParameterStoreReadonly = var.ssm_parameter_store_readonly ? "true" : "false"
    KMSReadonly               = var.kms_readonly ? "true" : "false"
    KMSDecrypt                = var.kms_decrypt ? "true" : "false"
    S3TFStateReadOnly         = var.s3_tf_state_readonly ? "true" : "false"
    S3TFStateBucketARNs       = join(",", coalesce(var.s3_tf_state_bucket_arns, ["*"]))
    S3TFStateBucketTags       = length(var.s3_tf_state_bucket_tags) > 0 ? jsonencode(var.s3_tf_state_bucket_tags) : ""
    S3TFStateObjectARNs       = join(",", coalesce(var.s3_tf_state_object_arns, []))
    SecurityAudit             = var.security_audit ? "true" : "false"
    SendEvents                = var.send_events ? "true" : "false"
    AgentDiscoveryReadonly    = local.agent_discovery ? "true" : "false"
    McpDiscoveryReadonly      = local.mcp_discovery ? "true" : "false"
    AgentActivityReadonly     = local.agent_activity ? "true" : "false"
    AllowedRegions            = join(",", coalesce(var.allowed_regions, []))
    # deprecated in the template; the toggles above already fold them in
    BedrockAgentsReadonly          = ""
    BedrockAgentCoreAgentsReadonly = ""
    BedrockAgentCoreReadonly       = ""
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]

  lifecycle {
    ignore_changes = [administration_role_arn]

    precondition {
      condition     = !local.self_managed || (length(var.account_ids) > 0 && length(var.organizational_unit_ids) == 0)
      error_message = "A SELF_MANAGED StackSet deploys to account_ids only; organizational_unit_ids need SERVICE_MANAGED."
    }

    # the module creates the calling account's role itself (single.tf), so a
    # stack there would collide with it on the role name
    precondition {
      condition     = !local.self_managed || !contains(var.account_ids, data.aws_caller_identity.current.account_id)
      error_message = "account_ids must not include the calling account: the module creates its role directly."
    }
  }
}

resource "aws_cloudformation_stack_set_instance" "this" {
  count = var.type == "stackset" && !local.self_managed ? 1 : 0

  stack_set_name            = aws_cloudformation_stack_set.this[0].name
  stack_set_instance_region = var.stackset_region
  call_as                   = var.call_as

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

# A self-managed StackSet takes no deployment_targets, only one account per
# instance
resource "aws_cloudformation_stack_set_instance" "self_managed" {
  for_each = var.type == "stackset" && local.self_managed ? toset(var.account_ids) : toset([])

  stack_set_name            = aws_cloudformation_stack_set.this[0].name
  stack_set_instance_region = var.stackset_region
  account_id                = each.value

  operation_preferences {
    max_concurrent_percentage = 100
    failure_tolerance_count   = 0
    region_concurrency_type   = "SEQUENTIAL"
  }
}
