```sh
export projectId=integration-demo-364406
docker build . -t reservation-app:latest 
docker tag reservation-app:latest gcr.io/{projectId}/reservation-app:latest
docker -- push gcr.io/{projectId}/reservation-app:latest 
```
