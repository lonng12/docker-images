# Build Node.js
for v in 12 14 16 17 18 19 20 21 22 23 24; do
    echo "====== Building nodejs$v ======"
    cd /root/nodejs/$v && docker build --compress -t 103.176.24.13:5000/nodejs$v:latest . && docker push 103.176.24.13:5000/nodejs$v:latest
done
# Build Pterodactyl Node.js
for v in 14 16 17 18 19 20 21 22 23 24 25; do
    echo "====== Building pterodactyl-nodejs$v ======"
    cd /root/pterodactyl-nodejs$v && docker build --compress -t 103.176.24.13:5000/pterodactyl-nodejs$v:latest . && docker push 103.176.24.13:5000/pterodactyl-nodejs$v:latest
done
echo "====== DONE ======"
