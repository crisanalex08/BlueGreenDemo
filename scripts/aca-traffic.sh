#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 crisan-devops crisan-bluegreen-ca"
  exit 1
fi

RESOURCE_GROUP="$1"
CONTAINER_APP_NAME="$2"

echo "\nActive revisions:"
az containerapp revision list \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_APP_NAME" \
  --query "sort_by([].{name:name,active:properties.active,created:properties.createdTime}, &created)" \
  -o table

echo "\nTraffic weights:"
az containerapp ingress traffic show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_APP_NAME" \
  -o table
