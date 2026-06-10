###############################################################################
# Outputs – MOI Training Academy Bootstrap
###############################################################################

output "folder_moi_training_id" {
  description = "Resource name of the MOI Training parent folder"
  value       = google_folder.moi_training.name
}

output "folder_resources_id" {
  description = "Resource name of the Resources sub-folder"
  value       = google_folder.resources.name
}

output "folder_students_id" {
  description = "Resource name of the Students sub-folder"
  value       = google_folder.students.name
}

output "resources_project_id" {
  description = "Project ID of the newly created Resources project"
  value       = google_project.resources.project_id
}

output "resources_project_number" {
  description = "Project number of the Resources project"
  value       = google_project.resources.number
}

output "tf_configs_bucket" {
  description = "GCS bucket for Terraform lab modules (referenced by Service Catalog)"
  value       = google_storage_bucket.tf_configs.name
}

output "lab_artifacts_bucket" {
  description = "GCS bucket for lab artifacts"
  value       = google_storage_bucket.lab_artifacts.name
}

output "enabled_apis" {
  description = "List of APIs enabled in the Resources project"
  value       = keys(google_project_service.apis)
}

output "hub_project_id" {
  description = "Project ID of the Hub (Shared VPC host) project"
  value       = google_project.hub.project_id
}

output "hub_project_number" {
  description = "Project number of the Hub project"
  value       = google_project.hub.number
}

output "hub_vpc_self_link" {
  description = "Self link of the Hub Shared VPC — student service projects attach to this"
  value       = google_compute_network.hub_vpc.self_link
}

output "hub_subnet_self_link" {
  description = "Self link of the Hub shared subnet used by student workloads"
  value       = google_compute_subnetwork.hub_subnet.self_link
}

output "hub_nat_name" {
  description = "Name of the Cloud NAT providing egress for student projects"
  value       = google_compute_router_nat.hub_nat.name
}

output "hub_vpc_compute_self_link" {
  description = "Self link of the second Hub VPC (me-central1) — compute-instance labs attach here"
  value       = google_compute_network.hub_vpc_compute.self_link
}

output "hub_subnet_compute_self_link" {
  description = "Self link of the me-central1 shared subnet used by student compute instances"
  value       = google_compute_subnetwork.hub_subnet_compute.self_link
}

output "hub_nat_compute_name" {
  description = "Name of the Cloud NAT providing egress for the me-central1 compute VPC"
  value       = google_compute_router_nat.hub_nat_compute.name
}
