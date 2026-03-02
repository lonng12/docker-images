# ----------------------------------
# Pterodactyl Core Dockerfile
# Environment: Java 25 (GraalVM)
# Minimum Panel Version: 1.7.0
# Updated: Feb 2026
# ----------------------------------
FROM ubuntu:24.04

ARG TARGETPLATFORM
# Cập nhật phiên bản GraalVM phù hợp với JDK 25
ARG GRAAL_VERSION=25.0.0
ARG JAVA_VERSION=25

LABEL maintainer="RikoDEV <kontakt@riko.dev>" 

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
     curl jq lsof ca-certificates openssl git tar sqlite3 fontconfig \
     libfreetype6 tzdata iproute2 libstdc++6 locales unzip \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_US.UTF-8 \
  && case ${TARGETPLATFORM} in \
         "linux/amd64")  ARCH=x64  ;; \
         "linux/arm64")  ARCH=aarch64  ;; \
         *) ARCH=x64 ;; \
    esac \
  && curl --retry 3 -Lfso /tmp/graalvm.tar.gz https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAAL_VERSION}/graalvm-community-jdk-${GRAAL_VERSION}_linux-${ARCH}_bin.tar.gz \
  && mkdir -p /opt/java/graalvm \
  && cd /opt/java/graalvm \
  && tar -xf /tmp/graalvm.tar.gz --strip-components=1 \
  && export PATH="/opt/java/graalvm/bin:$PATH" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/graalvm.tar.gz

ENV JAVA_HOME=/opt/java/graalvm \
    PATH="/opt/java/graalvm/bin:$PATH"

# Tải công cụ kiểm tra Malware cho Minecraft (nếu vẫn cần thiết)
RUN curl -sSL https://github.com/OpticFusion1/MCAntiMalware/releases/latest/download/MCAntiMalware.jar \
    -o /MCAntiMalware.jar

# Thiết lập người dùng cho Pterodactyl
RUN useradd -d /home/container -m container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Đảm bảo file entrypoint có quyền thực thi
COPY ./../entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]