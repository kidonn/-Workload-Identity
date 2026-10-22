
# ==============================================================================
# 2. WORKLOAD IDENTITY, STORAGE BUCKET & LEAST-PRIVILEGE IAM
# ==============================================================================

# Target GCS bucket for workload access
resource "google_storage_bucket" "app_data" {
  name                        = "${var.project_id}-workload-data"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Google Service Account (GSA) dedicated to the application
resource "google_service_account" "workload_gsa" {
  account_id   = "storage-reader-gsa"
  display_name = "Workload Identity GSA for Bucket Reader"
}

# Least-privilege IAM: Storage Object Viewer restricted solely to the target bucket
resource "google_storage_bucket_iam_member" "gcs_reader_binding" {
  bucket = google_storage_bucket.app_data.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.workload_gsa.email}"
}

# Kubernetes Namespace
resource "kubernetes_namespace" "app_ns" {
  metadata {
    name = var.k8s_namespace
  }
}

# Kubernetes Service Account (KSA) with GSA annotation
resource "kubernetes_service_account" "app_ksa" {
  metadata {
    name      = var.ksa_name
    namespace = kubernetes_namespace.app_ns.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.workload_gsa.email
    }
  }
}

# Workload Identity binding: Allow the KSA to act as the GSA
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.workload_gsa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.ksa_name}]"

  depends_on = [kubernetes_service_account.app_ksa]
}
