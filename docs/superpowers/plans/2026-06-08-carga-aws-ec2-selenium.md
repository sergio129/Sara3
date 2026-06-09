# Prueba de carga en AWS (EC2 spot + Selenium) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear el tooling (`aws/`) para lanzar una flota de EC2 spot que ejecuta los runners Selenium en paralelo (10 instancias × 10 runners = 100 sesiones concurrentes), sube resultados a S3 y consolida un resumen de carga.

**Architecture:** Scripts Bash + AWS CLI. Un orquestador (`launch-load-test.sh`) lanza N instancias spot; cada una corre un `user-data` que baja la imagen desde ECR, ejecuta su shard de clases con `-PmaxParallelForks`, sube reportes a S3 y se auto-termina. Helpers puros (sharding, consolidación) son testeables localmente; la corrida real en AWS es una tarea manual gated.

**Tech Stack:** Bash, AWS CLI v2 (EC2 spot, ECR, S3, IAM), Docker, Gradle/Serenity.

**Nota sobre verificación:** La lógica pura (sharding, resumen) se prueba con tests Bash locales (TDD). Los scripts de infraestructura se validan con `bash -n` y un modo `--dry-run` que imprime los comandos AWS sin ejecutarlos. La corrida real contra AWS + la app destino es una tarea manual que requiere cuenta AWS y autorización (Task 6).

---

## Estructura de archivos

- Create: `aws/shard-tests.sh` — genera los argumentos `--tests` de Gradle para un shard.
- Create: `aws/tests/test-shard-tests.sh` — test local del sharding.
- Create: `aws/summarize-results.sh` — consolida los logs descargados en un CSV.
- Create: `aws/tests/test-summarize-results.sh` — test local del resumen con fixtures.
- Create: `aws/user-data.sh.tpl` — script de arranque por instancia (plantilla).
- Create: `aws/launch-load-test.sh` — orquestador (lanza, descarga, resume, `--kill`).
- Create: `aws/config.env.example` — parámetros AWS (región, ECR, S3, AMI, subred, SG, IAM).
- Create: `aws/README.md` — precondiciones y uso.

Todos los `.sh` se crean con permiso de ejecución (`chmod +x`).

---

## Task 1: Helper de sharding (`aws/shard-tests.sh`)

**Files:**
- Create: `aws/shard-tests.sh`
- Test: `aws/tests/test-shard-tests.sh`

**Contexto:** Gradle paraleliza clases distintas. El shard `s` cubre las clases
`[s*PER+1 .. s*PER+PER]` (con `PER`=runners por instancia, default 10),
limitando a la clase 50 (hay 50 `CasesRunner`). El paquete es
`com.sara.automation.runners`.

- [ ] **Step 1: Escribir el test que falla**

Crear `aws/tests/test-shard-tests.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
ST="$here/../shard-tests.sh"

out0=$("$ST" 0 10)
echo "$out0" | grep -q 'CasesRunner01"' || { echo "FAIL: shard0 sin 01"; exit 1; }
echo "$out0" | grep -q 'CasesRunner10"' || { echo "FAIL: shard0 sin 10"; exit 1; }
if echo "$out0" | grep -q 'CasesRunner11"'; then echo "FAIL: shard0 incluye 11"; exit 1; fi

out4=$("$ST" 4 10)
echo "$out4" | grep -q 'CasesRunner41"' || { echo "FAIL: shard4 sin 41"; exit 1; }
echo "$out4" | grep -q 'CasesRunner50"' || { echo "FAIL: shard4 sin 50"; exit 1; }

out_small=$("$ST" 1 2)
echo "$out_small" | grep -q 'CasesRunner03"' || { echo "FAIL: shard1/PER2 sin 03"; exit 1; }
echo "$out_small" | grep -q 'CasesRunner04"' || { echo "FAIL: shard1/PER2 sin 04"; exit 1; }

out_hi=$("$ST" 9 10)   # 91..100 -> todo >50 -> vacío
[ -z "$out_hi" ] || { echo "FAIL: shard9 deberia ser vacio"; exit 1; }

echo "OK shard-tests"
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `bash aws/tests/test-shard-tests.sh`
Expected: FALLA (p. ej. "No such file or directory" porque `shard-tests.sh` no existe aún).

- [ ] **Step 3: Implementar `aws/shard-tests.sh`**

```bash
#!/usr/bin/env bash
# Genera los argumentos --tests de Gradle para un shard dado.
# Uso: shard-tests.sh <SHARD> [PER]
#   SHARD: 0-based; el shard s cubre las clases [s*PER+1 .. s*PER+PER]
#   PER: clases por shard (default 10). Se limita a la clase 50.
set -euo pipefail

