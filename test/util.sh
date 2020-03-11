#!/usr/bin/env bash
set -euo pipefail

get_latest_config_id() {
  # Given a service name, this returns the most recent deployment of that
  # API.
  service_name="$1"
  gcloud endpoints configs list \
    --service="$service_name" \
    --sort-by="~config_id" --limit=1 --format="value(CONFIG_ID)" \
    | tr -d '[:space:]'
}

get_project_id() {
  # Find the project ID first by DEVSHELL_PROJECT_ID (in Cloud Shell)
  # and then by querying the gcloud default project.
  local project="${DEVSHELL_PROJECT_ID:-}"
  if [[ -z "$project" ]]; then
    project=$(gcloud config get-value project 2> /dev/null)
  fi
  if [[ -z "$project" ]]; then
    >&2 echo "No default project was found, and DEVSHELL_PROJECT_ID is not set."
    >&2 echo "Please use the Cloud Shell or set your default project by typing:"
    >&2 echo "gcloud config set project YOUR-PROJECT-NAME"
  fi
  echo "$project"
}
