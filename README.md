# google-cloud-application-integration

#Pre-requisite

Organization policies is set to (this is need to access cloud run app)
1. Domain Restricted sharing - Allowed All 
2. Domain restricted contacts - Allowed All
3. Enable integration, setup region, KMS etc...

```
cd google-cloud-application-integration/Samples/cymbal-van-rental
```

open cymbal-van-rental-provision.tf

update the local values for your choice of 
1. location = "-----" # Add region
2. project = "----" # Add ProjectId
3. projectnumber = "---" # Add Project Number

save cymbal-van-rental-provision.tf

on terminal run 
 
```
 terraform init
 
 terraform plan 
 
 terraform apply.

``` 
And wait for 20 min
navigate to cloudrun app "reservation-app" find the url and you shoudl see the app running which is interacting with app integration
