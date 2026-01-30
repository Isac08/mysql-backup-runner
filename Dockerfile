FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    default-mysql-client \
    openssh-client \
    gzip \
    moreutils \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY dump_and_transfer.sh /usr/local/bin/dump_and_transfer.sh
RUN chmod +x /usr/local/bin/dump_and_transfer.sh

ENTRYPOINT ["dump_and_transfer.sh"]