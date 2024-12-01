# Base image for Kibana
FROM docker.elastic.co/kibana/kibana:8.12.2

# Declare the build-time argument
ARG XPACK_ENCRYPTED_SAVED_OBJECTS_ENCRYPTION_KEY

# Switch to root user for file operations
USER root

# Copy the saved objects file and scripts
COPY ./config/nginx_access.ndjson /usr/share/kibana/config/nginx_access.ndjson
COPY ./scripts/import-kibana-config.sh /usr/share/kibana/scripts/import-kibana-config.sh
COPY ./scripts/startup.sh /usr/local/bin/startup.sh

# Make the scripts executable
RUN chmod +x /usr/share/kibana/scripts/import-kibana-config.sh
RUN chmod +x /usr/local/bin/startup.sh

# Switch back to the Kibana user
USER kibana

# Add the encryption key to the keystore
RUN /usr/share/kibana/bin/kibana-keystore create && \
    echo "$XPACK_ENCRYPTED_SAVED_OBJECTS_ENCRYPTION_KEY" | \
    /usr/share/kibana/bin/kibana-keystore add xpack.encryptedSavedObjects.encryptionKey --stdin
