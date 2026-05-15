#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./scripts/bootstrap-azure.sh <resource-group> <location> <acr-name> <env-name> <app-name>

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <resource-group> <location> <acr-name> <env-name> <app-name>"
  exit 1
fi

RESOURCE_GROUP="$1"
LOCATION="$2"
ACR_NAME="$3"
ENV_NAME="$4"
APP_NAME="$5"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
az acr create --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME" --sku Basic --admin-enabled true
az containerapp env create --name "$ENV_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION"

ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query loginServer -o tsv)
ACR_USER=$(az acr credential show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query username -o tsv)
ACR_PASS=$(az acr credential show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query passwords[0].value -o tsv)

az containerapp create \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$ENV_NAME" \
  --ingress external \
  --target-port 8080 \
  --revisions-mode multiple \
  --image "$ACR_LOGIN_SERVER/bluegreen-api:initial" \
  --registry-server "$ACR_LOGIN_SERVER" \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --env-vars VERSION=v1 ENVIRONMENT=blue FAIL_HEALTHCHECK=false

echo "Bootstrap complete."
