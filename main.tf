
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }


}

provider "google" {
  region          = var.region
  billing_project = var.bootstrap_project_id
}



resource "google_folder" "moi_training" {
  display_name = "MOI Training Academy"
  parent       = "organizations/${var.org_id}"
}

resource "google_folder" "resources" {
  display_name = "Shared Resources"
  parent       = google_folder.moi_training.name
}

resource "google_folder" "students" {
  display_name = "Students"
  parent       = google_folder.moi_training.name
}


resource "random_id" "resources" {
  byte_length = 2
}

resource "google_project" "resources" {
  name            = "prj-ta-resources-01"
  project_id      = "${var.resources_project_prefix}-${random_id.resources.hex}"
  folder_id       = google_folder.resources.folder_id
  billing_account = var.billing_account_id

  labels = local.common_labels
}


locals {
  required_apis = [
    "cloudprivatecatalog.googleapis.com",

    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",

    "deploymentmanager.googleapis.com",

    "compute.googleapis.com",

    "aiplatform.googleapis.com",
    "notebooks.googleapis.com",

    "storage.googleapis.com",
    "storage-api.googleapis.com",

    "iam.googleapis.com",
    "iamcredentials.googleapis.com",

    "cloudbilling.googleapis.com",

    "logging.googleapis.com",
    "monitoring.googleapis.com",

    "cloudbuild.googleapis.com",

    "secretmanager.googleapis.com",

    "orgpolicy.googleapis.com",
  ]

  common_labels = {
    project    = "moi-training-academy"
    managed_by = "terraform"
    env        = var.environment
  }
}

resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  project                    = google_project.resources.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false

  depends_on = [google_project.resources]
}


resource "google_storage_bucket" "tf_configs" {
  project                     = google_project.resources.project_id
  name                        = "bkt-${google_project.resources.project_id}-tf-configs"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  labels     = local.common_labels
  depends_on = [google_project_service.apis]
}


resource "google_storage_bucket" "lab_artifacts" {
  project                     = google_project.resources.project_id
  name                        = "${google_project.resources.project_id}-lab-artifacts"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  labels     = local.common_labels
  depends_on = [google_project_service.apis]
}



resource "google_project" "hub" {
  name            = "prj-ta-studhub-01"
  project_id      = var.hub_project_id
  folder_id       = google_folder.students.folder_id
  billing_account = var.billing_account_id

  labels = local.common_labels
}

resource "google_project_service" "hub_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  project                    = google_project.hub.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false

  depends_on = [google_project.hub]
}


resource "google_compute_shared_vpc_host_project" "hub" {
  project    = google_project.hub.project_id
  depends_on = [google_project_service.hub_apis]
}


resource "google_compute_network" "hub_vpc" {
  name                    = "vpc-ta-svpc-wb-01"
  project                 = google_project.hub.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.hub_apis]
}

resource "google_compute_subnetwork" "hub_subnet" {
  name                     = "sn-ta-svpc-${var.hub_region}-wb-01"
  project                  = google_project.hub.project_id
  region                   = var.hub_region
  network                  = google_compute_network.hub_vpc.id
  ip_cidr_range            = var.hub_subnet_cidr
  private_ip_google_access = true
}


resource "google_compute_router" "hub_router" {
  name    = "cr-ta-${var.hub_region}-studhub-01"
  project = google_project.hub.project_id
  region  = var.hub_region
  network = google_compute_network.hub_vpc.id
}

resource "google_compute_router_nat" "hub_nat" {
  name                               = "nat-ta-${var.hub_region}-studhub-01"
  project                            = google_project.hub.project_id
  router                             = google_compute_router.hub_router.name
  region                             = var.hub_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


###############################################################################
# Hub – second VPC (me-central1) for the student Compute-Instances solution.
#   VPC 1  hub-vpc          (var.hub_region, europe-west1)  → Workbench labs
#   VPC 2  hub-vpc-compute  (var.hub_compute_region, me-central1) → compute labs
# Same host project, so service projects attach once and pick a subnet by region.
###############################################################################

resource "google_compute_network" "hub_vpc_compute" {
  name                    = "vpc-ta-svpc-ci-01"
  project                 = google_project.hub.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.hub_apis]
}

resource "google_compute_subnetwork" "hub_subnet_compute" {
  name                     = "sn-ta-spvc-${var.hub_compute_region}-ci-01"
  project                  = google_project.hub.project_id
  region                   = var.hub_compute_region
  network                  = google_compute_network.hub_vpc_compute.id
  ip_cidr_range            = var.hub_compute_subnet_cidr
  private_ip_google_access = true
}

resource "google_compute_router" "hub_router_compute" {
  name    = "cr-ta-${var.hub_compute_region}-ci-01"
  project = google_project.hub.project_id
  region  = var.hub_compute_region
  network = google_compute_network.hub_vpc_compute.id
}

resource "google_compute_router_nat" "hub_nat_compute" {
  name                               = "nat-ta-${var.hub_compute_region}-ci-01"
  project                            = google_project.hub.project_id
  router                             = google_compute_router.hub_router_compute.name
  region                             = var.hub_compute_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules live on the host project's VPC, not the service projects.
# Allow IAP-tunnelled SSH so students can reach the instances without public IPs.
resource "google_compute_firewall" "compute_iap_ssh" {
  name      = "hub-compute-allow-iap-ssh"
  project   = google_project.hub.project_id
  network   = google_compute_network.hub_vpc_compute.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP TCP-forwarding range
}

# Allow traffic between instances inside the me-central1 subnet.
resource "google_compute_firewall" "compute_internal" {
  name      = "hub-compute-allow-internal"
  project   = google_project.hub.project_id
  network   = google_compute_network.hub_vpc_compute.name
  direction = "INGRESS"

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }

  source_ranges = [var.hub_compute_subnet_cidr]
}

