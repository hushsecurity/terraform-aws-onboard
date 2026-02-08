locals {
  version = "1.3"

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
