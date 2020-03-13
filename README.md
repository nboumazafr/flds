# Project Background
WHAT: POC implementation for an API Endpoint (backend service) fronted by ESPV2 beta1 (service proxy)
JIRA#: FRAAS-2350
EPIC#: FRAAS-443

##1. Set your current projectID 
````
gcloud config set project <projectID>
````    
    
##2. Build & Deploy Backend Service on CloudRun

###2.1 Build docker image
Build your container image using Cloud Build, 
by running the following command from the directory containing the Dockerfile:

Command: 
````
gcloud builds submit --tag gcr.io/PROJECT-ID/BACKEND_SERVICE_NAME
````

Example:
````
gcloud builds submit --tag gcr.io/flds-269622/flds
````
###2.2 Deploy to CloudRun
Command: 
````
gcloud run deploy BACKEND_SERVICE_NAME \
--image="gcr.io/endpoints-release/endpoints-runtime-serverless:2" \
--platform managed \
--project=ESP_PROJECT_ID
````
Example:
````
 gcloud run deploy flds \
       --image="gcr.io/endpoints-release/endpoints-runtime-serverless:2" \
       --platform managed \
       --project=flds-269622
````

At this point we're set with the backend implementation of our service.
Built its image and deployed to CloudRun. 

The next steps involves deploying the corresponding GCP Endpoint fronted by [ESPv2 Beta](https://cloud.google.com/endpoints/docs/openapi/glossary#extensible_service_proxy_v2)
Endpoints uses ESP Beta as an API gateway.
With this set up, ESP intercepts all requests to your services and performs any necessary checks (such as authentication) before invoking the service. 
When the service responds, ESP gathers and reports telemetry.

##3. Deploy ESPv2 Beta to Cloud Run
Will be used as a gateway fronting our backend service 

Command:
```
gcloud run deploy CLOUD_RUN_SERVICE_NAME \
    --image="gcr.io/endpoints-release/endpoints-runtime-serverless:2" \
    --platform managed \
    --project=ESP_PROJECT_ID \  
```
Example:
```
gcloud run deploy gateway \
  --image="gcr.io/endpoints-release/endpoints-runtime-serverless:2" \
  --set-env-vars=ESPv2_ARGS=--cors_preset=basic \
  --platform managed \
  --project=flds-269622 \
  --region=us-east1

You should get a response like:
Service [gateway] revision [gateway-00001] has been deployed and is serving traffic at https://gateway-ijzjfv7ydq-ue.a.run.app
```

##4. Deploy Endpoint Service Contract  

*IMPORTANT*

* Our fronting proxy (ESP) referred to as CLOUD_RUN_HOSTNAME (in our example from step 3: gateway-ijzjfv7ydq-ue.a.run.app)
will be used in the openapi yaml as the *host* field 

* Our backend service referred to as BACKEND_SERVICE (in our example from step 2.2: flds-ijzjfv7ydq-uw.a.run.appp)
  will be used in the openapi yaml as the *address* field. Example snippet:
  x-google-backend:
    address: https://flds-ijzjfv7ydq-uw.a.run.app
Command:
````
 gcloud endpoints services deploy yourOpenApiServiceDef.yaml --project ESP_PROJECT_ID
````     
Example:
````
 gcloud endpoints services deploy api/v1/flds.yaml --project flds-269622
````  
  NOTE:
  You don't need to redeploy or restart ESP if you previously deployed ESP with the rollout option set to managed. 
  This option (--platform managed) configures ESP to use the latest deployed service configuration. 
  When you specify this option, within a minute after you deploy a new service configuration,    
  ESP detects the change and automatically begins using it
  More info [here](https://cloud.google.com/endpoints/docs/openapi/deploy-endpoints-config#redeploying)   

##5. Enable your Endpoints service 
Command:
 ````
  gcloud services enable ENDPOINTS_SERVICE_NAME
 ````     
 Example:
 ````
  gcloud services enable flds-ijzjfv7ydq-ue.a.run.app
 ````       
 NOTE:
 Endpoints and ESP require the following APIs enabled: servicemanagement.googleapis.com,
 servicecontrol.googleapis.com, endpoints.googleapis.com
 In most cases 'gcloud services deploy' enables them. 
 If using Terraform you must explicitly enable the above APIs
 More info [here](https://cloud.google.com/endpoints/docs/openapi/get-started-cloud-run#checking_required_services)
 
  
##5. Build a new ESPV2 image (fronting our service) 
If the docker image did not have the service config built into it, Cloud Run would have to 
make two API calls to Google ServiceManagement at cold start. 
These calls count against your Google ServiceManagement API quota.
More info [here](https://cloud.google.com/endpoints/docs/openapi/get-started-cloud-run#configure_esp)

###5.1. Build the service config into a new ESPv2 Beta docker image

The script uses the gcloud command to download the service config, 
build the service config into a new ESPv2 Beta image, and upload the new image 
to the project container registry located here: 
gcr.io/ESP_PROJECT_ID/endpoints-runtime-serverless:CLOUD_RUN_HOSTNAME-CONFIG_ID

Command: 
````
build-espv2-image.sh -s CLOUD_RUN_HOSTNAME -c CONFIG_ID -p ESP_PROJECT_ID
````
Example:
````
./scripts/build-espv2-image.sh -s  flds-ijzjfv7ydq-ue.a.run.app -c 2020-03-11r1 -p flds-269622
````       
###5.2. Redeploy the ESPv2 Beta Cloud Run service [step 2.] with the new image

Command:
````
gcloud run deploy CLOUD_RUN_SERVICE_NAME \
  --image="gcr.io/ESP_PROJECT_ID/endpoints-runtime-serverless:CLOUD_RUN_HOSTNAME-CONFIG_ID" \
  --set-env-vars=ESPv2_ARGS=--cors_preset=basic \
  --platform managed \
  --project ESP_PROJECT_ID
````
Example:

````
gcloud run deploy gateway \
  --image="gcr.io/flds-269622/endpoints-runtime-serverless:gateway-ijzjfv7ydq-ue.a.run.app-2020-03-11r1" \
  --set-env-vars=ESPv2_ARGS=--cors_preset=basic \
  --platform managed \
  --project=flds-269622 \
  --region=us-east1
````
##6. Grant ESPv2 Beta permission to invoke the Cloud Run services

Command: 
````
gcloud run services add-iam-policy-binding BACKEND_SERVICE_NAME \
  --member "serviceAccount:ESP_PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role "roles/run.invoker" \
  --platform managed \
  --project BACKEND_PROJECT_ID
````
Example:
````
  gcloud run services add-iam-policy-binding gateway \
    --member serviceAccount:317695325510-compute@developer.gserviceaccount.com \
    --role roles/run.invoker \
    --platform managed \
    --project flds-269622
    
  you should get an output like....
    Updated IAM policy for service [gateway].
    bindings:
    - members:
      - serviceAccount:317695325510-compute@developer.gserviceaccount.com
      role: roles/run.invoker
    etag: BwWgDzGN1GE=
    version: 1
````
NOTE: Service Consumer
If you want to give someone the ability to enable your service in their own Cloud project and invoke its APIs, 
give them the Service Consumer role. 


