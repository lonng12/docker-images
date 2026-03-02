FROM node:23-bookworm-slim

ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get upgrade -y \
    && apt-get -y install iptables apt-utils curl ffmpeg software-properties-common apt-transport-https ca-certificates wget dirmngr gnupg iproute2 sqlite3 libopus0 make g++ locales git cmake zip unzip libtool-bin autoconf automake curl jq \
    && useradd -d /home/container -m container

        # Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

        # NodeJS
RUN npm install -g nodemon && nodemon -v
RUN npm install -g coffeescript typescript node-gyp
RUN apt-get update && apt-get -y install dnsutils python3 build-essential
COPY ./start.sh /start.sh
RUN chmod +x /start.sh
RUN apt clean \
    && rm -rf /var/cache/apt/archives \
    && rm -rf /var/lib/apt/lists/*

USER container
ENV  USER container
ENV  HOME /home/container

WORKDIR /home/container
COPY ./entrypoint.sh /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]
