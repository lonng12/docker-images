#!/bin/bash
REGISTRY="103.176.24.13:5000"

# ===== Pterodactyl Node.js =====
for v in 14 16 17 18 19 20 21 22 23 24 25; do
    echo "====== Building pterodactyl-nodejs$v ======"
    cd /root/pterodactyl-nodejs$v && docker build --compress -t ${REGISTRY}/pterodactyl-nodejs$v:latest . && docker push ${REGISTRY}/pterodactyl-nodejs$v:latest
done
echo "====== ALL BUILDS COMPLETE ======"
