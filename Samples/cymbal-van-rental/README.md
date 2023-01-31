# Setup guide

# Prerequisite
The scripts are ONLY tested on Argolis project and on Application Integration feature (Apigee Integration may or may not work havent test.).
Assumption is that you will have owner access to Project.

Make sure to go through following setting to deploy app integration successfully.

1. Create new Project 
<img width="547" alt="create project" src="https://user-images.githubusercontent.com/93729562/215848119-dabe2dd9-9fb0-4e2f-82f3-6ba5a1d74eba.png">

2. Under the top level Argolis organization, assign Organization Administrator and  Organization Policy Administrator to your argolis admin User 
<img width="1224" alt="org policy adminitrator" src="https://user-images.githubusercontent.com/93729562/215848116-d1ce44c1-78fe-4a69-b852-481213e1ab6c.png">

3. For the application integration project, open you Organization Policy and make exception to allow ingress for cloud run to call app unauthenticated.

<img width="661" alt="domain-restricted" src="https://user-images.githubusercontent.com/93729562/215848114-8659d947-44ea-4d82-98bf-d62f49619b6c.png">

<img width="688" alt="allowingress cloud run " src="https://user-images.githubusercontent.com/93729562/215848099-93b00d28-80c3-402e-8309-25df9071f782.png">

4. Also, for the application integration project, change the org policy for cloudfunction as it also need to be called through app integration under specific user account 

<img width="635" alt="allowingress cloud function" src="https://user-images.githubusercontent.com/93729562/215848109-e647f606-885d-4f3d-b0d0-603f05b1ec0e.png">


5. Make sure you Integration is enabled and provisioned with all the settings, refer link below
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


Execute
```
 terraform init
 terraform plan 
 terraform apply
``` 
And wait for about 20 min
navigate to cloudrun app "reservation-app" find the url and you should see the app running which is interacting with app integration
