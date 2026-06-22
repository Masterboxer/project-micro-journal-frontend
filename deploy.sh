#!/bin/bash

set -e

flutter build web --release --base-href /app/

rm -rf /home/masterboxer/reflecto-website/app

mkdir -p /home/masterboxer/reflecto-website/app

cp -r build/web/* /home/masterboxer/reflecto-website/app/

sudo systemctl restart nginx

echo "Deployment complete!"