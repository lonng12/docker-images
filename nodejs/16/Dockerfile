FROM        --platform=$TARGETOS/$TARGETARCH node:16-bullseye-slim
LABEL       author="Michael Parker" maintainer="parker@pterodactyl.io"
RUN         useradd -m -d /home/container container
STOPSIGNAL  SIGINT
RUN         echo "deb http://archive.debian.org/debian bullseye main contrib non-free" > /etc/apt/sources.list \
            && echo "deb http://archive.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list \
            && apt-get -o Acquire::Check-Valid-Until=false update \
            && apt-get -o Acquire::Check-Valid-Until=false -y install --no-install-recommends \
                iproute2 \
                git \
                sqlite3 \
                libsqlite3-dev \
                python3 \
                python3-dev \
                ca-certificates \
                dnsutils \
                tzdata \
                zip \
                tar \
                curl \
                build-essential \
                libtool \
                iputils-ping \
                libnss3 \
                tini \
            && rm -rf /var/lib/apt/lists/*
RUN         npm install --global npm@9 typescript ts-node @types/node
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container
COPY        --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]