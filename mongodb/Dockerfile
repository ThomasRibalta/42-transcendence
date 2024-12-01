FROM mongo:7.0

COPY data.json /data.json
COPY config.sh /docker-entrypoint-initdb.d/

RUN chmod +x /docker-entrypoint-initdb.d/config.sh
