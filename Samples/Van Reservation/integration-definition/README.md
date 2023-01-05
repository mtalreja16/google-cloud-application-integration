<!-- Output copied to clipboard! -->

<!-- Yay, no errors, warnings, or alerts! -->

<h2>Cymbal Outdoor rental </h2>


**Connectors**
API Trigger
Cloud SQL Connector
REST API Task
Email Task 
Approval Task
GCS Connector - coming soon...
Pub/Sub Connector - comming soon...

**Integration Pattern(s)**
API Trigger
Fire-n-Forget
Scatter-Gather


<h3>**Prerequisite**</h3>


<h4>Create Database</h4>
* Cloud SQL - MySQL
<h4>Setup Cloud SQL Auth Proxy</h4>

wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy

<h4>Open 2 Cloud Shell</h4>

**Cloud Shell Window 1**

./cloud_sql_proxy -instances=integration-demo-364406:us-west1:integration-demo=tcp:3306

**Cloud Shell Window 2**

* mysql -u root -p --host 127.0.0.1 --port 3306 
* Create database name : catalog
* MySQL Schema : Create tables and stored procedure [https://github.com/mtalreja16/Integration-Demo/blob/main/mysql-scripts/reservation_db.sql](https://github.com/mtalreja16/Integration-Demo/blob/main/mysql-scripts/reservation_db.sql)

<h3>**Integration Setup **</h3>

* Create Integration Connector for MySQL.
* Import reservation-demov2-v10.json file in the application integration.
* We are using approval and mail connector, make sure to change the email address in the integration after Importing.

Use Following Input to test

* Operation - "POST"
* reservationId - ""
* reservation-payload -
  {
  "pickupdate": "2022-10-28",
  "dropoffdate": "2022-11-03",
  "rate": "200",
  "taxamount": "100",
  "totalamount": "800",
  "depositamount": "1000",
  "sku_id": "Van-1234567",
  "configuration": "Kitchen-Equipments, Vacuum Cleaner, GPS",
  "card": "1234-5678-9101-1121",
  "expiry": "2025-01-01",
  "cvv": "123",
  "email": "manojtrek@gmail.com",
  "name": "John Doe",
  "state": "CA",
  "licenseid": "JS500GB",
  "dob": "2000-01-01",
  "gender": 1
}


