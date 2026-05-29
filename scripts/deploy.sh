#!/bin/bash
set -e
source /home/ec2-user/ci-cd-project/deploy.env
IMAGE_TAG=$1

if [ -z "$IMAGE_TAG" ]; then
  echo "Error: no image tag provided"
  exit 1
fi

NGINX_CONF="/etc/nginx/conf.d/devopstester.conf"
REPO="alaaromdhani/ci-cd-project"

# ── Detect live and idle slots ────────────────────────────────────────────────
CURRENT_PORT=$(grep "localhost:" $NGINX_CONF | grep -o '[0-9]*;' | tr -d ';')

if [ "$CURRENT_PORT" = "8000" ]; then
  LIVE_SLOT="blue"
  IDLE_SLOT="green"
  IDLE_PORT=8001
else
  LIVE_SLOT="green"
  IDLE_SLOT="blue"
  IDLE_PORT=8000
fi
echo $GITHUB_TOKEN;
IDLE_DIR="/home/ec2-user/ci-cd-project/app-$IDLE_SLOT"

echo "================================================"
echo "  LIVE    : app-$LIVE_SLOT  on port $CURRENT_PORT"
echo "  DEPLOYING TO : app-$IDLE_SLOT on port $IDLE_PORT"
echo "================================================"

# ── Pull latest code into idle slot ──────────────────────────────────────────
echo ""
echo "==> Pulling latest code into $IDLE_DIR"
cd $IDLE_DIR
git pull origin staging

# ── Update image tag in .env ──────────────────────────────────────────────────
echo "==> Setting image tag to $IMAGE_TAG"
sed -i "s/IMAGE_TAG=.*/IMAGE_TAG=$IMAGE_TAG/" $IDLE_DIR/.env

# ── Login to GHCR ─────────────────────────────────────────────────────────────
echo "==> Logging into GHCR by TTy"
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin
# from where $GITHUB_ACTOR come from 
# ── Pull new image ────────────────────────────────────────────────────────────
echo "==> Pulling image: ghcr.io/$REPO:$IMAGE_TAG"
docker pull ghcr.io/$REPO:$IMAGE_TAG

# ── Start new version with Docker Compose ────────────────────────────────────
echo "==> Starting app-$IDLE_SLOT with Docker Compose"
cd $IDLE_DIR
docker compose down 2>/dev/null || true
docker compose up -d

# ── Health check ──────────────────────────────────────────────────────────────
echo "==> Health checking app-$IDLE_SLOT on port $IDLE_PORT"
PASSED=false
for i in {1..10}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$IDLE_PORT/health)
  if [ "$STATUS" = "200" ]; then
    PASSED=true
    echo "    Attempt $i — passed ✅"
    break
  fi
  echo "    Attempt $i — status $STATUS — retrying in 5s"
  sleep 5
done

# ── Abort if unhealthy ────────────────────────────────────────────────────────
if [ "$PASSED" = "false" ]; then
  echo ""
  echo "==> Health check failed — aborting deploy"
  echo "==> app-$LIVE_SLOT is still live on port $CURRENT_PORT — untouched"
  docker compose down
  exit 1
fi

# ── Switch Nginx ──────────────────────────────────────────────────────────────
echo "==> Switching Nginx → port $IDLE_PORT"
sed -i "s/server localhost:[0-9]*/server localhost:$IDLE_PORT/" $NGINX_CONF
nginx -t && systemctl reload nginx

echo ""
echo "================================================"
echo "  LIVE    : app-$IDLE_SLOT on port $IDLE_PORT ✅"
echo "  STANDBY : app-$LIVE_SLOT on port $CURRENT_PORT (running, rollback ready)"
echo "  To rollback: bash /opt/rollback.sh"
echo "================================================"