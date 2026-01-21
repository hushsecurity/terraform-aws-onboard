variable "hush_org_id" {
  description = "Hush Security organization ID."
  type        = string
}

variable "organizational_unit_ids" {
  description = "List of AWS Organizations OU IDs to deploy the StackSet to."
  type        = list(string)
}
