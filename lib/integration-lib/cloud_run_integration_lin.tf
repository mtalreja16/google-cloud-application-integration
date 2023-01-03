provider "google" {
  version = "3.12.0"
  project = "<PROJECT_ID>"
  region  = "<REGION>"
}

resource "google_service_account" "service-account" {
  account_id   = "service-account"
  display_name = "Service Account"
}

resource "google_cloud_run_service" "service" {
  name         = "<SERVICE_NAME>"
  location     = "<REGION>"
  template {
    spec {
      containers {
        image = "gcr.io/integration-demo-364406/integration-lib@sha256:4805c3c059cf4ec509e8442fbbbd66ded307dac6e7b87f8d79669a864a3e8c9d"
        ports {
          container_port = 8080
        }
      }
    }
  }

  auth {
    identity_binding {
      role        = "roles/run.invoker"
      members     = ["allUsers"]
      condition {
        title       = "exp-allow-unauthenticated"
        expression  = "true"
      }
    }
  }

  service_account_email = google_service_account.service-account.email
}

output "url" {
  value = google_cloud_run_service.service.status[0].url
}
