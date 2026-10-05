module "hush_security" {
  source  = "hushsecurity/onboard/aws"
  version = "~> 2.0" # Find the latest version at https://registry.terraform.io/modules/hushsecurity/onboard/aws/latest

  hush_org_id = var.hush_org_id
}
