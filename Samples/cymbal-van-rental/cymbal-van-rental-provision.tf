locals {
  location             = "us-central1"      # DO NOT CHANGE
  project              = ""                 # Add ProjectId
  projectnumber        = ""                 # Add ProjectId
  dbinstance           = "reservation-demo" # DO NOT CHANGE
  user                 = "root"             # DO NOT CHANGE
  secretid             = "secret-sql"       # DO NOT CHANGE
  dbname               = "catalog"          # DO NOT CHANGE
  service_account_name = "reservation-demo" # DO NOT CHANGE
  cloudrun-app         = "reservation-app"  # DO NOT CHANGE

  mysqlconnector  = "reservationdb" # DO NOT CHANGE
  pubsubconnector = "inventory"     # DO NOT CHANGE
  gcsconnector    = "partner-feed"  # DO NOT CHANGE

  sql_proxy_pid = ""
}

provider "google" {
  project = local.project
  region  = local.location
}


resource "google_project_organization_policy" "cloudfunctions_allowedIngressSettings" {
  project = local.project
  constraint = "cloudfunctions.allowedIngressSettings"

  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "run_allowedIngress" {
  project = local.project

  constraint = "run.allowedIngress"

  list_policy {
    allow {
      all = true
    }
  }
}



resource "google_project_organization_policy" "iam_allowedPolicyMemberDomains" {
  project = local.project
  constraint = "iam.allowedPolicyMemberDomains"

  list_policy {
    allow {
      all = true
    }
  }
}



variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "pubsub.googleapis.com",
    "connectors.googleapis.com",
    "integrations.googleapis.com",
    "run.googleapis.com",
    "containerregistry.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

resource "null_resource" "reservation_app" {
  provisioner "local-exec" {
    command = <<EOF
    docker build -t gcr.io/${local.project}/reservation-app:latest ./src/frontend
    docker push gcr.io/${local.project}/reservation-app:latest
    EOF
  }
}


resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "@"
}

resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  project  = local.project
  service  = each.key
}

resource "google_service_account" "service_account" {
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
    "roles/secretmanager.admin",
    "roles/pubsub.admin",
    "roles/storage.admin",
    "roles/cloudfunctions.admin"
  ])
  role    = each.key
  member  = format("serviceAccount:%s@%s.iam.gserviceaccount.com", google_service_account.service_account.account_id, local.project)
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
  depends_on = [
    google_project_iam_member.member-role
  ]
}

resource "random_id" "rand" {
  byte_length = 4
}



resource "google_storage_bucket" "bucket_name" {
  name                        = lower("cfsource-${random_id.rand.hex}")
  uniform_bucket_level_access = true
  project                     = local.project
  location                    = local.location
}


resource "google_storage_bucket_object" "zip_file" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.bucket_name.name
  source = "./src/cf/function-source.zip"
  depends_on = [
    google_storage_bucket.bucket_name
  ]

}

resource "google_cloudfunctions_function" "pullMessages" {
  name                         = "pullMessages"
  entry_point                  = "pullMessages"
  runtime                      = "nodejs16"
  source_archive_bucket        = google_storage_bucket.bucket_name.name
  source_archive_object        = "function-source.zip"
  ingress_settings             = "ALLOW_INTERNAL_AND_GCLB"
  https_trigger_security_level = "SECURE_ALWAYS"
  timeout                      = 60
  service_account_email        = google_service_account.service_account.email

  trigger_http = true
  depends_on = [
    google_storage_bucket_object.zip_file
  ]
}


