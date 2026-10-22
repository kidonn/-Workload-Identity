output "cluster_name" {
  value       = google_container_cluster.gke.name
  description = "The deployed GKE cluster name."
}

output "storage_bucket" {
  value       = google_storage_bucket.app_data.name
  description = "Target Cloud Storage bucket."
}

output "gsa_email" {
  value       = google_service_account.workload_gsa.email
  description = "Google Service Account email."
}

output "ksa_name" {
  value       = kubernetes_service_account.app_ksa.metadata[0].name
  description = "Kubernetes Service Account configured with Workload Identity."
}

output "alert_policies" {
  value = [
    google_monitoring_alert_policy.pod_restarts.name,
    google_monitoring_alert_policy.unavailable_replicas.name,
    google_monitoring_alert_policy.gcs_403_errors.name
  ]
  description = "Resource IDs of the configured incident response alert policies."
}