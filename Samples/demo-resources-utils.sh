#!/usr/bin/env bash
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"


function setup_cloudsql_components() {
  (
    comp_task_id="cloudsql-comp"
    begin_task "${comp_task_id}" "Install Cloud SQL components" 60
    set -e
    echo "Downloading Cloud SQL Auth proxy ..."
    mkdir cloudsql
    curl -s https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -o cloud_sql_proxy
    chmod +x cloud_sql_proxy
    end_task "${comp_task_id}"
  )
  return $?
}

function setup_cloudsql_instance() {
  (
    cloudsql_task_id="cloudsql-instance"
    begin_task "${cloudsql_task_id}" "Setup CloudSQL instance" 60
    set -e
    db_info="$1"

    instance_name=$(echo ${db_info} | jq -r ".instance_name")
    version=$(echo ${db_info} | jq -r ".version")
    cpu=$(echo ${db_info} | jq -r ".instance_cpu")
    mem=$(echo ${db_info} | jq -r ".instance_mem")
    instance_pwd=$(openssl rand -base64 21)

    create_secret "${instance_name}-password" "$instance_pwd"

    echo "*** Setup Cloud SQL instance ***"
    gcloud sql instances create ${instance_name} \
      --database-version=${version} \
      --cpu=${cpu} \
      --memory=${mem} \
      --region=${CHILD_PROJECT_REGION} \
      --project=${CHILD_PROJECT}
    echo "*** Setting root password ***"
    gcloud sql users set-password root \
      --host=% \
      --instance ${instance_name} \
      --password ${instance_pwd} \
      --project=${CHILD_PROJECT}

    end_task "${cloudsql_task_id}"
  )
  return $?
}

function setup_cloudsql_database() {
  (
    cloudsql_task_id="cloudsql-database"
    begin_task "${cloudsql_task_id}" "Setup CloudSQL database" 60
    set -e
    db_info="$1"
    instance_name=$(echo ${db_info} | jq -r ".instance_name")
    name=$(echo ${db_info} | jq -r ".name")
    root_pass=$(gcloud secrets versions access 1 --secret ${instance_name}-password --project $CHILD_PROJECT)
    CLOUDSQL_INSTANCE_ID="${CHILD_PROJECT}:${CHILD_PROJECT_REGION}:${instance_name}"

    echo "*** Creating SQL database ${name} ***"
    gcloud sql databases create ${name} -i=${instance_name} --project=${CHILD_PROJECT}

    echo "*** Starting Cloud SQL Proxy for instance $CLOUDSQL_INSTANCE_ID ***"
    ./cloud_sql_proxy -dir ./cloudsql -instances=${CLOUDSQL_INSTANCE_ID}=tcp:3306 &
    sql_proxy_pid=$!
    sleep 10
    sql_len=$(echo ${db_info} | jq '.sql_commands | length')
    for ((i = 0; i < sql_len; i++)); do
        sql_command=$(echo ${db_info} | jq -r ".sql_commands[$i]")
        mysql -u root --password=${root_pass} --execute "${sql_command}" --host 127.0.0.1 --database=${name}
    done
    kill $sql_proxy_pid
    end_task "${cloudsql_task_id}"
  )
  return $?
}

export CLOUDSQL_INSTANCE_NAME="myinstance"
export CLOUDSQL_DB_NAME="reservationdb"
export SECRET_MANAGER_NAME="$CLOUDSQL_INSTANCE_NAME-password"
export INTEGRATION_CONNECTOR_NAME="cloudsql-mysql"

