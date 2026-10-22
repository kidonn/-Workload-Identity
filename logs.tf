
# ==============================================================================
# 3. OBSERVABILITY & INCIDENT ALERTING POLICIES
# ==============================================================================

# Notification Channel (Email)
resource "google_monitoring_notification_channel" "email_alerts" {
  display_name = "Incident Response Team"
  type         = "email"
  labels = {
    email_address = var.alert_notification_email
  }
}

# Alert Policy 1: Excessive Container Restarts / CrashLoopBackOff
resource "google_monitoring_alert_policy" "pod_restarts" {
  display_name = "GKE Incident - Pod Restart Count > 3 in 5m"
  combiner     = "OR"
  notification_channels = [
    google_monitoring_notification_channel.email_alerts.name
  ]

  conditions {
    displayName = "Pod container restart delta > 3 per 5 minutes"
    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND metric.type = \"kubernetes.io/container/restart_count\" AND resource.labels.namespace_name = \"${var.k8s_namespace}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 3
      duration        = "0s"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  documentation {
    content   = "Pods are crashing or restarting frequently in namespace `${var.k8s_namespace}`. Check pod status via `kubectl describe pod` and view logs for OOMKilled or panics."
    mime_type = "text/markdown"
  }
}

# Alert Policy 2: Unavailable Deployment Replicas
resource "google_monitoring_alert_policy" "unavailable_replicas" {
  display_name = "GKE Incident - Deployment Has Unavailable Replicas"
  combiner     = "OR"
  notification_channels = [
    google_monitoring_notification_channel.email_alerts.name
  ]

  conditions {
    displayName = "Unavailable replicas > 0 for 3 minutes"
    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND metric.type = \"kubernetes.io/deployment/unavailable_replicas\" AND resource.labels.namespace_name = \"${var.k8s_namespace}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "180s"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  documentation {
    content   = "One or more deployment replicas in `${var.k8s_namespace}` are unavailable. Check pending scheduling, readiness probe failures, or image pull errors."
    mime_type = "text/markdown"
  }
}

# Alert Policy 3: Workload Identity / GCS Storage 403 Permission Denials
resource "google_monitoring_alert_policy" "gcs_403_errors" {
  display_name = "GKE Incident - Cloud Storage Authorization Failures (403)"
  combiner     = "OR"
  notification_channels = [
    google_monitoring_notification_channel.email_alerts.name
  ]

  conditions {
    displayName = "GCS 403 Access Denied errors > 0 for 1m"
    condition_threshold {
      filter          = "resource.type = \"gcs_bucket\" AND metric.type = \"storage.googleapis.com/api/request_count\" AND metric.labels.response_code = \"403\" AND resource.labels.bucket_name = \"${google_storage_bucket.app_data.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  documentation {
    content   = "Cloud Storage requests are returning HTTP 403 Forbidden on bucket `${google_storage_bucket.app_data.name}`. Verify Workload Identity User IAM binding or service account annotations."
    mime_type = "text/markdown"
  }
}
