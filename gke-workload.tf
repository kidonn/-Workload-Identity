
# ==============================================================================
# 1. NETWORKING & GKE CLUSTER WITH WORKLOAD IDENTITY
# ==============================================================================

resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.cluster_name}-subnet"
  ip_cidr_range            = "10.10.0.0/20"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

#tfsec:ignore:google-gke-enforce-master-auth-networks
resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Cluster-level Workload Identity setup
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Logging & Monitoring enabled for GKE system and workloads
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal RFC1918 Range"
    }
  }
}

resource "google_service_account" "gke_node_sa" {
  account_id   = "${var.cluster_name}-nodes"
  display_name = "Service Account for GKE Nodes"
}

resource "google_project_iam_member" "node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-pool"
  location   = var.region
  cluster    = google_container_cluster.gke.name
  node_count = 2

  node_config {
    machine_type    = "e2-standard-4"
    service_account = google_service_account.gke_node_sa.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Enables metadata concealment so pods only access identity via Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
