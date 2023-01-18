locals {
  location = "us-west1"
  project = "integration-demo-364406"
  projectnumber = "901962132371"
  dbinstance="reservation-demo-v131"
  user="root"
  secretid="secret-root-v131"
  service_account_name="reservation-demo-v131"
  dbname="catalog"
  cloudrun-app="reservation-app-v131"
  mysqlconnector="reservationdb-v131" 
  pubsubconnector="inventory"
  integration="manage-reservation-v131" 
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
    "integrations.googleapis.com",
    "run.googleapis.com"
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

resource "random_password" "password" {
    length           = 16
    special          = true
    override_special = "!#$%&*()-_=+[]{}<>:?"
  }

resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  project = local.project
  service = each.key
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
    "roles/pubsub.admin"
  ])
  role = each.key
  member = format("serviceAccount:%s@%s.iam.gserviceaccount.com", google_service_account.service_account.account_id, local.project)
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

resource "google_cloud_run_service" "service" {
  name         = local.cloudrun-app
  location     = local.location
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
        env {
          name  = "name"
          value = local.integration
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

resource "google_pubsub_subscription" "sub_inventory" {
  name          = "sub-inventory"
  topic         = google_pubsub_topic.inventory.name
  ack_deadline_seconds = 10
  depends_on = [
    google_project_iam_member.member-role
  ]
}

resource "google_sql_database_instance" "demo" {
  name          = local.dbinstance
  database_version = "MYSQL_8_0"
  region        = local.location
  settings {
    tier = "db-f1-micro"
  }
  depends_on = [
    google_project_iam_member.member-role
  ]
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
  password = random_password.password.result
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
  secret_data = random_password.password.result
  depends_on = [
    google_sql_database.database
  ]
}

#curl https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64 -o ./cloud_sql_proxy  && 

resource "null_resource" "downloadproxy" {
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

resource "null_resource" "openmysql" {
  provisioner "local-exec" {
    command = <<EOF
     ./cloud_sql_proxy -dir cloudsql -instances=${local.project}:${local.location}:${local.dbinstance}=tcp:3306 & 
     sql_proxy_pid=$! && 
     sleep 10 && 
     mysql -u ${local.user} --password=${random_password.password.result} --host 127.0.0.1 --database=${local.dbname} <db/reservationdb.sql && 
     kill $sql_proxy_pid
    EOF
  }
  depends_on = [
    null_resource.downloadproxy
   
  ]
 }

resource "local_file" "connector_file" {
  content  = templatefile("connector/mysql-connector.json", {
    location = local.location, 
    project = local.project,
    projectnumber = local.projectnumber,
    dbinstance=local.dbinstance,
    user=local.user,
    password=random_password.password,
    service_account_name=local.service_account_name,
    dbname=local.dbname,
    mysqlconnector=local.mysqlconnector,
    secretid=local.secretid,
    integration=local.integration
  })
    filename = format("./%s.json", local.mysqlconnector)
}

resource "local_file" "pubsubconnector_file" {
  content  = templatefile("connector/pubsub-connector.json", {
    project = local.project,
    service_account_name=local.service_account_name,
    pubsubconnector=local.pubsubconnector,
  })
    filename = format("./%s.json", local.pubsubconnector)
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
    EOF
  }
  depends_on = [
    null_resource.openmysql
   ]
}

resource "local_file" "integration_file" {
  content  = templatefile("src/manage-reservation.json", {
    mysqlconnector=local.mysqlconnector,
    pubsubconnector=local.pubsubconnector
    location = local.location, 
    project = local.project
  })
  filename = format("./%s.json", local.integration)
}

resource "local_file" "overrides" {
  content  = templatefile("overrides/overrides.json", {
    mysqlconnector=local.mysqlconnector,
    pubsubconnector=local.pubsubconnector
  })
  filename = "overrides.json"
}


resource "null_resource" "createintegration" {
  provisioner "local-exec" {
    command = <<EOF
    export PATH=$PATH:$HOME/.integrationcli/bin &&
    export token=$(gcloud auth application-default print-access-token) && 
    integrationcli token cache -t $token &&
    sleep 2 &&
    integrationcli prefs set --reg ${local.location} --proj ${local.project} &&
    integrationcli integrations create -n ${local.integration} -f  -o ./overrides.json ./${local.integration}.json > ./output.txt &&
    export version=$(cat ./output.txt | jq '.name' | awk -F/ '{print $NF}' | tr -d '\"')  &&
    integrationcli integrations versions publish -n ${local.integration}  -v $version - t $token
    EOF
  }
 depends_on = [
    null_resource.createconnector
  ]
}
