module "hush_security" {
  source = "../../"

  hush_org_id              = var.hush_org_id
  hush_account_id          = "116981795030"
  secrets_manager_readonly = false
  s3_tf_state_bucket_arns  = ["arn:aws:s3:::hushsecurity-dev-tf-state"]

  allowed_regions = ["eu-central-1"]
}
