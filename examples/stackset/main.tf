module "hush_security" {
  source  = "hushsecurity/onboard/aws"
  version = "~> 1.0" # Find the latest version at https://registry.terraform.io/modules/hushsecurity/onboard/aws/latest

  type        = "stackset"
  hush_org_id = var.hush_org_id

  organizational_unit_ids = var.organizational_unit_ids
}
