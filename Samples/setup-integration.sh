#!/usr/bin/env bash
source ~/env

cd ~

echo "**********************************"
echo "*** (BEGIN) Setup Integration  ***"
echo "**********************************"

setup_logger "setup-integration"

if [ "$ENABLE_INTEGRATIONS" != "true" ]; then
  echo "Integration setup is not enabled, skipping setup."
  exit 0
fi

set -e

if [ -z "$CHILD_PROJECT" ]; then
  echo "ERROR: Environment variable CHILD_PROJECT is not set."
  exit 1
fi
  
if [ ! -z "$CHILD_PROJECT_REGION_OVERRIDE" ]; then
  export CHILD_PROJECT_REGION=$CHILD_PROJECT_REGION_OVERRIDE
fi

if [ -z "$CHILD_PROJECT_REGION" ]; then
  echo "ERROR: Environment variable CHILD_PROJECT_REGION is not set."
  exit 1
fi

if [ -z "$RUNTIME_HOST_ALIAS" ]; then
  echo "ERROR: Environment variable RUNTIME_HOST_ALIAS is not set."
  exit 1
fi

export NETWORK=default

function token { echo -n "$(gcloud config config-helper --force-auth-refresh --format json | jq -r .credential.access_token)"; }

function setup_integration_enable_apis() {
  (
    apis_task_id="integration-apis"
    begin_task "${apis_task_id}" "Enable Integration APIs" 60
    set -e
    counter=0
    enabled_service_count=0

    while [ $enabled_service_count -lt 4 ]
    do
      if [ $counter -gt 20 ]
      then
        echo "Reached counter limit of $counter, failed to enable APIs"
        enabled_services=$(gcloud services list --enabled --format json)
        echo "Failed to enable required integration APIs...Current enabled API list is $enabled_servcies"

        exit 1
      fi

      echo "*** Enable GCP APIs for Integration & Cloud SQL ***"
      gcloud services enable \
        cloudkms.googleapis.com \
        secretmanager.googleapis.com \
        connectors.googleapis.com \
        sqladmin.googleapis.com \
        integrations.googleapis.com \
        --project=$CHILD_PROJECT

      sleep 30

      enabled_service_count=$(gcloud services list --enabled --format json | \
          jq '[.[].config | select (.name == "cloudkms.googleapis.com" or .name == "integrations.googleapis.com" or .name == "secretmanager.googleapis.com" or .name == "sqladmin.googleapis.com" or .name == "connectors.googleapis.com")] | length')

      echo "Tried to enable 5 services, enabled service count is $enabled_service_count"

      ((counter=$counter+1))
    done

    end_task "${apis_task_id}"
  )
  return $?
}

function setup_integration_serviceaccount() {
  (
    integration_task_id="integration-serviceaccount"
    begin_task "${integration_task_id}" "Setup Integration Service Account" 60
    set -e
    echo "*** Creating service account for Integration connector ***"
    gcloud iam service-accounts create ${INTEGRATION_SVC_ACCOUNT} \
      --description="Service account used for Integration connector" \
      --display-name=${INTEGRATION_SVC_ACCOUNT} \
      --project="${CHILD_PROJECT}"
    sleep 10
    # roles/cloudsql.editor
    gcloud projects add-iam-policy-binding "${CHILD_PROJECT}" \
      --member=serviceAccount:${INTEGRATION_SVC_ACCOUNT}@${CHILD_PROJECT}.iam.gserviceaccount.com \
      --role=roles/cloudsql.editor
    sleep 10
    # roles/secretmanager.viewer
    gcloud projects add-iam-policy-binding "${CHILD_PROJECT}" \
      --member=serviceAccount:${INTEGRATION_SVC_ACCOUNT}@${CHILD_PROJECT}.iam.gserviceaccount.com \
      --role=roles/secretmanager.viewer
    sleep 10
    # roles/secretmanager.secretAccessor
    gcloud projects add-iam-policy-binding "${CHILD_PROJECT}" \
      --member=serviceAccount:${INTEGRATION_SVC_ACCOUNT}@${CHILD_PROJECT}.iam.gserviceaccount.com \
      --role=roles/secretmanager.secretAccessor
    end_task "${integration_task_id}"
  )
  return $?
}

function provision_integration() {
  task_id="provision-integration"
  begin_task "${task_id}" "Provision Integration In $CHILD_PROJECT_REGION Region" 60
  set -e

  KEY_RING_NAME="integration-keyring"
  KEY_NAME="integration-key"
  
  echo "Creating keyring '$KEY_RING_NAME' to be used for integrations"
  gcloud kms keyrings create $KEY_RING_NAME --location=$CHILD_PROJECT_REGION --project="${CHILD_PROJECT}"

  echo "Creating key '$KEY_NAME' to be used for integrations"
  gcloud kms keys create $KEY_NAME --keyring="$KEY_RING_NAME" --location=$CHILD_PROJECT_REGION --purpose="encryption" --project="${CHILD_PROJECT}"
  
  status_code=""
  attempts=0
  temp_file=$(mktemp)

  while [ -z "$status_code" ] || [ "$status_code" != "200" ]; do
    (("attempts = attempts + 1"))

    if [ $attempts -gt 10 ]; then
        echo "Failed to provision integrations service...last status was $status_code" 
        exit 1
    fi

    echo "Provisioning integration service in $CHILD_PROJECT_REGION... (${attempts} attempts(s)) ..."
    status_code=$(curl  -k -s -o ${temp_file} \
                -w "%{http_code}" \
                -H "Content-Type: application/json" \
                -H "authorization: Bearer $(token)" \
                -d "{\"cloud_kms_config\": {\"kms_location\": \"$CHILD_PROJECT_REGION\", \"kms_ring\": \"$KEY_RING_NAME\", \"key\": \"$KEY_NAME\", \"key_version\": \"1\"}}" \
                -X POST "https://$CHILD_PROJECT_REGION-integrations.googleapis.com/v1/projects/${CHILD_PROJECT}/locations/$CHILD_PROJECT_REGION/clients:provision")
    
    if [ "$status_code" != "200" ]; then
      echo "Error Result: $(cat $temp_file)"
      sleep 10
    fi

    echo "Provisioning integration service HTTP Return code \"${status_code}\""
  done

  echo "Providing integration service account access to key"
  gcloud kms keys add-iam-policy-binding $KEY_NAME \
                                        --location="$CHILD_PROJECT_REGION" \
                                        --keyring="$KEY_RING_NAME" \
                                        --member="serviceAccount:service-$CHILD_PROJECT_NUMBER@gcp-sa-integrations.iam.gserviceaccount.com" \
                                        --role="roles/cloudkms.cryptoKeyEncrypterDecrypter" \
                                        --project="$CHILD_PROJECT"
  end_task "${task_id}"
}

#This is the main logic for provisioning Apigee X Integration
#Notice some of the tasks are done concurrently, and others in sequence
setup_integration_enable_apis
setup_integration_serviceaccount
provision_integration

if ! wait_for_all_jobs; then
  echo "At least one Integration setup task failed ..."

  echo "Sending failure signal to DM ..."
  send_signal_to_qwiklabs_waiter "failure" "1"

  #echo "Dumping Apigee Operations List"
  #gcloud alpha apigee operations list

  echo "Killing all pending sub-tasks ..."
  kill_all_children

  exit 1
fi

echo "*******************************"
echo "*** (END) Setup Integration ***"
echo "*******************************"
