#!/bin/bash
set -e  # stop immediately if any command fails

IMAGE=$1   # passed from the pipeline (the full image name with SHA tag)

if [ -z "$IMAGE" ]; then
  echo "Error: no image provided"
  exit 1
fi

echo "==> Pulling image: $IMAGE"
docker pull $IMAGE

echo "==> Stopping old container (if exists)"
docker stop app 2>/dev/null || true
docker rm   app 2>/dev/null || true

echo "==> Starting new container"
docker run -d \
  --name app \
  --restart unless-stopped \
  -p 8000:8000 \
  $IMAGE

echo "==> Health check"
sleep 5
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)

if [ "$STATUS" != "200" ]; then
  echo "Health check failed — status $STATUS"
  docker stop app
  exit 1
fi

echo "==> Deploy successful: $IMAGE is live"