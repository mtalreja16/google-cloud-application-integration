locals {
  location = "us-west1"
  project = "integration-demo-364406"
  projectnumber = "901962132371"
  image = "gcr.io/integration-demo-364406/reservation-app:latest"
  dbinstance="integration-demo"
  user="root"
  password="welcome!1" 
  secretid="secret-root"
  service_account_name="reservation-demo"
  dbname="catalog" # DONT CHANGE IT
  cloudrun-app="reservation-app" # DONT CHANGE IT
  connectorname="reservationdb" # DONT CHANGE IT
  integration="manage-reservation" # DONT CHANGE IT
}

provider "google" {
  project = local.project
  region  = local.location
}

variable "gcp_service_list" {
  description ="The list of apis necessary for the project"
  type = list(string)
  default = [
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "pubsub.googleapis.com",
    "connectors.googleapis.com",
    "integrations.googleapis.com"
  ]
}

resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  project = local.project
  service = each.key
}

resource "google_service_account" "integration-admin" {
  account_id   = local.service_account_name
  display_name = local.service_account_name
}

# Grant the service account the "Integration Admin" role
resource "google_project_iam_member" "member-role" {
   for_each = toset([
    "roles/cloudsql.admin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/secretmanager.secretAccessor",
    "roles/datastore.owner",
    "roles/integrations.integrationAdmin",
    "roles/secretmanager.admin"
  ])
  role = each.key
  member = format("%s%s@%s%s", "serviceAccount:", local.service_account_name, local.project, ".iam.gserviceaccount.com")
  project = local.project
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
  name         = local.cloudrun-app
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


resource "google_sql_database_instance" "integration-demo" {
  name          = local.dbinstance
  database_version = "MYSQL_8_0"
  region        = local.location
  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "database" {
name = local.dbname
instance = "${google_sql_database_instance.integration-demo.name}"
charset = "utf8"
collation = "utf8_general_ci"
}

resource "google_sql_user" "root" {
  name     = local.user
  instance = local.dbinstance	
  password = local.password
}


resource "google_secret_manager_secret" "secret-basic" {
  secret_id = local.secretid
  labels = {
    label = "sqlpassword"
  }
    replication {
    user_managed {
      replicas {
        location = local.location
      }
    }
    }
}

resource "google_secret_manager_secret_version" "secret-version-basic" {
  secret = google_secret_manager_secret.secret-basic.id
  secret_data = local.password
}

 
resource "local_file" "resource_file" {
  content  = templatefile("Integration/connector/mysql-resources.json", 
  {
    location = local.location, 
    project = local.project,
    projectnumber = local.projectnumber,
    dbinstance=local.dbinstance,
    user=local.user,
    password=local.password,
    service_account_name=local.service_account_name,
    dbname=local.dbname,
    connectorname=local.connectorname,
    secretid=local.secretid,
  
  })
  filename = "./Integration/connector/tmpresources.json"
}


resource "null_resource" "createschemas" {
  provisioner "local-exec" {
    command = "./Integration/connector/mysql-setup.sh"
  }
  depends_on = [
    local_file.resource_file
  ]
}


resource "local_file" "connector_file" {
  content  = templatefile("Integration/connector/mysql-connector.json", {
    location = local.location, 
    project = local.project,
    projectnumber = local.projectnumber,
    dbinstance=local.dbinstance,
    user=local.user,
    password=local.password,
    service_account_name=local.service_account_name,
    dbname=local.dbname,
    connectorname=local.connectorname,
    secretid=local.secretid,
  })
  filename = "./Integration/connector/tmpconnector.json"
}



resource "null_resource" "oauth_provisioner" {
  provisioner "local-exec" {
    command = "export token=$(gcloud auth print-access-token) && echo integrationcli token cache -t $token"
  }
}

resource "null_resource" "setintegrationApi" {
  provisioner "local-exec" {
    command = format("%s%s%s%s", "integrationcli prefs set -p " , local.project,  " -r " , local.location )
  }
}

resource "null_resource" "createconnectors" {
  provisioner "local-exec" {
    command = format("%s%s%s", "integrationcli connectors create -n ", local.connectorname, " -f ./Integration/connector/tmpconnector.json")
  }
}

resource "local_file" "integration_file" {
  content  = templatefile("Integration/manage-reservation.json", {
    location = local.location, 
    project = local.project,
    projectnumber = local.projectnumber,
    dbinstance=local.dbinstance,
    user=local.user,
    password=local.password,
    service_account_name=local.service_account_name,
    dbname=local.dbname,
    connectorname=local.connectorname,
    secretid=local.secretid,
    integration=local.integration
  })
  filename = "./Integration/tmpintegration.json"
}
resource "null_resource" "createconnectors" {
  provisioner "local-exec" {
    command = format("%s%s%s", "integrationcli integrations upload -n ", local.integration, " -f ./Integration/tmpintegration.json")
  }
}