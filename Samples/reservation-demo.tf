locals {
  location = "us-west1"
  project = "integration-demo-364406"
  projectnumber = "901962132371"
  image = "gcr.io/integration-demo-364406/reservation-app:latest" # DONT CHANGE IT, this is public image needed to create the cloud run app
  dbinstance="integration-demo-v2"
  user="root"
  password="welcome@1" 
  secretid="secret-root-v2"
  service_account_name="reservation-demo-v2"
  dbname="catalog"
  cloudrun-app="reservation-app-v2"
  connectorname="reservationdb-v2" 
  integration="manage-reservation-v2" 
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
  member = format("serviceAccount:%s@%s.iam.gserviceaccount.com", local.service_account_name, local.project)
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
        env {
          name  = "name"
          value = local.integration
        }
      }
    }
  }
}


resource "google_sql_database_instance" "demo" {
  name          = local.dbinstance
  database_version = "MYSQL_8_0"
  region        = local.location
  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "database" {
name = local.dbname
instance = "${google_sql_database_instance.demo.name}"
charset = "utf8"
collation = "utf8_general_ci"
depends_on = [
    google_sql_database.database
  ]
}

resource "google_sql_user" "user" {
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

#curl https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64 -o ./cloud_sql_proxy  && 

resource "null_resource" "downloadproxy" {
  provisioner "local-exec" {
    command = <<EOF
      mkdir ./cloudsql  &&
      wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy &&
      sudo chmod +x ./cloud_sql_proxy 
    EOF
  }
    depends_on = [
    google_sql_database.database
  ]
 }

resource "null_resource" "openmysql" {
  provisioner "local-exec" {
    command = <<EOF
     ./cloud_sql_proxy -dir cloudsql -instances=${local.project}:${local.location}:${local.dbinstance}=tcp:3306 & 
     sql_proxy_pid=$! && 
     sleep 10 && 
     mysql -u {local.user} --password=${local.password} --host 127.0.0.1 --database=${local.dbname} <reservationdb.sql && 
     kill $sql_proxy_pid
    EOF
  }
  depends_on = [
    null_resource.downloadproxy
   
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
    integration=local.integration
  })
    filename = format("./%s.json", local.connectorname)
}

resource "null_resource" "createconnector" {
  provisioner "local-exec" {
    command = <<EOF
      curl -L https://raw.githubusercontent.com/srinandan/integrationcli/master/downloadLatest.sh | sh - &&
      export PATH=$PATH:$HOME/.integrationcli/bin &&
      export token=$(gcloud auth application-default print-access-token) && 
      integrationcli token cache -t $token &&
      sleep 2 &&
      integrationcli prefs set --reg ${local.location} --proj ${local.project} &&
      integrationcli connectors create -n ${local.connectorname} -f ${local_file.connector_file.filename} 
    EOF
  }
}

resource "local_file" "integration_file" {
  content  = templatefile("Integration/manage-reservation.json", {
    connectorname=local.connectorname,
    location = local.location, 
    project = local.project
  })
  filename = format("./%s.json", local.integration)
}
resource "null_resource" "createintegration" {
  provisioner "local-exec" {
    command = format("%s%s%s%s", "integrationcli integrations create -n ", local.integration, " -f ", local_file.integration_file.filename)
  }

 depends_on = [
    null_resource.createconnector
  ]
}