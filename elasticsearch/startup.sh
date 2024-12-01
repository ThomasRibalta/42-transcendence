#!/bin/bash

# Start Elasticsearch in the background
/usr/local/bin/docker-entrypoint.sh &

# Wait for Elasticsearch to start
echo "Waiting for Elasticsearch to start..."
until curl -s -k http://localhost:9200 >/dev/null; do
  sleep 5
done

# Run custom scripts
echo "Running create_users.sh..."
/usr/local/bin/create_users.sh

echo "Running init_ilm.sh..."
/usr/local/bin/init_ilm.sh

# Bring Elasticsearch to the foreground
wait -n