SHARD="${1:?Uso: shard-tests.sh <SHARD> [PER]}"
PER="${2:-10}"
PKG="com.sara.automation.runners"
MAX=50

start=$(( SHARD * PER + 1 ))
end=$(( SHARD * PER + PER ))

args=""
for n in $(seq "$start" "$end"); do
  [ "$n" -gt "$MAX" ] && break
  printf -v cls "CasesRunner%02d" "$n"
  args+=" --tests \"${PKG}.${cls}\""
done
echo "${args# }"
```

- [ ] **Step 4: Dar permiso de ejecución y correr el test**

Run: `chmod +x aws/shard-tests.sh aws/tests/test-shard-tests.sh && bash aws/tests/test-shard-tests.sh`
Expected: `OK shard-tests`

- [ ] **Step 5: Commit**

```bash
git add aws/shard-tests.sh aws/tests/test-shard-tests.sh
git commit -m "feat(aws): helper de sharding de runners para carga

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Consolidación de resultados (`aws/summarize-results.sh`)

**Files:**
- Create: `aws/summarize-results.sh`
- Test: `aws/tests/test-summarize-results.sh`

**Contexto:** Tras descargar los reportes de S3 a un directorio con subcarpetas
`instance-<id>/` (cada una con un `.log`), generar un CSV con columnas
`instance,tests_completed,tests_failed,timeouts`. El log de Gradle contiene una
línea tipo `50 tests completed, 4 failed`; los timeouts se cuentan por
`TimeoutException`.

- [ ] **Step 1: Escribir el test que falla**

Crear `aws/tests/test-summarize-results.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
SUM="$here/../summarize-results.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/instance-0" "$tmp/instance-1"
cat > "$tmp/instance-0/run.log" <<'LOG'
> Task :test
50 tests completed, 4 failed
org.openqa.selenium.TimeoutException: ...
org.openqa.selenium.TimeoutException: ...
LOG
cat > "$tmp/instance-1/run.log" <<'LOG'
> Task :test
10 tests completed, 0 failed
LOG

out="$tmp/summary.csv"
bash "$SUM" "$tmp" "$out" >/dev/null

grep -q "^instance-0,50,4,2$" "$out" || { echo "FAIL: fila instance-0 incorrecta"; cat "$out"; exit 1; }
grep -q "^instance-1,10,0,0$" "$out" || { echo "FAIL: fila instance-1 incorrecta"; cat "$out"; exit 1; }
echo "OK summarize-results"
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `bash aws/tests/test-summarize-results.sh`
Expected: FALLA (`summarize-results.sh` no existe).

- [ ] **Step 3: Implementar `aws/summarize-results.sh`**

```bash
#!/usr/bin/env bash
# Consolida los logs descargados en un CSV resumen.
# Uso: summarize-results.sh <RESULTS_DIR> [OUT_CSV]
set -euo pipefail
DIR="${1:?Uso: summarize-results.sh <RESULTS_DIR> [OUT_CSV]}"
OUT="${2:-${DIR}/summary.csv}"

echo "instance,tests_completed,tests_failed,timeouts" > "$OUT"
for d in "$DIR"/instance-*/; do
  [ -d "$d" ] || continue
  inst="$(basename "$d")"
  log="$(find "$d" -name '*.log' | head -1 || true)"
  if [ -z "$log" ]; then
    echo "${inst},NA,NA,NA" >> "$OUT"
    continue
  fi
  line="$(grep -oE '[0-9]+ tests completed, [0-9]+ failed' "$log" | tail -1 || true)"
  completed="$(printf '%s' "$line" | grep -oE '^[0-9]+' || echo 0)"
  failed="$(printf '%s' "$line" | grep -oE '[0-9]+ failed' | grep -oE '^[0-9]+' || echo 0)"
  timeouts="$(grep -c 'TimeoutException' "$log" || true)"
  echo "${inst},${completed:-0},${failed:-0},${timeouts:-0}" >> "$OUT"
done
cat "$OUT"
```

- [ ] **Step 4: Dar permiso y correr el test**

Run: `chmod +x aws/summarize-results.sh aws/tests/test-summarize-results.sh && bash aws/tests/test-summarize-results.sh`
Expected: `OK summarize-results`

- [ ] **Step 5: Commit**

```bash
git add aws/summarize-results.sh aws/tests/test-summarize-results.sh
git commit -m "feat(aws): consolidacion de resultados de carga en CSV

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Plantilla `user-data` por instancia (`aws/user-data.sh.tpl`)

