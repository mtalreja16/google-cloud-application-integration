<!-- Output copied to clipboard! -->

<!-- Yay, no errors, warnings, or alerts! -->

<h2>Integration Management API</h2>

There are couple of ways to do Interact with Integration outsite of application integratiun

<h3> Through gcloud, and Integration API's </h3>

This is fairly straightforward, here are some commnds which will help you.

<h4>KickOff Integration</h4>

```sh
export TOKEN=$(gcloud auth application-default print-access-token)
export REGION=us-west1
export PROJECT=integration-demo-364406

curl -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json" -X POST \
https://$REGION-integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/integrations/reservation-demo`:execute`
```

<h4>Resume Integration</h4>

```sh
export TOKEN=$(gcloud auth application-default print-access-token)
export EXECUTION_ID=507585c6-c288-493b-b299-c4abbb404596
export SUSPENSION_ID=e55b07b9-cd53-48b0-9765-3b3c5b7b374e
export EXECUTION_ID2=39e1452a-1b67-4b07-ae24-82a725ae21a7

curl -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json" -X POST \
https://$REGION-integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/integrations/reservation-demo/executions/$EXECUTION_ID/suspensions/$SUSPENSION_ID:lift \
-d '{ "suspensionResult":"DONE"}'

curl -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json" -X POST \
https://$REGION-integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/integrations/reservation-demo/executions/$EXECUTION_ID2/suspensions/-:lift \
-d '{ "suspensionResult":"DONE"}'
```

<h4>Download Logs</h4>

```sh
export TOKEN=$(gcloud auth application-default print-access-token)
export REGION=us-west1
export PROJECT=integration-demo-364406

curl -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json" \
https://$REGION-integrations.googleapis.com/v1/projects/$PROJECT/locations/$REGION/integrations/reservation-demo/executions/cba2de38-4d3c-41ed-800f-9e16da017ef7
```

<h3> Through go sdk ONLY</h3>

google.golang.org/api/integrations/v1alpha

You can find functions like ExecuteIntegration and LiftIntegration

<h3> Custom API wrapping up go sdk </h3>
The code here shows you how to wrap go sdk into Go API, which can be run in cloudrun or in your local console, here is how you will compile.

```sh
cd Integration-Demo/integration-lib 
docker build -t integration-lib:latest 
docker tag integration-lib:latest gcr.io/{projectId}/integration-lib:latest 
gcloud docker -- push gcr.io/{projectId}/integration-lib:latest 
```


* Now go and deploy this in cloud run, refer to this terraform script to spin up CloudRun with appropriate permission to integration </br>
      cloud_run_integration_lin.tf
      
* You can also run this locally by doing 

```sh
 cd ./integration-lib
 
 go run integration.go
```
