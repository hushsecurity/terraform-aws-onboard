variable "hush_org_id" {
  description = "Unique identifier for your organization, shown as the External ID in the Hush Security onboarding flow."
  type        = string
}

variable "organizational_unit_ids" {
  description = "List of AWS Organizations OU IDs to deploy the StackSet to."
  type        = list(string)
}
