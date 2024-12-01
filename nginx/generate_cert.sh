#!/bin/sh

mkdir -p /etc/nginx/ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt \
  -subj "/C=FR/ST=Paris/L=Paris/O=Dev/OU=IT Department/CN=localhost"

openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
