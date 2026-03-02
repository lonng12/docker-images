#!/bin/bash
# Build all Docker images and push to registry
# Đã xoá các image adoptium, thêm aio builds

REGISTRY="103.176.24.13:5000"

build_push() {
    local dir="$1"
    local tag="$2"
    echo "====== Building $tag ======"
    cd "$dir" && docker build --compress -t ${REGISTRY}/${tag}:latest . && docker push ${REGISTRY}/${tag}:latest
}

# ===== Python =====
build_push /root/python/3.7 python3.7
build_push /root/python/3.8 python3.8
build_push /root/python/3.9 python3.9
build_push /root/python/3.10 python3.10
build_push /root/python/3.11 python3.11
build_push /root/python/3.12 python3.12
build_push /root/python/3.13 python3.13

# ===== Pterodactyl Java (không có adoptium) =====
build_push /root/pterodactyl-java8 pterodactyl-java8
build_push /root/pterodactyl-java11 pterodactyl-java11
build_push /root/pterodactyl-java16 pterodactyl-java16
build_push /root/pterodactyl-java17 pterodactyl-java17
build_push /root/pterodactyl-java18 pterodactyl-java18
build_push /root/pterodactyl-java19 pterodactyl-java19
build_push /root/pterodactyl-java21 pterodactyl-java21
build_push /root/pterodactyl-java22 pterodactyl-java22
build_push /root/pterodactyl-java23 pterodactyl-java23
build_push /root/pterodactyl-java24 pterodactyl-java24
build_push /root/pterodactyl-java25 pterodactyl-java25

# ===== VPSBumboo (không có adoptium) =====
build_push /root/vpsbumboo/pterodactyl-java8 pterodactyl-java8-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java11 pterodactyl-java11-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java16 pterodactyl-java16-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java17 pterodactyl-java17-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java18 pterodactyl-java18-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java19 pterodactyl-java19-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java21 pterodactyl-java21-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java22 pterodactyl-java22-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java23 pterodactyl-java23-vpsbumboo
build_push /root/vpsbumboo/pterodactyl-java25 pterodactyl-java25-vpsbumboo

# ===== Node.js =====
for v in 12 14 16 17 18 19 20 21 22 23 24; do
    build_push /root/nodejs/$v nodejs$v
done

# ===== Pterodactyl Node.js =====
for v in 14 16 17 18 19 20 21 22 23 24 25; do
    build_push /root/pterodactyl-nodejs$v pterodactyl-nodejs$v
done

echo "====== ALL BUILDS COMPLETE ======"
