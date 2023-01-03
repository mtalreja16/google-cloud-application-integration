<!-- Output copied to clipboard! -->

<!-- Yay, no errors, warnings, or alerts! -->

<h2>Integration Management API</h2>

There are couple of ways to do Interact with Integration outsite of application integratiun

<h3> Through gcloud, and Integration API's </h3>

This is fairly straightforward, here are some commnds which will help you.
**KickOff Integration**

export TOKEN=$(gcloud auth application-default print-access-token)

curl -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json" -X POST  https://us-west1-integrations.googleapis.com/v1/projects/integration-demo-364406/locations/us-west1/integrations/reservation-demo`:execute`

**Resume Integration**

export TOKEN=$(gcloud auth application-default print-access-token)

curl -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json" -X POST  https://us-west1-integrations.googleapis.com/v1/projects/integration-demo-364406/locations/us-west1/integrations/reservation-demo/executions/507585c6-c288-493b-b299-c4abbb404596/suspensions/e55b07b9-cd53-48b0-9765-3b3c5b7b374e:lift -d '{ "suspensionResult":"DONE"}'

export TOKEN=$(gcloud auth application-default print-access-token)

curl -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json" -X POST  https://us-west1-integrations.googleapis.com/v1/projects/integration-demo-364406/locations/us-west1/integrations/reservation-demo/executions/39e1452a-1b67-4b07-ae24-82a725ae21a7/suspensions/-:lift -d '{ "suspensionResult":"DONE"}'

**Download Logs**

export TOKEN=$(gcloud auth application-default print-access-token)

curl -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json"  https://us-west1-integrations.googleapis.com/v1/projects/integration-demo-364406/locations/us-west1/integrations/reservation-demo/executions/cba2de38-4d3c-41ed-800f-9e16da017ef7

<h3> Through go sdk ONLY</h3>

google.golang.org/api/integrations/v1alpha

You can find functions like ExecuteIntegration.

<h3> Custom API wrapping up go sdk </h3>
The code here shows you how to wrap go sdk into Go API, which can be run in cloudrun or in your local console, here is how you will compile
cd Integration-Demo/integration-lib
docker build -t integration-lib:latest .
docker tag integration-lib:latest gcr.io/{projectId}/integration-lib:latest
gcloud docker -- push gcr.io/{projectId}/integration-lib:latest

Now go and deploy this in cloud run

You can also run this locally by doing cd Integration-Demo/integration-lib 
and then "go run integration.go"
