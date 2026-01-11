locals {
  version = "1.3"

  hush_account_arn = "arn:aws:iam::${var.hush_account_id}:root"
  role_name        = "hush-security-${random_id.suffix.hex}"

  common_tags = merge(
    {
      Name      = local.role_name
      Version   = local.version
      CreatedBy = "Terraform"
    },
    var.tags
  )
}