**Files:**
- Create: `aws/user-data.sh.tpl`

**Contexto:** El orquestador sustituye los marcadores `__VAR__` y pasa el
resultado como `user-data`. Corre en cada instancia al arrancar: asegura Docker,
login a ECR, `docker run` del shard (comando como string único porque el
entrypoint hace `bash -c "$@"`), sube a S3 y se auto-termina.

- [ ] **Step 1: Crear la plantilla**

```bash
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

# Ejecutar el shard (RUNNERS forks en paralelo)
set +e
docker run --rm \
  -v /tmp/out/target:/app/target \
  -v /tmp/out/logs:/app/logs \
  "$IMAGE" \
  "./gradlew test --continue -PmaxParallelForks=${RUNNERS} ${TESTS_ARGS}" \
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
```

- [ ] **Step 2: Validar que la plantilla, ya sustituida, es bash válido**

Run:
```bash
sed -e 's/__AWS_REGION__/us-east-1/' \
    -e 's#__ECR_IMAGE__#123456789012.dkr.ecr.us-east-1.amazonaws.com/sara3:latest#' \
    -e 's/__S3_BUCKET__/mi-bucket/' \
    -e 's/__RUN_ID__/test123/' \
    -e 's/__RUNNERS__/10/' \
    -e 's/__INSTANCE_ID__/0/' \
    -e 's/__TESTS_ARGS__/--tests "x.Y"/' \
    aws/user-data.sh.tpl | bash -n -
```
Expected: sin salida (sintaxis válida, exit 0).

- [ ] **Step 3: Commit**

```bash
git add aws/user-data.sh.tpl
git commit -m "feat(aws): plantilla user-data para instancia de carga

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Orquestador (`aws/launch-load-test.sh`)

**Files:**
- Create: `aws/launch-load-test.sh`

**Contexto:** Lee `aws/config.env` (creado en Task 5; en `--dry-run` usa valores
de ejemplo si falta). Por cada instancia `i` calcula `shard = i % NUM_SHARDS`
(con `NUM_SHARDS = ceil(50/RUNNERS)`), genera el `user-data` y lanza una spot
etiquetada. Modos: `--dry-run` (imprime los `aws ec2 run-instances` sin
ejecutar), `--download <RUN_ID>` (descarga de S3 + resume), `--kill` (termina por
tag).

- [ ] **Step 1: Crear el orquestador**

```bash
#!/usr/bin/env bash
# Orquestador de prueba de carga en EC2 spot.
# Uso:
#   launch-load-test.sh [--instances N] [--runners M] [--dry-run]
#   launch-load-test.sh --download <RUN_ID>
#   launch-load-test.sh --kill
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# Defaults (sobreescribibles por config.env / flags)
INSTANCES=10
RUNNERS=10
DRY_RUN=false
ACTION="launch"
DOWNLOAD_RUN_ID=""
MAX_CLASSES=50

# Cargar config si existe
[ -f "$HERE/config.env" ] && source "$HERE/config.env"

while [ $# -gt 0 ]; do
  case "$1" in
    --instances) INSTANCES="$2"; shift 2;;
    --runners) RUNNERS="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
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
echo "RUN_ID=$RUN_ID  INSTANCES=$INSTANCES  RUNNERS=$RUNNERS  NUM_SHARDS=$NUM_SHARDS"

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
    --iam-instance-profile Name=$IAM_INSTANCE_PROFILE \
    --instance-initiated-shutdown-behavior terminate \
    --instance-market-options 'MarketType=spot' \
    --user-data file://$ud \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Project,Value=sara3-loadtest},{Key=RunId,Value=$RUN_ID},{Key=Shard,Value=$shard}]'"
  echo "-> instancia $i (shard $shard)"
  run_or_echo "$cmd"
  [ "$DRY_RUN" = true ] && rm -f "$ud"
done

