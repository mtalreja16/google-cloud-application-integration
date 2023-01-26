# Setup guide

# Prerequisite
The scripts are ONLY tested on Argolis project and on Application Integration feature (Apigee Integration may or may not work havent test.).
Assumption is that you will have owner access to Project.


Since we are deploying an app on cloud run, make sure your Organization policies is set to allow "UnAuthenticated User Access"

1. Domain Restricted sharing - Allowed All 
2. Domain restricted contacts - Allowed All
3. Make sure you Integration is enabled and provisioned with all the settings, refer link below
https://cloud.google.com/application-integration/docs/setup-integration

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


 
```
 terraform init
```
Check for any errors here..

```
 terraform plan 
 terraform apply
``` 
And wait for 20 min
navigate to cloudrun app "reservation-app" find the url and you should see the app running which is interacting with app integration
