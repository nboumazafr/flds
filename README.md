
ESP_PROJECT_ID flds-269622
ESP_PROJECT_NUMBER 317695325510
CLOUD_RUN_HOSTNAME = ENDPOINTS_HOST gateway-ijzjfv7ydq-ue.a.run.app
CLOUD_RUN_SERVICE_NAME gateway
CLOUD_RUN_SERVICE_URL https://gateway-ijzjfv7ydq-ue.a.run.app
SERVICE_CONFIG_ID  2020-03-01r0 ESP-V2-IMAGE gcr.io/ flds-269622/endpoints-runtime-serverless:gateway-ijzjfv7ydq-ue.a.run.app-2020-03-01r0
BACKEND_SERVICE_NAME flds
BACKEND_PROJECT_ID flds-269622   //USED THE SAME ProjectID

NOTE: Service Consumer
If you want to give someone the ability to enable your service in their own Cloud project and invoke its APIs, 
give them the Service Consumer role. 

https://cloud.google.com/endpoints/docs/openapi/get-started-cloud-run

>>>> https://cloud.google.com/run/docs/quickstarts/build-and-deploy 
###1. Set your current projectID 
    gcloud config set project <projectID>
    
### 2. Deploy CloudRun service 
Command: 
````
gcloud run deploy CLOUD_RUN_SERVICE_NAME \
--image="gcr.io/endpoints-release/endpoints-runtime-serverless:2" \
--allow-unauthenticated \
--platform managed \
--project=ESP_PROJECT_ID
````
Example:
````
 gcloud run deploy gateway \
       --image="gcr.io/endpoints-release/endpoints-runtime-serverless:2" \
       --platform managed \
       --project=flds-269622
````
##3. Deploy Endpoint Service Contract  
Command:
````
 gcloud endpoints services deploy yourOpenApiServiceDef.yaml --project ESP_PROJECT_ID
````     
Example:
````
 gcloud endpoints services deploy openapi/flds.yaml --project flds-269622
````  
  NOTE:You don't need to redeploy or restart ESP if you previously deployed ESP with the rollout option set to managed. This option configures ESP to use the latest deployed service configuration. When you specify this option, within a minute after you deploy a new service configuration,    
  ESP detects the change and automatically begins using it
     https://cloud.google.com/endpoints/docs/openapi/deploy-endpoints-config#redeploying   

##4. Build a new ESPV2 beta image 
If the docker image did not have the service config built into it, Cloud Run would have to make two API calls to Google ServiceManagement at cold start. These calls count against your Google ServiceManagement API quota.
More info here: https://cloud.google.com/endpoints/docs/openapi/get-started-cloud-run#configure_esp

Command: 
````
gcloud_build_image -s CLOUD_RUN_HOSTNAME \
    -c CONFIG_ID -p ESP_PROJECT_ID
````

Example:
````
     ./build-espv2-image.sh -s  gateway-ijzjfv7ydq-ue.a.run.app -c  2020-03-06r0 -p flds-269622
````       
   	     
5. redeploy so that call to service config are not counting against us and add some other args like CORS
gcloud run deploy CLOUD_RUN_SERVICE_NAME \
  --image="gcr.io/ESP_PROJECT_ID/endpoints-runtime-serverless:CLOUD_RUN_HOSTNAME-CONFIG_ID" \
  --set-env-vars=ESPv2_ARGS=--cors_preset=basic \
  //--allow-unauthenticated \
  --platform managed \
  --project ESP_PROJECT_ID
  
6. Grant ESPv2 Beta permission to invoke the Cloud Run services
gcloud run services add-iam-policy-binding BACKEND_SERVICE_NAME \
  --member "serviceAccount:ESP_PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role "roles/run.invoker" \
  --platform managed \
  --project BACKEND_PROJECT_ID
  
  gcloud run services add-iam-policy-binding gateway \
    --member serviceAccount:317695325510-compute@developer.gserviceaccount.com \
    --role roles/run.invoker \
    --platform managed \
    --project flds-269622
    
    you get an output like....
    Updated IAM policy for service [gateway].
    bindings:
    - members:
      - serviceAccount:317695325510-compute@developer.gserviceaccount.com
      role: roles/run.invoker
    etag: BwWgDzGN1GE=
    version: 1

TESTING via Curl:
curl --request GET \
   --header "content-type:application/json" \
   "https://gateway-ijzjfv7ydq-ue.a.run.app/logs"
   fldsKAey=AIzaSyAf9Lc-jHjjJblOFvyU_oeu0QWg00vDtlA
