###############################################################################
# Variables – MOI Training Academy Bootstrap
###############################################################################

variable "org_id" {
  description = "GCP Organization ID (numeric, e.g. 123456789012)"
  type        = string
}

variable "billing_account_id" {
  description = "GCP Billing Account ID (format XXXXXX-XXXXXX-XXXXXX)"
  type        = string
  default     = "0123B0-2567C0-0A624B"
}

variable "bootstrap_project_id" {
  description = "Existing project you are running Terraform from (for billing_project in provider)"
  type        = string
}

variable "resources_project_prefix" {
  description = "Prefix for the Shared Services project ID; a random suffix is appended so the full ID is globally unique (e.g. moi-resources-a1b2)"
  type        = string
  default     = "moi-resources"
}

variable "region" {
  description = "Primary GCP region for all resources"
  type        = string
  default     = "me-central1"
}

variable "environment" {
  description = "Environment label"
  type        = string
  default     = "prod"
}

variable "hub_project_id" {
  description = "Desired project ID for the Hub project (Shared VPC host, lives in the Students folder; must be globally unique in GCP)"
  type        = string
}

variable "hub_region" {
  description = "Region for the Hub VPC subnet, Cloud Router and Cloud NAT (must match where student labs run)"
  type        = string
  default     = "europe-west1"
}

variable "hub_subnet_cidr" {
  description = "Primary IP CIDR range for the Hub shared subnet"
  type        = string
  default     = "10.10.10.0/24"
}

variable "hub_compute_region" {
  description = "Region for the second Hub VPC + subnet (backs the student compute-instance labs; separate from the Workbench VPC)"
  type        = string
  default     = "me-central1"
}

variable "hub_compute_subnet_cidr" {
  description = "Primary IP CIDR range for the me-central1 compute subnet (must not overlap hub_subnet_cidr)"
  type        = string
  default     = "10.10.20.0/24"
}
