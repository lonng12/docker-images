FROM        --platform=$TARGETOS/$TARGETARCH eclipse-temurin:16-jdk-focal

LABEL       author="Robert Jansen" maintainer="rjansengd@gmail.com"

LABEL       org.opencontainers.image.source="https://github.com/mcjars/pterodactyl-yolks"
LABEL       org.opencontainers.image.licenses=MIT

# Gỡ các công cụ không cần thiết và cài đặt các gói cần dùng
RUN         apt-get update -y && \
            apt-get install -y --no-install-recommends \
                curl jq lsof ca-certificates openssl git tar sqlite3 fontconfig libfreetype6 tzdata iproute2 libstdc++6 unzip&& \
            rm -rf /usr/bin/dd /usr/bin/fallocate /usr/bin/truncate /usr/bin/xfs_mkfile && \
            apt-get clean && rm -rf /var/lib/apt/lists/*

# Tải MCAntiMalware
RUN         curl -sSL https://github.com/OpticFusion1/MCAntiMalware/releases/latest/download/MCAntiMalware.jar \
            -o /MCAntiMalware.jar

# Thêm user container
RUN         useradd -d /home/container -m container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

# Copy script entrypoint
COPY        ./../entrypoint.sh /entrypoint.sh
CMD         [ "/bin/bash", "/entrypoint.sh" ]