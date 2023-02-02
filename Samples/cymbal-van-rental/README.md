# Setup guide

# Prerequisite
The scripts are ONLY tested on Argolis project and on Application Integration feature (Apigee Integration may or may not work havent test.).
Assumption is that you will have owner access to Project.

Make sure to go through following setting to deploy app integration successfully.

1. Create new Project 
<img width="547" alt="create project" src="https://user-images.githubusercontent.com/93729562/215848119-dabe2dd9-9fb0-4e2f-82f3-6ba5a1d74eba.png">

2. Under the top level Argolis organization, assign Organization Administrator and  Organization Policy Administrator to your argolis admin User 
<img width="1224" alt="org policy adminitrator" src="https://user-images.githubusercontent.com/93729562/215848116-d1ce44c1-78fe-4a69-b852-481213e1ab6c.png">

3. Make sure you Integration is enabled and provisioned with all the settings, refer link below
https://cloud.google.com/application-integration/docs/setup-integration
<img width="531" alt="integration" src="https://user-images.githubusercontent.com/93729562/216405862-52af544e-2f30-4a06-8c29-b2e262134d04.png">

# Setup Integration 
Go to your google cloud console, open google cloud shell, run following commands one after another.
```
git clone https://github.com/mtalreja16/google-cloud-application-integration.git
cd google-cloud-application-integration/Samples/cymbal-van-rental
```
Open cymbal-van-rental-provision.tf and update the following settings.
1. location = "-----" # Add region
2. project = "----" # Add ProjectId
3. projectnumber = "---" # Add Project Number

save the cymbal-van-rental-provision.tf


Execute
```
 terraform init
 terraform plan 
 terraform apply
``` 
And wait for about 20 min
navigate to cloudrun app "reservation-app" find the url and you should see the app running which is interacting with app integration


Note -> There is inconsistent behavior from CloudSQLProxy, which get stuck and may not able to finish the provisiong of Tables and Stored proc, if you run into this issue, you will find a file  "mysqlcmd.sh" under google-cloud-application-integration/Samples/cymbal-van-rental and  need to run this file manually using command prompt, just copy the content from the file and run it to provision the tables and stored proc in db.
