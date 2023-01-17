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
  depends_on = [
    google_cloud_run_service_iam_policy.noauth
  ]
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
depends_on = [
    google_sql_database.database
  ]
}

resource "google_sql_user" "root" {
  name     = local.user
  instance = local.dbinstance	
  password = local.password
  depends_on = [
    google_sql_database.database
  ]
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
    depends_on = [
    google_sql_database.database
  ]
}

resource "google_secret_manager_secret_version" "secret-version-basic" {
  secret = google_secret_manager_secret.secret-basic.id
  secret_data = local.password
  depends_on = [
    google_sql_database.database
  ]
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
  filename = "./tmpresources.json"
  depends_on = [
    google_sql_database.database
  ]
}


resource "null_resource" "createschemas" {
  provisioner "local-exec" {
    command = "./mysql-setup.sh"
  }
  depends_on = [
    google_sql_database.database
  ]
}

resource "null_resource" "createconnector" {
  provisioner "local-exec" {
    command = <<EOF
    curl -L https://raw.githubusercontent.com/srinandan/integrationcli/master/downloadLatest.sh | sh - &&
    sleep 5 &&
    export PATH=$PATH:$HOME/.integrationcli/bin &&
    sleep 2 &&
    export token=$(gcloud auth application-default print-access-token) && 
    sleep 2 &&
    integrationcli token cache -t $token &&
    sleep 2 &&
    integrationcli prefs set --reg ${local.location} --proj ${local.project} &&
    sleep 2 &&
    integrationcli connectors create -n ${local.connectorname} -f ./tmpconnector.json &&
    sleep 2
    EOF
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
  filename = "./tmpintegration.json"
}
resource "null_resource" "createintegration" {
  provisioner "local-exec" {
    command = format("%s%s%s", "integrationcli integrations create -n ", local.integration, " -f ./tmpintegration.json")
  }

 depends_on = [
    null_resource.createconnector
  ]
}