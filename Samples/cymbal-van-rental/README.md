# Setup guide

# Prerequisite

Since we are deploying an app on cloud run, make sure your Organization policies is set to allow "UnAuthenticated User Access"
1. Domain Restricted sharing - Allowed All 
2. Domain restricted contacts - Allowed All

Make sure you Integration is enabled and ready with all the settings, refer link below
https://cloud.google.com/application-integration/docs/setup-integration

# Setup Integration 
```
git clone https://github.com/mtalreja16/google-cloud-application-integration.git
cd google-cloud-application-integration/Samples/cymbal-van-rental
vi ./cymbal-van-rental-provision.tf
i
```
Update values for
1. location = "-----" # Add region
2. project = "----" # Add ProjectId
3. projectnumber = "---" # Add Project Number
press escape and type
```
!wq!
```
 This will save the cymbal-van-rental-provision.tf


 
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
