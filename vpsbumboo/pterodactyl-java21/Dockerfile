FROM ubuntu:24.04

ARG TARGETPLATFORM
ARG GRAAL_VERSION=21.0.2
ARG JAVA_VERSION=21

LABEL maintainer="RikoDEV <kontakt@riko.dev>" 

ENV DEBIAN_FRONTEND=noninteractive


# Default to UTF-8 file.encoding
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update -y && \
    apt-get install -y curl jq lsof ca-certificates openssl git tar sqlite3 fontconfig libfreetype6 tzdata iproute2 libstdc++6 locales unzip && \
    rm -rf /usr/bin/dd /usr/bin/fallocate /usr/bin/truncate /usr/bin/xfs_mkfile && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    case ${TARGETPLATFORM} in \
        "linux/amd64") ARCH=x64 ;; \
        "linux/arm64") ARCH=aarch64 ;; \
    esac && \
    curl --retry 3 -Lfso /tmp/graalvm.tar.gz https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAAL_VERSION}/graalvm-community-jdk-${GRAAL_VERSION}_linux-${ARCH}_bin.tar.gz && \
    mkdir -p /opt/java/graalvm && \
    cd /opt/java/graalvm && \
    tar -xf /tmp/graalvm.tar.gz --strip-components=1 && \
    export PATH="/opt/java/graalvm/bin:$PATH" && \
    rm -rf /tmp/graalvm.tar.gz


ENV JAVA_HOME=/opt/java/graalvm \
    PATH="/opt/java/graalvm/bin:$PATH"
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