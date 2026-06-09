#!/usr/bin/env bash
# Genera aws/config.env desde el outputs-file de `cdk deploy --outputs-file`.
# Uso: gen-config-env.sh <cdk-outputs.json> [STACK_NAME]
# La salida por defecto es <repo>/aws/config.env (overridable con CONFIG_ENV_OUT).
set -euo pipefail
JSON="${1:?Uso: gen-config-env.sh <cdk-outputs.json> [STACK_NAME]}"
STACK="${2:-Sara3LoadTestStack}"
OUT="${CONFIG_ENV_OUT:-$(cd "$(dirname "$0")/.." && pwd)/aws/config.env}"

command -v jq >/dev/null 2>&1 || { echo "ERROR: se requiere jq" >&2; exit 1; }

get() { jq -r --arg s "$STACK" --arg k "$1" '.[$s][$k] // empty' "$JSON"; }

AWS_REGION="$(get AwsRegion)"
ECR_IMAGE="$(get EcrImage)"
S3_BUCKET="$(get S3Bucket)"
SUBNET_ID="$(get SubnetId)"
SECURITY_GROUP_ID="$(get SecurityGroupId)"
IAM_INSTANCE_PROFILE="$(get IamInstanceProfile)"
AMI_ID="$(get AmiId)"

for v in AWS_REGION ECR_IMAGE S3_BUCKET SUBNET_ID SECURITY_GROUP_ID IAM_INSTANCE_PROFILE AMI_ID; do
  [ -n "${!v}" ] || { echo "ERROR: falta el output $v en $JSON (stack $STACK)" >&2; exit 1; }
done

mkdir -p "$(dirname "$OUT")"
cat > "$OUT" <<EOF
# Generado por infra/gen-config-env.sh desde ${JSON}
AWS_REGION=${AWS_REGION}
ECR_IMAGE=${ECR_IMAGE}
S3_BUCKET=${S3_BUCKET}
INSTANCE_TYPE=r5.4xlarge
AMI_ID=${AMI_ID}
SUBNET_ID=${SUBNET_ID}
SECURITY_GROUP_ID=${SECURITY_GROUP_ID}
IAM_INSTANCE_PROFILE=${IAM_INSTANCE_PROFILE}
INSTANCES=10
RUNNERS=10
EOF
echo "Escrito $OUT"
cat "$OUT"
