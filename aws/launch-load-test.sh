#!/usr/bin/env bash
# Orquestador de prueba de carga en EC2 (spot por defecto).
# Uso:
#   launch-load-test.sh [--instances N] [--runners M] [--on-demand] [--dry-run]
#   launch-load-test.sh --download <RUN_ID>
#   launch-load-test.sh --kill
# --on-demand: usa instancias on-demand (sin spot). Util si la cuenta no tiene el
#   service-linked role de spot (AWSServiceRoleForEC2Spot).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# Defaults (sobreescribibles por config.env / flags)
INSTANCES=10
RUNNERS=10
DRY_RUN=false
ACTION="launch"
DOWNLOAD_RUN_ID=""
MAX_CLASSES=10
SPOT=true

# Cargar config si existe
[ -f "$HERE/config.env" ] && source "$HERE/config.env"

while [ $# -gt 0 ]; do
  case "$1" in
    --instances) INSTANCES="$2"; shift 2;;
    --runners) RUNNERS="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    --on-demand) SPOT=false; shift;;
    --download) ACTION="download"; DOWNLOAD_RUN_ID="$2"; shift 2;;
    --kill) ACTION="kill"; shift;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "Opción desconocida: $1" >&2; exit 2;;
  esac
done

require_vars() {
  local missing=()
  for v in "$@"; do [ -n "${!v:-}" ] || missing+=("$v"); done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "ERROR: faltan variables (define aws/config.env): ${missing[*]}" >&2
    exit 1
  fi
}

run_or_echo() {
  if [ "$DRY_RUN" = true ]; then echo "[dry-run] $*"; else eval "$*"; fi
}

if [ "$ACTION" = "kill" ]; then
  require_vars AWS_REGION
  echo "Terminando instancias con tag Project=sara3-loadtest..."
  ids=$(aws ec2 describe-instances --region "$AWS_REGION" \
    --filters "Name=tag:Project,Values=sara3-loadtest" "Name=instance-state-name,Values=pending,running" \
    --query "Reservations[].Instances[].InstanceId" --output text)
  [ -z "$ids" ] && { echo "No hay instancias activas."; exit 0; }
  run_or_echo "aws ec2 terminate-instances --region $AWS_REGION --instance-ids $ids"
  exit 0
fi

if [ "$ACTION" = "download" ]; then
  require_vars AWS_REGION S3_BUCKET
  dest="results/run-${DOWNLOAD_RUN_ID}"
  mkdir -p "$dest"
  run_or_echo "aws s3 cp s3://${S3_BUCKET}/run-${DOWNLOAD_RUN_ID}/ ${dest}/ --recursive"
  [ "$DRY_RUN" = true ] || bash "$HERE/summarize-results.sh" "$dest"
  exit 0
fi

# ACTION = launch
require_vars AWS_REGION ECR_IMAGE S3_BUCKET INSTANCE_TYPE AMI_ID SUBNET_ID SECURITY_GROUP_ID IAM_INSTANCE_PROFILE

NUM_SHARDS=$(( (MAX_CLASSES + RUNNERS - 1) / RUNNERS ))
RUN_ID="$(date -u +%Y%m%d-%H%M%S 2>/dev/null || echo manual)"
MARKET_OPT=""
[ "$SPOT" = true ] && MARKET_OPT="--instance-market-options 'MarketType=spot'"
echo "RUN_ID=$RUN_ID  INSTANCES=$INSTANCES  RUNNERS=$RUNNERS  NUM_SHARDS=$NUM_SHARDS  SPOT=$SPOT"

for i in $(seq 0 $(( INSTANCES - 1 ))); do
  shard=$(( i % NUM_SHARDS ))
  tests_args="$(bash "$HERE/shard-tests.sh" "$shard" "$RUNNERS")"
  ud="$(mktemp)"
  sed -e "s/__AWS_REGION__/${AWS_REGION}/g" \
      -e "s#__ECR_IMAGE__#${ECR_IMAGE}#g" \
      -e "s/__S3_BUCKET__/${S3_BUCKET}/g" \
      -e "s/__RUN_ID__/${RUN_ID}/g" \
      -e "s/__RUNNERS__/${RUNNERS}/g" \
      -e "s/__INSTANCE_ID__/${i}/g" \
      -e "s#__TESTS_ARGS__#${tests_args}#g" \
      "$HERE/user-data.sh.tpl" > "$ud"

  cmd="aws ec2 run-instances --region $AWS_REGION \
    --image-id $AMI_ID --instance-type $INSTANCE_TYPE \
    --subnet-id $SUBNET_ID --security-group-ids $SECURITY_GROUP_ID \
    --no-associate-public-ip-address \
    --iam-instance-profile Name=$IAM_INSTANCE_PROFILE \
    --instance-initiated-shutdown-behavior terminate \
    $MARKET_OPT \
    --user-data file://$ud \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Project,Value=sara3-loadtest},{Key=RunId,Value=$RUN_ID},{Key=Shard,Value=$shard}]'"
  echo "-> instancia $i (shard $shard)"
  run_or_echo "$cmd"
  [ "$DRY_RUN" = true ] && rm -f "$ud"
done

echo "Lanzadas $INSTANCES instancias. Resultados en s3://${S3_BUCKET}/run-${RUN_ID}/"
echo "Para descargar y resumir: $0 --download $RUN_ID"
echo "Para abortar: $0 --kill"