resource "google_cloud_run_service" "service" {
  name     = local.cloudrun-app
  location = local.location
  template {
    spec {
      service_account_name = google_service_account.service_account.email
      containers {
        image = "gcr.io/${local.project}/reservation-app:latest"
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
    null_resource.reservation_app
  ]
}

resource "google_pubsub_topic" "inventory" {
  name = local.pubsubconnector
  depends_on = [
    google_project_iam_member.member-role
  ]
}


resource "google_storage_bucket" "integration_bucket_name" {
  name                        = lower("inte-feed-${random_id.rand.hex}")
  uniform_bucket_level_access = true
  project                     = local.project
  location                    = local.location
}

resource "google_pubsub_subscription" "sub_inventory" {
  name                 = "sub-inventory"
  topic                = google_pubsub_topic.inventory.name
  ack_deadline_seconds = 10
  depends_on = [
    google_project_iam_member.member-role
  ]
}

resource "google_sql_database_instance" "demo" {
  name             = local.dbinstance
  database_version = "MYSQL_8_0"
  region           = local.location
  settings {
    tier = "db-f1-micro"
  }
  depends_on = [
    google_project_iam_member.member-role
  ]
}

resource "google_sql_database" "database" {
  name      = local.dbname
  instance  = google_sql_database_instance.demo.name
  charset   = "utf8"
  collation = "utf8_general_ci"
  depends_on = [
    google_sql_database.database
  ]
}

resource "google_sql_user" "user" {
  name     = local.user
  instance = local.dbinstance
  password = random_string.password.result
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
  secret      = google_secret_manager_secret.secret-basic.id
  secret_data = random_string.password.result
  depends_on = [
    google_sql_database.database
  ]
}

#curl https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64 -o ./cloud_sql_proxy  && 

resource "null_resource" "download_proxy" {
  provisioner "local-exec" {
    command = <<EOF
      mkdir ./cloudsql
      wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy &&
      sudo chmod +x ./cloud_sql_proxy 
    EOF
  }
  depends_on = [
    google_sql_database.database
  ]
}

resource "null_resource" "cloud_sql_proxy" {
  depends_on = [null_resource.download_proxy]
  provisioner "local-exec" {
     command = <<EOF
      echo ./cloud_sql_proxy -dir cloudsql -instances=${local.project}:${local.location}:${local.dbinstance}=tcp:3306 > mysqlproxy.sh
      ./cloud_sql_proxy -dir cloudsql -instances=${local.project}:${local.location}:${local.dbinstance}=tcp:3306 & sql_proxy_pid=$! && echo $! > sql_proxy_pid
     EOF
  }
}

resource "null_resource" "cloud_sql_import" {
  depends_on = [null_resource.download_proxy]
  provisioner "local-exec" {
    command = <<EOF
      sleep 10 &&
      echo mysql -u ${local.user}  --password=${random_string.password.result} --host 127.0.0.1 --database=${local.dbname} > mysqlcmd.sh &&
      mysql -u ${local.user}  --password=${random_string.password.result} --host 127.0.0.1 --database=${local.dbname} <db/reservationdb.sql &&
      kill $(cat sql_proxy_pid)
    EOF
  }
}

resource "local_file" "connector_file" {
  content = templatefile("template/mysql-connector.json", {
    location             = local.location,
    project              = local.project,
    projectnumber        = local.projectnumber,
    dbinstance           = local.dbinstance,
    user                 = local.user,
    password             = random_string.password,
    service_account_name = local.service_account_name,
    dbname               = local.dbname,
    mysqlconnector       = local.mysqlconnector,
    secretid             = local.secretid,
  })
  filename = format("./%s.json", local.mysqlconnector)
}

resource "local_file" "pubsubconnector_file" {
  content = templatefile("template/pubsub-connector.json", {
    project              = local.project,
    service_account_name = local.service_account_name,
    pubsubconnector      = local.pubsubconnector,
  })
  filename = format("./%s.json", local.pubsubconnector)
}

resource "local_file" "gcs_file" {
  content = templatefile("template/gcs-connector.json", {
    project              = local.project,
    service_account_name = local.service_account_name,
    gcsconnector         = local.gcsconnector,
  })
  filename = format("./%s.json", local.gcsconnector)
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
      integrationcli connectors create -n ${local.mysqlconnector} -f ${local_file.connector_file.filename} --wait=true
      integrationcli connectors create -n ${local.pubsubconnector} -f ${local_file.pubsubconnector_file.filename} --wait=true
      integrationcli connectors create -n ${local.gcsconnector} -f ${local_file.gcs_file.filename} --wait=true
    EOF
  }
   depends_on = [
    null_resource.cloud_sql_import
  ]
}


resource "null_resource" "createintegration" {
  provisioner "local-exec" {
    command = <<EOF
    export PATH=$PATH:$HOME/.integrationcli/bin &&
    export token=$(gcloud auth application-default print-access-token) && 
    integrationcli token cache -t $token &&
    integrationcli prefs set --reg ${local.location} --proj ${local.project} &&
    sleep 2 &&
    for file in $(find ./src/Integration/* -type f ! -name overrides.json);
      do 
        integrationcli integrations create -n $(basename "$(dirname "$file")") -o ./src/Integration/$(basename "$(dirname "$file")")/overrides.json -f $file > ./output.txt &&
        export version=$(cat ./output.txt | jq '.name' | awk -F/ '{print $NF}' | tr -d '\"')  &&
        integrationcli integrations versions publish -n $(basename "$(dirname "$file")")  -v $version - t $token
      done;
    EOF
  }
  depends_on = [
    null_resource.createconnector
  ]
}
