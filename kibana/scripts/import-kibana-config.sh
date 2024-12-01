#!/bin/bash

echo "$(date) Waiting for Kibana to be ready..."

# Wait for Kibana to be available
until curl -s -o /dev/null "http://kibana:5601/kibana/api/status"; do
  sleep 5
done

echo "$(date) Kibana is ready. Importing configuration..."

# Define variables
KIBANA_URL="http://kibana:5601/kibana"
FILE_PATH="/usr/share/kibana/config/nginx_access.ndjson"

# Perform the import
curl -X POST "$KIBANA_URL/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: multipart/form-data" \
  --form file=@$FILE_PATH

echo "$(date) Kibana configuration imported successfully!"
