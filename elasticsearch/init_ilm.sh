#!/bin/bash

# Wait for Elasticsearch to start
echo "Waiting for Elasticsearch to start..."
until curl -s -k http://elasticsearch:9200 >/dev/null; do
  sleep 5
done

# Create ILM policy
echo "Creating ILM policy..."
curl -X PUT "http://elasticsearch:9200/_ilm/policy/nginx" \
-H "Content-Type: application/json" \
-d '{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "50gb",
            "max_age": "7d"
          },
          "set_priority": { "priority": 100 }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "allocate": { "number_of_replicas": 1 },
          "set_priority": { "priority": 50 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "freeze": {},
          "set_priority": { "priority": 0 }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'

# Create Index Template
echo "Creating index template..."
curl -X PUT "http://elasticsearch:9200/_index_template/nginx-template" \
-H "Content-Type: application/json" \
-d '{
  "index_patterns": ["nginx-access-logs-*"],
  "template": {
    "settings": {
      "index.lifecycle.name": "nginx",
      "index.lifecycle.rollover_alias": "nginx-access-logs"
    }
  },
  "priority": 100
}'

# Create Initial Index with Alias
echo "Creating initial index and alias..."
curl -X PUT "http://elasticsearch:9200/nginx-access-logs-000001" \
-H "Content-Type: application/json" \
-d '{
  "aliases": {
    "nginx-access-logs": {
      "is_write_index": true
    }
  }
}'

echo "ILM setup completed."
