#!/usr/bin/env bash
set -euxo pipefail
# Marcadores inyectados por launch-load-test.sh:
REGION="__AWS_REGION__"
IMAGE="__ECR_IMAGE__"
BUCKET="__S3_BUCKET__"
RUN_ID="__RUN_ID__"
RUNNERS="__RUNNERS__"
INSTANCE_ID="__INSTANCE_ID__"
TESTS_ARGS='__TESTS_ARGS__'

# Asegurar Docker
if ! command -v docker >/dev/null 2>&1; then
  yum install -y docker 2>/dev/null || amazon-linux-extras install -y docker 2>/dev/null || { apt-get update && apt-get install -y docker.io; }
fi
systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true

# Login ECR + pull
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${IMAGE%%/*}"
docker pull "$IMAGE"

mkdir -p /tmp/out/target /tmp/out/logs

# Registrar la IP publica de SALIDA de esta instancia (para whitelisting en la app).
# En subred publica, esta IP es la misma con la que la instancia llega a la app.
EGRESS_IP="$(curl -s --max-time 10 https://checkip.amazonaws.com 2>/dev/null || echo unknown)"
echo "EGRESS_IP=${EGRESS_IP}" | tee /tmp/out/logs/egress_ip.txt

# Ejecutar el shard (RUNNERS forks en paralelo)
set +e
docker run --rm \
  --shm-size=4g \
  -v /tmp/out/target:/app/target \
  -v /tmp/out/logs:/app/logs \
  "$IMAGE" \
  "./gradlew test --continue --max-workers=${RUNNERS} -PmaxParallelForks=${RUNNERS} ${TESTS_ARGS}" \
  > "/tmp/out/logs/instance-${INSTANCE_ID}.log" 2>&1
RC=$?
set -e

# Subir resultados a S3
DEST="s3://${BUCKET}/run-${RUN_ID}/instance-${INSTANCE_ID}/"
aws s3 cp /tmp/out/logs/ "$DEST" --recursive || true
aws s3 cp /tmp/out/target/site/ "${DEST}site/" --recursive || true
printf 'exit_code=%s\n' "$RC" | aws s3 cp - "${DEST}exit_code.txt" || true

# Auto-terminar
shutdown -h now
