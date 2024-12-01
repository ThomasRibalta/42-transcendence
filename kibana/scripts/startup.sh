#!/bin/bash

# Start Kibana in the background using the default command
/usr/local/bin/kibana-docker &

# Wait for Kibana to be ready
echo "$(date) Waiting for Kibana to be ready..."
until curl -s -o /dev/null "http://localhost:5601/api/status"; do
  sleep 5
done

sleep 30  # Additional wait time if necessary
echo "$(date) Kibana is ready. Importing configuration..."

# Run the import script
/usr/share/kibana/scripts/import-kibana-config.sh

# Wait for Kibana process to exit
wait -n
