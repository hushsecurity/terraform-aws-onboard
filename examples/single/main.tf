module "hush_security" {
  source  = "hushsecurity/onboard/aws"
  version = "~> 1.0" # Find the laest version at https://registry.terraform.io/modules/hushsecurity/onboard/aws/latest

  hush_org_id = var.hush_org_id
}
