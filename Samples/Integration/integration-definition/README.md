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
* MySQL Schema : Create tables and stored procedure [https://github.com/mtalreja16/google-cloud-application-integration/tree/main/Samples/Van%20Reservation/mysql-scripts](https://github.com/mtalreja16/google-cloud-application-integration/tree/main/Samples/Van%20Reservation/mysql-scripts)

**Integration Setup**

* Create Integration Connector for MySQL and name it "reservationdb
* Create Pub/Sub Connector with topic inventory and inventory-sub and name it "inventory"
* Create SFTP Connector - use host and credential from here https://test.rebex.net/ and name it outdoorsy-partner-feed
* Create GCS Connector - for give your project name only and name it rentalvanwalkthrough
* Import manage-reservation.json file in the application integration.
* <b>We are using mail connector, make sure to change the email address in the integration after Importing.</b>


