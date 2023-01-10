locals {
  location = "<REGION>"
  project = "<PROJECT_ID>"
  image = "gcr.io/integration-demo-364406/reservation-app:latest"
}

provider "google" {
  version = "3.47.0"
  project = local.project
  region  = local.location
}

resource "google_service_account" "integration-admin" {
  account_id   = "reservation-demo"
  display_name = "reservation demo"
}

# Grant the service account the "Integration Admin" role
resource "google_project_iam_member" "integration-admin" {
  role = "roles/integrations.integrationAdmin"
  member = format("%s@%s%s", "serviceAccount:reservation-demo", local.project, ".iam.gserviceaccount.com")
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = local.location
  project     = local.project
  service     = google_cloud_run_service.service.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_service" "service" {
  name         = "reservation-app"
  location     = local.location
  template {
    spec {
      service_account_name = google_service_account.integration-admin.email
      containers {
        image = local.image
        env {
          name  = "project"
          value = local.project
        }
        env {
          name  = "location"
          value = local.location
        }
      }
    }
  }
}

resource "local_file" "json_file" {
  content  = templatefile("Integration/manage-reservation.json", {location = local.location, projectId = local.project})
  filename = "/manage-reservation.json"
}

