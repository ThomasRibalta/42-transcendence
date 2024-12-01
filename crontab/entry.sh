#!/bin/bash

cat <<EOF > /etc/cron.d/mycron
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

* * * * * /usr/local/bin/script.sh >> /var/log/script.log 2>&1
EOF

chmod 0644 /etc/cron.d/mycron
crontab /etc/cron.d/mycron

cron -f
