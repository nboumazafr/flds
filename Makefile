include .env
export

APP_NAME=flds
REGISTRY_PROJECT_ID = fr-saas-registry

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

check-env:
	ifndef GOOGLE_PROJECT_ID
	  $(error GOOGLE_PROJECT_ID is undefined, please make sure these match the environment you are planning to run against)
	endif

# Requires ENV vars to be set for: GOOGLE_PROJECT_ID, etc
# Make your own .env file to source.

docker-run: docker-build
	docker run --rm -it -p 7070:7070 flds

docker-build:
	docker build -f Dockerfile -t flds .

deploy-flds-endpoint:
	gcloud endpoints services deploy api/v1/flds.yaml --project flds-269622

cloudrun-deploy-flds:
	./scripts/deploy-flds-to-cloudrun.sh

go-run: go-install
	flds

go-install:
	go install github.com/ForgeCloud/flds

config: check-env
	gcloud config list
	gcloud config set core/project $(GOOGLE_PROJECT_ID)