echo "Lanzadas $INSTANCES instancias. Resultados en s3://${S3_BUCKET}/run-${RUN_ID}/"
echo "Para descargar y resumir: $0 --download $RUN_ID"
echo "Para abortar: $0 --kill"
```

- [ ] **Step 2: Validar sintaxis**

Run: `bash -n aws/launch-load-test.sh && echo SINTAXIS_OK`
Expected: `SINTAXIS_OK`

- [ ] **Step 3: Probar `--dry-run` (sin AWS) con config de ejemplo**

Run:
```bash
chmod +x aws/launch-load-test.sh
AWS_REGION=us-east-1 ECR_IMAGE=123.dkr.ecr.us-east-1.amazonaws.com/sara3:latest \
S3_BUCKET=b INSTANCE_TYPE=r5.2xlarge AMI_ID=ami-x SUBNET_ID=subnet-x \
SECURITY_GROUP_ID=sg-x IAM_INSTANCE_PROFILE=role-x \
bash aws/launch-load-test.sh --instances 2 --runners 2 --dry-run
```
Expected: imprime `NUM_SHARDS=25`, dos bloques `[dry-run] aws ec2 run-instances ...` (instancia 0 shard 0, instancia 1 shard 1), sin llamar a AWS.

> Nota: las variables se exportan inline solo para el dry-run; en uso real vienen de `aws/config.env` (Task 5).

- [ ] **Step 4: Commit**

```bash
git add aws/launch-load-test.sh
git commit -m "feat(aws): orquestador de flota EC2 spot para carga (dry-run, download, kill)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Config de ejemplo y README (`aws/config.env.example`, `aws/README.md`)

**Files:**
- Create: `aws/config.env.example`
- Create: `aws/README.md`

**Contexto:** Documentar precondiciones AWS y el uso. `config.env` real lo crea
el usuario copiando el ejemplo (y va al `.gitignore` para no versionar IDs).

- [ ] **Step 1: Crear `aws/config.env.example`**

```bash
# Copia este archivo a aws/config.env y completa los valores.
# (aws/config.env NO se versiona.)
AWS_REGION=us-east-1
# Imagen publicada en ECR (ver README, sección Publicar imagen):
ECR_IMAGE=123456789012.dkr.ecr.us-east-1.amazonaws.com/sara3:latest
# Bucket S3 para resultados (debe existir):
S3_BUCKET=sara3-loadtest-results
# Tipo de instancia (r5.2xlarge: 8 vCPU / 64 GB, holgado para 10 Chrome):
INSTANCE_TYPE=r5.2xlarge
# AMI con Docker (Amazon Linux 2/2023). Si no trae Docker, user-data lo instala:
AMI_ID=ami-xxxxxxxxxxxxxxxxx
# Red con salida a internet:
SUBNET_ID=subnet-xxxxxxxx
SECURITY_GROUP_ID=sg-xxxxxxxx
# Perfil IAM de instancia con permisos: lectura ECR + escritura al bucket S3:
IAM_INSTANCE_PROFILE=sara3-loadtest-instance-profile
# Concurrencia por defecto:
INSTANCES=10
RUNNERS=10
```

- [ ] **Step 2: Añadir `aws/config.env` al `.gitignore`**

Append a `.gitignore`:

```
# Config local de carga AWS (contiene IDs de cuenta)
aws/config.env
results/
```

- [ ] **Step 3: Crear `aws/README.md`**

```markdown
# Prueba de carga en AWS (EC2 spot + Selenium)

Lanza una flota de EC2 spot que ejecuta los runners Selenium en paralelo para
generar carga concurrente contra la app, sube resultados a S3 y consolida un
resumen.

> ⚠️ Genera carga real contra `https://asistenciaapp.kit.sura-konecta.com`.
> Úsalo solo como **testing autorizado** y en **ventana acordada**. Empieza con
> pocas instancias y escala.

## Precondiciones (una vez)

1. **AWS CLI v2** instalado y configurado (`aws configure`).
2. **ECR**: repositorio `sara3`. Publicar la imagen:
   ```bash
   aws ecr create-repository --repository-name sara3 --region <REGION>   # una vez
   aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com
   docker build -t sara3:latest .
   docker tag sara3:latest <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/sara3:latest
   docker push <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/sara3:latest
   ```
3. **S3**: bucket de resultados (`aws s3 mb s3://<bucket>`).
4. **IAM**: rol de instancia (instance profile) con lectura de ECR
   (`AmazonEC2ContainerRegistryReadOnly`) y escritura al bucket S3.
5. **Red**: subred con salida a internet y security group con egress permitido.
6. Copia `aws/config.env.example` a `aws/config.env` y completa los valores.

## Uso

```bash
# Ver qué se lanzaría, sin tocar AWS:
./aws/launch-load-test.sh --instances 2 --runners 2 --dry-run

# Corrida reducida real (4 sesiones concurrentes) para validar el pipeline:
./aws/launch-load-test.sh --instances 2 --runners 2

# Carga objetivo (100 concurrentes):
./aws/launch-load-test.sh --instances 10 --runners 10

# Descargar resultados y generar el CSV resumen:
./aws/launch-load-test.sh --download <RUN_ID>

# Abortar / limpiar instancias colgadas:
./aws/launch-load-test.sh --kill
```

