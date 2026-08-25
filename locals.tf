locals {
  version = "1.7"

  # The current name wins when it was supplied; a superseded one fills in for
  # a consumer who has not moved yet, so their setting - an opt-out especially
  # - survives the rename. All default null so "not supplied" is tellable from
  # "supplied as false", which is the whole point: coalescing the superseded
  # name first would override an explicit new-name false with a stale true.
  agent_discovery = coalesce(
    var.agent_discovery_readonly,
    var.bedrock_agents_readonly,
    var.bedrock_agentcore_agents_readonly,
    false,
  )
  mcp_discovery = coalesce(
    var.mcp_discovery_readonly,
    var.bedrock_agentcore_readonly,
    false,
  )

  hush_account_arn = "arn:aws:iam::${var.hush_account_id}:root"
  role_name        = "hush-security-${random_id.suffix.hex}"

  common_tags = merge(
    {
      Name                = local.role_name
      Version             = local.version
      CreatedBy           = "Terraform"
      S3TFStateBucketTags = length(var.s3_tf_state_bucket_tags) > 0 ? base64encode(jsonencode(var.s3_tf_state_bucket_tags)) : ""
    },
    var.tags
  )
}
