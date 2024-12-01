FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    cron \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY clean.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

VOLUME /var/log

COPY entry.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
