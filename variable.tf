variable "project_id" {
  type        = string
  description = "The GCP Project ID."
  default     = "tidy-interface-406606"
}

variable "region" {
  type        = string
  description = "GCP Region for regional resources."
  default     = "us-central1"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name."
  default     = "gke-prod-cluster"
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace for the workload."
  default     = "production"
}

variable "ksa_name" {
  type        = string
  description = "Kubernetes Service Account name."
  default     = "storage-reader-ksa"
}

variable "alert_notification_email" {
  type        = string
  description = "Email address for incident alerts."
  default     = "sre-team@example.com"
}