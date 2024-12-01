FROM docker.elastic.co/elasticsearch/elasticsearch:8.12.2

# Switch to root user to install additional packages
USER root

# Install curl
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Copy your Elasticsearch configuration
COPY elasticsearch.yml /usr/share/elasticsearch/config/

# Copy custom initialization scripts
COPY create_users.sh /usr/local/bin/create_users.sh
COPY init_ilm.sh /usr/local/bin/init_ilm.sh
COPY startup.sh /usr/local/bin/startup.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/*.sh

# Switch back to the Elasticsearch user
USER elasticsearch

# Use the custom startup script
ENTRYPOINT ["/usr/local/bin/startup.sh"]
