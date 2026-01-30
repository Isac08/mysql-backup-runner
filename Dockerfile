FROM mysql:8.0-debian

# Install scp (openssh-client) and gzip for compression
RUN apt-get update && apt-get install -y openssh-client gzip && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y moreutils && rm -rf /var/lib/apt/lists/*
RUN apt-get update -y && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
RUN apt-get update -y && apt-get install -y jq && rm -rf /var/lib/apt/lists/*

# Copy script
COPY dump_and_transfer.sh /usr/local/bin/dump_and_transfer.sh
RUN chmod +x /usr/local/bin/dump_and_transfer.sh

ENTRYPOINT ["dump_and_transfer.sh"]