generate_connector_post_data() {
  cat <<EOF
{
  "connectorVersion": "projects/${CHILD_PROJECT}/locations/global/providers/gcp/connectors/${INTEGRATION_CONNECTOR_NAME}/versions/1",
  "configVariables": [
    {
      "key": "project_id",
      "stringValue": "${CHILD_PROJECT}"
    },
    {
      "key": "database_region",
      "stringValue": "${CHILD_PROJECT_REGION}"
    },
    {
      "key": "instance_id",
      "stringValue": "${CLOUDSQL_INSTANCE_NAME}"
    },
    {
      "key": "database_name",
      "stringValue": "${CLOUDSQL_DB_NAME}"
    }
  ],
  "authConfig": {
    "authType": "USER_PASSWORD",
    "userPassword": {
      "username": "root",
      "password": {
        "secretVersion": "projects/${CHILD_PROJECT_NUMBER}/secrets/${SECRET_MANAGER_NAME}/versions/1"
      }
    }
  },
  "serviceAccount": "${INTEGRATION_SVC_ACCOUNT}@${CHILD_PROJECT}.iam.gserviceaccount.com"
}
EOF
}

function create_integration_cloudsql_connector() {
  connector_task_id="integration-cloud-sql-connector"
  begin_task "${connector_task_id}" "Create Integration Cloud SQL Connector" 900
  status_code=""
  attempts=0
  temp_file=$(mktemp)
  connector_request_payload=$(generate_connector_post_data)

  echo "Connector request payload: $connector_request_payload"

  while [ -z "$status_code" ] || [ "$status_code" != "200" ]; do
    (("attempts = attempts + 1"))

    if [ $attempts -gt 60 ]; then
      echo "Failed to create connector $INTEGRATION_CONNECTOR_NAME...last status was $status_code" 
      exit 1
    fi
    echo "Creating Integration Connector... (${attempts} attempts(s)) ..."

    status_code=$(curl -k -s -o ${temp_file} \
      -w "%{http_code}" \
      --max-time "5" \
      -d "$connector_request_payload" \
      -H "Authorization: Bearer $(project_access_token)" \
      -H "Content-Type: application/json" \
      -X POST "https://connectors.googleapis.com/v1/projects/${CHILD_PROJECT}/locations/${CHILD_PROJECT_REGION}/connections?connectionId=${INTEGRATION_CONNECTOR_NAME}" | head -1)
    echo "Creating Integration Connector Status Code: ${status_code}"
    
    if [ "$status_code" != "200" ]; then
      echo "Error Result: $(cat $temp_file)"
      sleep 10
    fi
  done
  echo "Integration Connector provisioning started. HTTP Return code \"${status_code}\""
  operation_id=$(jq ".name" -r ${temp_file})
  rm ${temp_file}
  operation_status=""
  attempts=0
  while [ -z "$operation_status" ] || [ "$operation_status" != "true" ]; do
    (("attempts = attempts + 1"))

    if [ $attempts -gt 45 ]; then
        echo "Exceeded maximum wait period for connector creation to complete...last status was $operation_status" 
        exit 1
    fi

    echo "Checking Integration Connector long running operation... (${attempts} attempts(s)) ..."
    operation_status=$(curl -k -s \
      --max-time "5" \
      -H "Authorization: Bearer $(project_access_token)" \
      "https://connectors.googleapis.com/v1/${operation_id}" | jq ".done" -r)
    echo "Integration Connector long running operation status: ${operation_status}"
    
    if [ "$operation_status" != "true" ]; then
      echo "Waiting 60 seconds prior to next check..."
      sleep 60
    fi
  done
  echo "Integration Connector provisioning completed successfully!"
  end_task "${connector_task_id}"
}

