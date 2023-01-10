#!/usr/bin/env bash
source ~/env
source "$(which demo-resources-utils.sh)"

task_id="setup-demo-resources"
setup_logger "${task_id}"
setup_error_handler "${task_id}"
cd ~

echo "****************************************"
echo "*** (BEGIN) Setting Up demo Resources ***"
echo "****************************************"

set -e

if [ -z "$CHILD_PROJECT" ]; then
   echo "ERROR: Environment variable CHILD_PROJECT is not set."
   exit 1
fi

if [ -z "$CHILD_PROJECT_REGION" ]; then
   echo "ERROR: Environment variable CHILD_PROJECT_REGION is not set."
   exit 1
fi

if [ -z "$CHILD_PROJECT_ZONE" ]; then
   echo "ERROR: Environment variable CHILD_PROJECT_ZONE is not set."
   exit 1
fi

if [ -z "$RUNTIME_HOST_ALIAS" ]; then
   echo "ERROR: Environment variable RUNTIME_HOST_ALIAS is not set."
   exit 1
fi

export demo_RESOURCES=$(get_metadata_property 'demoResources' "")


# strip out lines that are only comments
echo "$demo_RESOURCES" | sed -e '/^[ \t]*#/d' > demo_resources.json


function setup_databases_enable_apis() {
  (
    apis_task_id="database-apis"
    begin_task "${apis_task_id}" "Enable Cloud SQL APIs" 60
    set -e
    counter=0
    enabled_service_count=0

    while [ $enabled_service_count -lt 2 ]
    do
      if [ $counter -gt 20 ]
      then
        echo "Reached counter limit of $counter, failed to enable APIs"
        enabled_services=$(gcloud services list --enabled --format json)
        echo "Failed to enable required database APIs...Current enabled API list is $enabled_servcies"

        exit 1
      fi

      echo "*** Enable GCP APIs for Cloud SQL ***"
      gcloud services enable secretmanager.googleapis.com \
        sqladmin.googleapis.com \
        --project=$CHILD_PROJECT

      sleep 30

      enabled_service_count=$(gcloud services list --enabled --format json | \
          jq '[.[].config | select (.name == "secretmanager.googleapis.com" or .name == "sqladmin.googleapis.com")] | length')

      echo "Tried to enable 2 services, enabled service count is $enabled_service_count"

      ((counter=$counter+1))
    done

    end_task "${apis_task_id}"
  )
  return $?
}

function demo_resources_databases() {
(
   begin_task "databases" "Provision Databases" 1380

   setup_databases_enable_apis
   process_databases_section ~/demo_resources.json
   
   end_task "databases"
)
return $?
}

demo_resources_databases

function enable_pubsub_apis() {
  (
    apis_task_id="pubsub-apis"
    begin_task "${apis_task_id}" "Enable PubSub APIs" 120
    set -e
    counter=0
    enabled_service_count=0

    while [ $enabled_service_count -lt 1 ]
    do
      if [ $counter -gt 20 ]
      then
        echo "Reached counter limit of $counter, failed to enable APIs"
        enabled_services=$(gcloud services list --enabled --format json)
        echo "Failed to enable PubSub API...Current enabled API list is $enabled_servcies"

        exit 1
      fi

      echo "*** Enable GCP APIs for Cloud SQL ***"
      gcloud services enable pubsub.googleapis.com --project=$CHILD_PROJECT

      sleep 30

      enabled_service_count=$(gcloud services list --enabled --format json | jq '[.[].config | select (.name == "pubsub.googleapis.com")] | length')

      echo "Tried to enable services, enabled service count is $enabled_service_count"

      ((counter=$counter+1))
    done

    end_task "${apis_task_id}"
  )
  return $?
}

function demo_resources_pubsubtopics() {
(
   begin_task "pubsub" "Provision PubSub Topics" 120

   enable_pubsub_apis
   process_pubsub_section ~/demo_resources.json
   
   end_task "pubsub"
)
return $?
}

demo_resources_pubsubtopics

function demo_resources_app_integration() {
(
begin_task "import-integrations" "Import App integration assets that are part of demo" 1380

if [ "$ENABLE_INTEGRATIONS" != "true" ]; then
  echo "Application Integration setup is not enabled, skipping setup."
else   
   wait_for_integrations_region_provisioning "${CHILD_PROJECT}"
   create_integration_cloudsql_connector
   process_integrations_section ~/demo_resources.json
fi

end_task "import-integrations"
)
return $?
}

demo_resources_app_integration ~/demo_resources.json

if ! wait_for_all_jobs ; then
  echo "At least one demo Resource setup task failed ... "
  echo "Killing all pending sub-tasks ..."
  kill_all_children
  exit 1
fi

echo "**************************************"
echo "*** (End) Setting Up Demo Resources ***"
echo "**************************************"
