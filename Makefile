APP_NAME=flds

ESP_PROJECT_ID = flds-269622
ESP_PROJECT_NUMBER = 317695325510
CLOUD_RUN_HOSTNAME = ENDPOINTS_HOST gateway-ijzjfv7ydq-ue.a.run.app
CLOUD_RUN_SERVICE_NAME = gateway
CLOUD_RUN_SERVICE_URL = https://gateway-ijzjfv7ydq-ue.a.run.app
SERVICE_CONFIG_ID =  2020-03-01r0 ESP-V2-IMAGE gcr.io/ flds-269622/endpoints-runtime-serverless:gateway-ijzjfv7ydq-ue.a.run.app-2020-03-01r0
BACKEND_SERVICE_NAME = flds
BACKEND_PROJECT_ID = flds-269622   #USE THE SAME ProjectID

REGISTRY_PROJECT_ID = fr-saas-registry

.PHONY: check-env

check-env:
	ifndef GOOGLE_PROJECT_ID
	  $(error GOOGLE_PROJECT_ID is undefined, please make sure these match the environment you are planning to run against)
	endif

# Requires ENV vars to be set for: GOOGLE_PROJECT_ID, CLUSTER_REGION, CLUSTER_NAME
# Suggestion: Make your own .env file to source.

build:
	docker build -t forgecloud/$(APP_NAME):local -f docker/Dockerfile ..


push:
	docker tag forgecloud/$(APP_NAME):local gcr.io/$(REGISTRY_PROJECT_ID)/$(APP_NAME):$(IMAGE_TAG)
	gcloud docker -- push gcr.io/$(REGISTRY_PROJECT_ID)/$(APP_NAME):$(IMAGE_TAG)


flds: go-install
	go run ./cmd/flds


go-install:
	go install cmd/

config: check-env
	gcloud config list
	gcloud config set core/project $(GOOGLE_PROJECT_ID)

lint:
	golangci-lint run ./...  -c golangci-lint_config_base.yml -v --issues-exit-code 0 --deadline 5m0s