function update_connector_reference() {
    local conn_name=$1
    local int_definition_file=$2

    if [ ! -z "$conn_name" ] && [ "$conn_name" != "null" ]; then
        filter_name="projects/${CHILD_PROJECT}/locations/${CHILD_PROJECT_REGION}/connections/${conn_name}"
        status_code=""
        attempts=0
        temp_file2=$(mktemp)
        connector_count=0

        while [ -z "$status_code" ] || [ "$status_code" != "200" ] || [ "$connector_count" == "0" ]; do
            (("attempts = attempts + 1"))

            if [ $attempts -gt 60 ]; then
                echo "Failed to retrieve connector using filter: $filter_name...last status was $status_code" >&2
                exit 1
            fi

            echo "Retrieving Connector version & details using filter '$filter_name'... (${attempts} attempts(s)) ..." && sleep 10

            status_code=$(curl -k -s -o ${temp_file2} \
                -w "%{http_code}" \
                -H "Authorization: Bearer $(project_access_token)" \
                https://connectors.googleapis.com/v1/projects/${CHILD_PROJECT}/locations/${CHILD_PROJECT_REGION}/connections\?filter\=name:"${filter_name}")

            echo "Connector retrieval request returned HTTP status code $status_code"
                    
            if [ "$status_code" != "200" ]; then
                echo "Error Result: $(cat $temp_file)"
            else
                connector_count=$(jq -r '.connections | length' $temp_file2)
                echo "Connector count was $connector_count"
            fi
        done

        new_conn_name=$(jq -r '.connections[].name' ${temp_file2})
        new_service_name=$(jq -r '.connections[].serviceDirectory' ${temp_file2})
        new_conn_version=$(jq -r '.connections[].connectorVersion' ${temp_file2})

        echo "Replacing #NEW_CONN_NAME# marker with '$new_conn_name' from $int_definition_file"
        sed -i="" "s/#CONN_NAME#/${new_conn_name//\//\\/}/g" $int_definition_file

        echo "Replacing #NEW_SERVICE_NAME# marker with '$new_service_name' from $int_definition_file"
        sed -i="" "s/#SERVICE_NAME#/${new_service_name//\//\\/}/g" $int_definition_file

        echo "Replacing #NEW_CONN_VERSION# marker with '$new_conn_version' from $int_definition_file"
        sed -i="" "s/#CONN_VERSION#/${new_conn_version//\//\\/}/g" $int_definition_file
    fi
}

function publish_integration_version() {
    local int_publish=$1
    local int_definition_file=$2

    if [ "$int_publish" = "true" ]; then
        status_code=""
        attempts=0
        while [ -z "$status_code" ] || [ "$status_code" != "200" ]; do
            (("attempts = attempts + 1"))

            if [ $attempts -gt 10 ]; then
                echo "Failed to publish integration version $version_id...last status was $status_code" >&2
                exit 1
            fi

            echo "Publishing integration... (${attempts} attempts(s)) ..." && sleep 10
            status_code=$(curl -k -s -o ${temp_file} \
                -w "%{http_code}" \
                --max-time "5" \
                -H "Authorization: Bearer $(project_access_token)" \
                -X POST "https://${CHILD_PROJECT_REGION}-integrations.googleapis.com/v1/${version_id}:publish")

            echo "Integration publish request returned HTTP status code $status_code, response body was: $(cat ${temp_file})"
        done
        echo "Got HTTP \"${status_code}\" from the publish integration API ..."
    fi
}

function import_integration() {
    local int_name=$1
    local int_publish=$2
    local pubsub_topic=$3
    local conn_name=$4
    local int_definition_file=$5
        
    update_connector_reference "$conn_name" "$int_definition_file"

    echo "Replacing #HIPSTER_MOCK# marker with 'https://$RUNTIME_HOST_ALIAS/products' from $int_definition_file"
    sed -i="" "s/#HIPSTER_MOCK#/https:\/\/${RUNTIME_HOST_ALIAS//\//\\/}\/products/g" $int_definition_file

    echo "Replacing #SUBSCRIPTION_NAME# marker with '${CHILD_PROJECT}_${pubsub_topic}' from $int_definition_file"
    sed -i="" "s/#SUBSCRIPTION_NAME#/${CHILD_PROJECT}_${pubsub_topic}/g" $int_definition_file

    status_code=""
    attempts=0
    temp_file=$(mktemp)
    while [ -z "$status_code" ] || [ "$status_code" != "200" ]; do
        (("attempts = attempts + 1"))

        if [ $attempts -gt 10 ]; then
            echo "Failed to create integration version...last status was $status_code" >&2
            exit 1
        fi
        
        echo "Waiting for Integration to create... (${attempts} attempts(s)) ..."
        status_code=$(curl -k -s -o ${temp_file} \
            -w "%{http_code}" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $(project_access_token)" \
            --data "@${int_definition_file}" \
            -X POST "https://${CHILD_PROJECT_REGION}-integrations.googleapis.com/v1/projects/${CHILD_PROJECT}/locations/${CHILD_PROJECT_REGION}/integrations/${int_name}/versions?newIntegration=true")

        echo "Integration version creation request returned HTTP status code $status_code"
        
        if [ "$status_code" != "200" ]; then
            echo "Error Result: $(cat $temp_file)"
            sleep 10
        fi
    done

    #retrieving version id from create integration response
    version_id=$(jq ".name" -r ${temp_file})
    rm ${temp_file}

    publish_integration_version "$int_publish" "$int_definition_file"
}

function process_integrations_section() {
    local filename="$1"

    len=$(jq '.integrations | length' ${filename})

    for ((i = 0; i < len; i++)); do
        int_name=$(jq -r ".integrations[$i].name" ${filename})
        int_url=$(jq -r ".integrations[$i].bundle_url" ${filename})
        int_publish=$(jq -r ".integrations[$i].publish" ${filename})
        pubsub_topic=$(jq -r ".integrations[$i].pubsubTopic" ${filename})
        conn_name=$(jq -r ".integrations[$i].connectorName" ${filename})

        int_definition_file=$(mktemp)

        echo "Integration Name: $int_name"
        echo "Integration URL: $int_url"
        echo "Integration Publish: $int_publish"
        echo "PubSub Topic: $pubsub_topic"
        echo "Connector Name: $conn_name"

        status_code=$(curl -k -s -o ${int_definition_file} -w "%{http_code}" ${int_url})

        echo "Integration template file retrieval request from ${int_url} returned HTTP status code $status_code"

        import_integration "$int_name" "$int_publish" "$pubsub_topic" "$conn_name" "$int_definition_file"
    done
}

function process_databases_section() {
    filename="$1"
    db_len=$(jq '.databases | length' ${filename})

    for ((i = 0; i < db_len; i++)); do
        db_type=$(jq -r ".databases[$i].type" ${filename})
        
        #only cloudsql is supported for now
        if [ "$db_type" != "cloudsql" ]; then
            echo "DB Type of $db_type is not supported, only cloudsql is"
            continue
        fi

        if [ $i == 0 ]; then
            setup_cloudsql_components
        fi

        setup_cloudsql_instance "$(jq -r ".databases[$i]" ${filename})"
        setup_cloudsql_database "$(jq -r ".databases[$i]" ${filename})"
    done
}

function create_pubsub_topic() {
    topic_name=$1
    task_id="pubsub-topic"
    begin_task "${task_id}" "Create PubSub Topic" 60
    set -e

    status_code=""
    attempts=0
    temp_file=$(mktemp)

    # Retrying to make this more resilient to PubSub service taking a while to be enabled
    while [ -z "$status_code" ] || [ "$status_code" != "200" ]; do
      (("attempts = attempts + 1"))

      if [ $attempts -gt 15 ]; then
          echo "Failed to create topic $topic_name...last status was $status_code"
          exit 1
      fi
      echo "Creating PubSub topic... (${attempts} attempt(s)) ..."
      
      #using REST call here since gcloud command makes it harder to get status code on failure
      status_code=$(curl -k -s -o ${temp_file} \
                        -w "%{http_code}" \
                        -H "Authorization: Bearer $(project_access_token)" \
                        -X PUT "https://pubsub.googleapis.com/v1/projects/${CHILD_PROJECT}/topics/${topic_name}")
      
      echo "Creating PubSub topic Status Code: ${status_code}"

      if [ "$status_code" != "200" ]; then
        echo "PubSub topic creation failed with response: $(cat $temp_file)"
      fi

      sleep 30
    done

    end_task "${task_id}"
}

function process_pubsub_section() {
    filename="$1"
    topics_len=$(jq '.pubsubTopics | length' ${filename})

    for ((i = 0; i < topics_len; i++)); do
        topic_name=$(jq -r ".pubsubTopics[$i].name" ${filename})

        create_pubsub_topic "$topic_name"
    done
}