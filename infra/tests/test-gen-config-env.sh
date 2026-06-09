#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
GEN="$here/../gen-config-env.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/out.json" <<'JSON'
{ "Sara3LoadTestStack": {
  "AwsRegion": "us-east-1",
  "EcrImage": "111.dkr.ecr.us-east-1.amazonaws.com/cdk:abc",
  "S3Bucket": "bkt",
  "SubnetId": "subnet-123",
  "SecurityGroupId": "sg-123",
  "IamInstanceProfile": "prof-123",
  "AmiId": "ami-123"
} }
JSON

CONFIG_ENV_OUT="$tmp/config.env" bash "$GEN" "$tmp/out.json" >/dev/null

grep -q '^AWS_REGION=us-east-1$' "$tmp/config.env" || { echo "FAIL AWS_REGION"; cat "$tmp/config.env"; exit 1; }
grep -q '^ECR_IMAGE=111.dkr.ecr.us-east-1.amazonaws.com/cdk:abc$' "$tmp/config.env" || { echo "FAIL ECR_IMAGE"; exit 1; }
grep -q '^S3_BUCKET=bkt$' "$tmp/config.env" || { echo "FAIL S3_BUCKET"; exit 1; }
grep -q '^SUBNET_ID=subnet-123$' "$tmp/config.env" || { echo "FAIL SUBNET_ID"; exit 1; }
grep -q '^SECURITY_GROUP_ID=sg-123$' "$tmp/config.env" || { echo "FAIL SG"; exit 1; }
grep -q '^IAM_INSTANCE_PROFILE=prof-123$' "$tmp/config.env" || { echo "FAIL PROFILE"; exit 1; }
grep -q '^AMI_ID=ami-123$' "$tmp/config.env" || { echo "FAIL AMI"; exit 1; }
grep -q '^INSTANCE_TYPE=r5.4xlarge$' "$tmp/config.env" || { echo "FAIL INSTANCE_TYPE"; exit 1; }
grep -q '^INSTANCES=10$' "$tmp/config.env" || { echo "FAIL INSTANCES"; exit 1; }
grep -q '^RUNNERS=10$' "$tmp/config.env" || { echo "FAIL RUNNERS"; exit 1; }
echo "OK gen-config-env"
