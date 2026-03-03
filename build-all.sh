#!/bin/bash
REGISTRY="103.176.24.13:5000"

# ===== Python =====
for v in 3.7 3.8 3.9 3.10 3.11 3.12 3.13; do
    echo "====== Building python$v ======"
    cd /root/python/$v && docker build --compress -t ${REGISTRY}/python$v:latest . && docker push ${REGISTRY}/python$v:latest
done

# ===== Pterodactyl Java =====
for v in 8 11 16 17 18 19 21 22 23 24 25; do
    echo "====== Building pterodactyl-java$v ======"
    cd /root/pterodactyl-java$v && docker build --compress -t ${REGISTRY}/pterodactyl-java$v:latest . && docker push ${REGISTRY}/pterodactyl-java$v:latest
done

# ===== VPSBumboo =====
for v in 8 11 16 17 18 19 21 22 23 25; do
    echo "====== Building pterodactyl-java$v-vpsbumboo ======"
    cd /root/vpsbumboo/pterodactyl-java$v && docker build --compress -t ${REGISTRY}/pterodactyl-java$v-vpsbumboo:latest . && docker push ${REGISTRY}/pterodactyl-java$v-vpsbumboo:latest
done

# ===== Node.js =====
for v in 12 14 16 17 18 19 20 21 22 23 24; do
    echo "====== Building nodejs$v ======"
    cd /root/nodejs/$v && docker build --compress -t ${REGISTRY}/nodejs$v:latest . && docker push ${REGISTRY}/nodejs$v:latest
done

echo "====== ALL BUILDS COMPLETE ======"