## Modelo de sharding

`shard = índice_instancia % ceil(50/RUNNERS)`. Con `RUNNERS=10` hay 5 shards
(decenas de clases 01-10, 11-20, ...). Con 10 instancias, cada shard corre en 2
instancias a la vez → 100 sesiones concurrentes, cada escenario en 2 máquinas
(ejercita la reutilización de los 50 usuarios).

## Resultados

`s3://<bucket>/run-<RUN_ID>/instance-<id>/` (reporte Serenity + log). El
`--download` los baja a `results/run-<RUN_ID>/` y produce `summary.csv` con
tests completados/fallidos y `TimeoutException` por instancia.
```

- [ ] **Step 4: Verificar**

Run: `test -f aws/config.env.example && grep -q "aws/config.env" .gitignore && grep -q "Sharding" aws/README.md && echo OK`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add aws/config.env.example aws/README.md .gitignore
git commit -m "docs(aws): config de ejemplo, gitignore y README de carga

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6 (MANUAL / gated): Publicar imagen y corrida reducida real

**Files:** ninguno (operación en AWS; requiere cuenta AWS + autorización del dueño de la app)

**Contexto:** Esta tarea SÓLO se ejecuta con: (a) cuenta AWS con credenciales
configuradas, (b) precondiciones de la Task 5 cumplidas, (c) `aws/config.env`
completo, (d) **autorización** para generar carga contra el entorno. NO la
ejecutes automáticamente; requiere confirmación explícita del usuario.

- [ ] **Step 1: Confirmar precondiciones**

Run: `aws sts get-caller-identity && test -f aws/config.env && echo PRECONDICIONES_OK`
Expected: identidad AWS válida + `PRECONDICIONES_OK`.

- [ ] **Step 2: Publicar la imagen en ECR**

Seguir la sección "Precondiciones → ECR" de `aws/README.md` (build, tag, push).
Verify: `aws ecr describe-images --repository-name sara3 --region <REGION>` lista la tag `latest`.

- [ ] **Step 3: Corrida reducida (2×2 = 4 concurrentes)**

Run: `./aws/launch-load-test.sh --instances 2 --runners 2`
Expected: lanza 2 spot; anota el `RUN_ID` impreso.

- [ ] **Step 4: Descargar y revisar**

Run: `./aws/launch-load-test.sh --download <RUN_ID>`
Expected: `results/run-<RUN_ID>/summary.csv` con 2 filas (instance-0, instance-1),
tests completados y conteo de timeouts. Confirmar que las instancias se
auto-terminaron: `./aws/launch-load-test.sh --kill` no debe encontrar activas.

- [ ] **Step 5: Escalar (opcional, bajo autorización)**

Run: `./aws/launch-load-test.sh --instances 10 --runners 10`
Verify: ~100 sesiones concurrentes (timestamps solapados en los 10 logs);
`--download <RUN_ID>` produce el resumen consolidado.

---

## Self-Review

- **Spec coverage:** Task 1 (sharding), Task 2 (consolidación CSV / métricas),
  Task 3 (`user-data`: ECR pull + run + S3 + teardown), Task 4 (orquestador:
  launch/dry-run/download/kill + tags + spot), Task 5 (precondiciones, config,
  README), Task 6 (publicar imagen + corrida reducida y escalado). Cubren
  Arquitectura, Sharding, Resultados, Teardown y Riesgos del spec. Fuera de
  alcance (Terraform, k6, +usuarios, HTML agregado) respetado.
- **Placeholder scan:** sin TBD/TODO reales; los `__VAR__` son marcadores
  intencionales de plantilla (Task 3) y los `<...>` del README son entradas del
  usuario, no del implementador.
- **Type consistency:** nombres consistentes — `shard-tests.sh`,
  `summarize-results.sh`, `user-data.sh.tpl`, `launch-load-test.sh`,
  `config.env`, variables `AWS_REGION/ECR_IMAGE/S3_BUCKET/INSTANCE_TYPE/AMI_ID/
  SUBNET_ID/SECURITY_GROUP_ID/IAM_INSTANCE_PROFILE/INSTANCES/RUNNERS`,
  `RUN_ID`, tag `Project=sara3-loadtest`, ruta S3 `run-<RUN_ID>/instance-<id>/`.
