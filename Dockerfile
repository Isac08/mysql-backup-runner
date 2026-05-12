FROM debian:bookworm-slim AS base

RUN apt-get update && apt-get install -y \
    default-mysql-client \
    openssh-client \
    gzip \
    moreutils \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

FROM base AS minio
RUN curl -sSL https://dl.min.io/client/mc/release/linux-amd64/mc \
    -o /usr/local/bin/mc &&  \
    chmod +x /usr/local/bin/mc &&  \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY script/dump_minio.sh /usr/local/bin/dump_minio.sh
RUN chmod +x /usr/local/bin/dump_minio.sh
ENTRYPOINT ["dump_minio.sh"]

FROM base AS scp
COPY script/dump_scp.sh /usr/local/bin/dump_scp.sh
RUN chmod +x /usr/local/bin/dump_scp.sh

ENTRYPOINT ["dump_scp.sh"]