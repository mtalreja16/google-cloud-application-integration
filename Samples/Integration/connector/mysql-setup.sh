
function setup_cloudsql_components() {
  (
    set -e
    echo "Downloading Cloud SQL Auth proxy ..."
    mkdir ./Integration/connector/cloudsql 
    curl https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64 -o cloud_sql_proxy 
    chmod +x cloud_sql_proxy
  )
  return $?
}

function setup_cloudsql_database() {
  (
    set -e
    db_info="$1"
    instance_name=$(echo ${db_info} | jq -r ".instance_name")
    name=$(echo ${db_info} | jq -r ".name")
    root_pass=$(echo ${db_info} | jq -r ".password")
    PROJECT=$(echo ${db_info} | jq -r ".project")
    REGION=$(echo ${db_info} | jq -r ".location")
    
    
    CLOUDSQL_INSTANCE_ID="${PROJECT}:${REGION}:${instance_name}"
    
    
    echo "*** Starting Cloud SQL Proxy for instance $CLOUDSQL_INSTANCE_ID ***"
    
    ./cloud_sql_proxy -dir ./Integration/connector/cloudsql -instances=${CLOUDSQL_INSTANCE_ID}=tcp:3306 &
    sql_proxy_pid=$!
    sleep 10
    sql_len=$(echo ${db_info} | jq '.sql_commands | length')
    for ((i = 0; i < sql_len; i++)); do
        sql_command=$(echo ${db_info} | jq -r ".sql_commands[$i]")
        mysql -u root --password=${root_pass} --execute "${sql_command}" --host 127.0.0.1 --database=${name}
    done
    kill $sql_proxy_pid
  )
  return $?
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

        setup_cloudsql_database "$(jq -r ".databases[$i]" ${filename})"
    done
}
setup_cloudsql_components
process_databases_section ./Integration/connector/tmpresources.json