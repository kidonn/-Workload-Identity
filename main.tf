terraform {
  required_version = ">= 1.17.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Fetch client config and cluster auth for the Kubernetes provider
data "google_client_config" "default" {}

data "google_container_cluster" "primary" {
  name     = google_container_cluster.gke.name
  location = var.region
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}
