#!/bin/bash

echo "Waiting for Elasticsearch to start..."
until curl -s -k http://localhost:9200 >/dev/null; do
  sleep 5
done

echo "Setting password for 'elastic' user..."
echo "$ELASTIC_PASSWORD" | /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic --auto -b

echo "Setting password for 'kibana_system' user..."
echo "$KIBANA_PASSWORD" | /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system --auto -b
