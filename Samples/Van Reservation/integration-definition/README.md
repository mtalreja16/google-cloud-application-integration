<!-- Output copied to clipboard! -->

<!-- Yay, no errors, warnings, or alerts! -->

<h2>Cymbal Outdoor rental </h2>


**Connectors**
API Trigger
Cloud SQL Connector
REST API Task
Email Task 
Suspend Task
Pub/Sub Connector
Cloud Functions Task
GCS Connector - coming soon...

**Integration Pattern(s)**
API Trigger
Fire-n-Forget


**Prerequisite**


<h4>Create Database</h4>
* Cloud SQL - MySQL
<h4>Setup Cloud SQL Auth Proxy</h4>

   wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
   chmod +x cloud_sql_proxy

<h4>Open 2 Cloud Shell</h4>

*Cloud Shell Window 1*

./cloud_sql_proxy -instances=integration-demo-364406:us-west1:integration-demo=tcp:3306

*Cloud Shell Window 2*

* mysql -u root -p --host 127.0.0.1 --port 3306 
* Create database name : catalog
* MySQL Schema : Create tables and stored procedure [https://github.com/mtalreja16/Integration-Demo/blob/main/mysql-scripts/reservation_db.sql](https://github.com/mtalreja16/Integration-Demo/blob/main/mysql-scripts/reservation_db.sql)

**Integration Setup**

* Create Integration Connector for MySQL.
* Import reservation-demov2-v10.json file in the application integration.
* We are using mail connector, make sure to change the email address in the integration after Importing.



