#!/bin/bash

# Wait until MongoDB is ready
until mongosh --host localhost --port 27017 -u user -p password --authenticationDatabase admin --eval "print(\"waiting for connection\")"; do
    echo "Waiting for MongoDB to start..."
    sleep 5
done

# Create the collection in the database
mongosh --host localhost --port 27017 -u user -p password --authenticationDatabase admin <<EOF
use ft_transcendence_db
db.createCollection('images')
EOF

# Insert the data from data.json
mongosh --host localhost --port 27017 -u user -p password --authenticationDatabase admin <<EOF
use ft_transcendence_db
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('/data.json'));

// Check if the data is an array or a single object
if (Array.isArray(data)) {
  db.images.insertMany(data);
} else {
  db.images.insertOne(data);
}
EOF

echo "Default image(s) added successfully."
