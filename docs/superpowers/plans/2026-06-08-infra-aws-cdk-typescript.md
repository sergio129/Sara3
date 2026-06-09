# Infra de carga en AWS con CDK (TypeScript) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear un proyecto CDK (TypeScript) bajo `infra/` que provisione la infra durable de la prueba de carga (ECR vía DockerImageAsset, S3, IAM instance profile, security group, VPC default, AMI AL2023) y emita outputs que un script vuelca a `aws/config.env` para el orquestador bash existente.

**Architecture:** Un stack `Sara3LoadTestStack`. La imagen se publica con `DockerImageAsset`; la red usa la VPC default (subred pública). `cdk deploy --outputs-file` + `infra/gen-config-env.sh` generan `aws/config.env`. El orquestador `aws/launch-load-test.sh` no se modifica.

**Tech Stack:** AWS CDK 2.x (TypeScript), Node 22, aws-cdk-lib, bash + jq (script de integración).

**Nota sobre verificación:** Lo offline-testeable: compilación TypeScript (`tsc --noEmit`) y el script `gen-config-env.sh` (test bash, TDD). Lo gated (requiere cuenta AWS + Docker): `cdk bootstrap`, `cdk synth` (DockerImageAsset construye la imagen; `fromLookup` necesita credenciales), `cdk deploy`, la corrida real y `cdk destroy`.

---

## Estructura de archivos

- Create: `infra/package.json` — dependencias y scripts del proyecto CDK.
- Create: `infra/tsconfig.json` — config TypeScript.
- Create: `infra/cdk.json` — entrypoint de la app (ts-node).
- Create: `infra/.gitignore` — node_modules, cdk.out, outputs, context.
- Create: `infra/bin/sara3-loadtest.ts` — instancia la app y el stack.
- Create: `infra/lib/sara3-loadtest-stack.ts` — el stack con los recursos.
- Create: `infra/gen-config-env.sh` — outputs JSON → `aws/config.env`.
- Create: `infra/tests/test-gen-config-env.sh` — test del script.
- Create: `infra/README.md` — flujo de uso.
- Modify: `.gitattributes` — forzar LF también en `infra/**/*.sh`.

---

## Task 1: Scaffold del proyecto CDK TypeScript

**Files:**
- Create: `infra/package.json`, `infra/tsconfig.json`, `infra/cdk.json`, `infra/.gitignore`, `infra/bin/sara3-loadtest.ts`, `infra/lib/sara3-loadtest-stack.ts` (stack mínimo)

**Contexto:** Proyecto CDK estándar con ts-node (sin compilar a JS). El stack se
deja mínimo aquí y se llena en la Task 2, para que `tsc --noEmit` compile desde el
inicio.

- [ ] **Step 1: Crear `infra/package.json`**

```json
{
  "name": "sara3-loadtest-infra",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "synth": "cdk synth",
    "deploy": "cdk deploy --outputs-file cdk-outputs.json",
    "destroy": "cdk destroy",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "aws-cdk": "^2.150.0",
    "ts-node": "^10.9.2",
    "typescript": "~5.5.4"
  },
  "dependencies": {
    "aws-cdk-lib": "^2.150.0",
    "constructs": "^10.3.0"
  }
}
```

- [ ] **Step 2: Crear `infra/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "strict": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "types": ["node"]
  },
  "exclude": ["node_modules", "cdk.out"]
}
```

- [ ] **Step 3: Crear `infra/cdk.json`**

```json
{
  "app": "npx ts-node --prefer-ts-exts bin/sara3-loadtest.ts"
}
```

- [ ] **Step 4: Crear `infra/.gitignore`**

```
node_modules/
cdk.out/
cdk-outputs.json
cdk.context.json
*.js
*.d.ts
```

- [ ] **Step 5: Crear `infra/bin/sara3-loadtest.ts`**

```typescript
#!/usr/bin/env node
import { App } from 'aws-cdk-lib';
import { Sara3LoadTestStack } from '../lib/sara3-loadtest-stack';

const app = new App();
new Sara3LoadTestStack(app, 'Sara3LoadTestStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});
```

- [ ] **Step 6: Crear `infra/lib/sara3-loadtest-stack.ts` (mínimo)**

```typescript
import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';

export class Sara3LoadTestStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);
    // Recursos en Task 2
  }
}
```

- [ ] **Step 7: Instalar dependencias y type-check**

Run: `cd infra && npm install && npx tsc --noEmit && echo TSC_OK`
Expected: `TSC_OK` (instala aws-cdk-lib y compila sin errores). Si npm falla por el sandbox de red, reintentar con sandbox deshabilitado (registry.npmjs.org está permitido).

- [ ] **Step 8: Commit**

```bash
git add infra/package.json infra/tsconfig.json infra/cdk.json infra/.gitignore infra/bin/sara3-loadtest.ts infra/lib/sara3-loadtest-stack.ts
git commit -m "feat(infra): scaffold proyecto CDK TypeScript para carga

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

> No se versionan `package-lock.json` ni `node_modules` aquí; si `npm install` genera lock, queda fuera por el `.gitignore` raíz/infra. (Opcional: versionar el lock; no requerido por este plan.)

---

## Task 2: Implementar los recursos del stack

**Files:**
- Modify: `infra/lib/sara3-loadtest-stack.ts` (reemplazo completo)

**Contexto:** VPC default + subred pública, SG solo-egress, DockerImageAsset
(contexto = raíz del repo, donde está el `Dockerfile`), bucket S3 efímero, rol +
instance profile con ECR read + pull del asset + write al bucket, AMI AL2023, y
outputs con ids sin guion bajo (para keys limpias en el outputs-file).

- [ ] **Step 1: Reemplazar `infra/lib/sara3-loadtest-stack.ts` con:**

```typescript
import * as path from 'path';
import { Stack, StackProps, CfnOutput, RemovalPolicy } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ecrAssets from 'aws-cdk-lib/aws-ecr-assets';

export class Sara3LoadTestStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // VPC default + primera subred pública
    const vpc = ec2.Vpc.fromLookup(this, 'DefaultVpc', { isDefault: true });
    const subnet = vpc.publicSubnets[0];

    // Security group: solo egress (las instancias solo hacen salida)
    const sg = new ec2.SecurityGroup(this, 'LoadTestSg', {
      vpc,
      description: 'SARA3 load test - solo egress',
      allowAllOutbound: true,
    });

    // Imagen Docker -> ECR (assets de CDK). Contexto = raiz del repo.
    const image = new ecrAssets.DockerImageAsset(this, 'Sara3Image', {
      directory: path.join(__dirname, '..', '..'),
    });

    // Bucket de resultados (efimero: se borra con cdk destroy)
    const bucket = new s3.Bucket(this, 'ResultsBucket', {
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // Rol + instance profile para las EC2
    const role = new iam.Role(this, 'InstanceRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEC2ContainerRegistryReadOnly'),
      ],
    });
    image.repository.grantPull(role);
    bucket.grantWrite(role);
    const profile = new iam.InstanceProfile(this, 'InstanceProfile', { role });

    // AMI Amazon Linux 2023 (x86_64)
    const amiId = ec2.MachineImage.latestAmazonLinux2023().getImage(this).imageId;

    // Outputs (ids alfanumericos para keys limpias en --outputs-file)
    new CfnOutput(this, 'AwsRegion', { value: this.region });
    new CfnOutput(this, 'EcrImage', { value: image.imageUri });
    new CfnOutput(this, 'S3Bucket', { value: bucket.bucketName });
    new CfnOutput(this, 'SubnetId', { value: subnet.subnetId });
    new CfnOutput(this, 'SecurityGroupId', { value: sg.securityGroupId });
    new CfnOutput(this, 'IamInstanceProfile', { value: profile.instanceProfileName });
    new CfnOutput(this, 'AmiId', { value: amiId });
  }
}
```

- [ ] **Step 2: Type-check**

Run: `cd infra && npx tsc --noEmit && echo TSC_OK`
Expected: `TSC_OK` (compila; valida tipos de todos los constructs e imports).

> `cdk synth` NO se ejecuta aquí: requiere Docker (DockerImageAsset construye la
> imagen) y credenciales (`fromLookup`). Queda en la Task 5 (gated).

- [ ] **Step 3: Commit**

```bash
git add infra/lib/sara3-loadtest-stack.ts
git commit -m "feat(infra): stack CDK con ECR asset, S3, IAM, SG, AMI y outputs

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Script de integración `gen-config-env.sh` (+ test)

**Files:**
- Create: `infra/gen-config-env.sh`
- Test: `infra/tests/test-gen-config-env.sh`
- Modify: `.gitattributes`

**Contexto:** Transforma el `cdk-outputs.json` (de `cdk deploy --outputs-file`) en
`aws/config.env`, añadiendo defaults `INSTANCE_TYPE`, `INSTANCES`, `RUNNERS`. Usa
`jq`. La ruta de salida es overridable por `CONFIG_ENV_OUT` (para tests).

- [ ] **Step 1: Escribir el test que falla: `infra/tests/test-gen-config-env.sh`**

```bash
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
grep -q '^INSTANCE_TYPE=r5.2xlarge$' "$tmp/config.env" || { echo "FAIL INSTANCE_TYPE"; exit 1; }
grep -q '^INSTANCES=10$' "$tmp/config.env" || { echo "FAIL INSTANCES"; exit 1; }
grep -q '^RUNNERS=10$' "$tmp/config.env" || { echo "FAIL RUNNERS"; exit 1; }
echo "OK gen-config-env"
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `bash infra/tests/test-gen-config-env.sh`
Expected: FALLA (`gen-config-env.sh` no existe).

- [ ] **Step 3: Implementar `infra/gen-config-env.sh`**

```bash
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
INSTANCE_TYPE=r5.2xlarge
AMI_ID=${AMI_ID}
SUBNET_ID=${SUBNET_ID}
SECURITY_GROUP_ID=${SECURITY_GROUP_ID}
IAM_INSTANCE_PROFILE=${IAM_INSTANCE_PROFILE}
INSTANCES=10
RUNNERS=10
EOF
echo "Escrito $OUT"
cat "$OUT"
```

- [ ] **Step 4: Permiso + correr el test**

Run: `chmod +x infra/gen-config-env.sh infra/tests/test-gen-config-env.sh && bash infra/tests/test-gen-config-env.sh`
Expected: `OK gen-config-env`

- [ ] **Step 5: Forzar LF en los scripts de `infra/`**

Reemplazar en `.gitattributes` la línea:

```
aws/** text eol=lf
```

por:

```
aws/** text eol=lf
infra/**/*.sh text eol=lf
```

- [ ] **Step 6: Commit**

```bash
git add infra/gen-config-env.sh infra/tests/test-gen-config-env.sh .gitattributes
git commit -m "feat(infra): gen-config-env.sh (outputs CDK -> aws/config.env) + test

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: README de `infra/`

**Files:**
- Create: `infra/README.md`

**Contexto:** Documentar el flujo de extremo a extremo (bootstrap → deploy →
gen-config → lanzar carga → destroy) y precondiciones.

- [ ] **Step 1: Crear `infra/README.md`**

```markdown
# Infra de carga (AWS CDK · TypeScript)

Provisiona la infra durable de la prueba de carga (ECR vía DockerImageAsset, S3,
IAM instance profile, security group, VPC default, AMI AL2023) y genera
`aws/config.env` para el orquestador `aws/launch-load-test.sh`.

## Precondiciones

- Node 22 + AWS CLI v2 con **credenciales válidas** (`aws sts get-caller-identity`).
- Docker (el deploy construye la imagen 3.55 GB con DockerImageAsset).
- `jq` (para `gen-config-env.sh`).
- `cdk bootstrap` una vez por cuenta/región.

## Flujo

```bash
cd infra
npm install
npx cdk bootstrap                          # una vez por cuenta/region
npx cdk deploy --outputs-file cdk-outputs.json
./gen-config-env.sh cdk-outputs.json       # escribe ../aws/config.env

cd ..
./aws/launch-load-test.sh --instances 2 --runners 2 --dry-run   # ensayo
./aws/launch-load-test.sh --instances 10 --runners 10           # carga objetivo
./aws/launch-load-test.sh --download <RUN_ID>                   # resultados

cd infra && npx cdk destroy                # desmontar infra
```

## Qué crea el stack

| Recurso | Output | Uso en config.env |
|---------|--------|--------------------|
| VPC default (subred pública) | `SubnetId` | `SUBNET_ID` |
| Security Group (solo egress) | `SecurityGroupId` | `SECURITY_GROUP_ID` |
| DockerImageAsset (ECR) | `EcrImage` | `ECR_IMAGE` |
| Bucket S3 (efímero) | `S3Bucket` | `S3_BUCKET` |
| IAM Role + Instance Profile | `IamInstanceProfile` | `IAM_INSTANCE_PROFILE` |
| AMI Amazon Linux 2023 | `AmiId` | `AMI_ID` |
| Región del stack | `AwsRegion` | `AWS_REGION` |

`gen-config-env.sh` añade además `INSTANCE_TYPE=r5.2xlarge`, `INSTANCES=10`,
`RUNNERS=10`.

## Notas

- `verify` parcial sin cuenta: `npm install && npx tsc --noEmit`. `cdk synth`
  necesita Docker + credenciales (DockerImageAsset + `fromLookup`).
- `cdk destroy` borra S3 (con objetos), IAM y SG. La imagen vive en el repo de
  assets compartido de CDK.
- La carga real golpea `https://asistenciaapp.kit.sura-konecta.com` — testing
  autorizado y en ventana acordada.
```

- [ ] **Step 2: Verificar**

Run: `grep -q "cdk bootstrap" infra/README.md && grep -q "gen-config-env.sh cdk-outputs.json" infra/README.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add infra/README.md
git commit -m "docs(infra): README del stack CDK de carga

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5 (MANUAL / gated): bootstrap, deploy, generar config y validar

**Files:** ninguno (operaciones en AWS; requieren credenciales + Docker + autorización)

**Contexto:** SÓLO ejecutar con: credenciales AWS válidas (hoy el token está
expirado), Docker disponible, y autorización. NO ejecutar automáticamente;
requiere confirmación explícita del usuario.

- [ ] **Step 1: Confirmar precondiciones**

Run: `aws sts get-caller-identity && docker info >/dev/null 2>&1 && echo PRECOND_OK`
Expected: identidad AWS válida + `PRECOND_OK`.

- [ ] **Step 2: Bootstrap (una vez por cuenta/región)**

Run: `cd infra && npx cdk bootstrap`
Expected: termina sin error (crea el toolkit stack `CDKToolkit`).

- [ ] **Step 3: Deploy**

Run: `cd infra && npx cdk deploy --outputs-file cdk-outputs.json --require-approval never`
Expected: crea el stack; `cdk-outputs.json` contiene `Sara3LoadTestStack` con las 7 keys.

- [ ] **Step 4: Generar `aws/config.env`**

Run: `cd infra && ./gen-config-env.sh cdk-outputs.json`
Expected: escribe `aws/config.env` con las 10 variables pobladas.

- [ ] **Step 5: Ensayo del orquestador con valores reales**

Run: `cd .. && ./aws/launch-load-test.sh --instances 2 --runners 2 --dry-run`
Expected: imprime los `run-instances` con el AMI/subred/SG/profile/ECR reales.

- [ ] **Step 6: (opcional, bajo autorización) corrida reducida y teardown**

Run: `./aws/launch-load-test.sh --instances 2 --runners 2` → anotar `RUN_ID` →
`./aws/launch-load-test.sh --download <RUN_ID>`.
Al terminar: `cd infra && npx cdk destroy` y `./aws/launch-load-test.sh --kill`.

---

## Self-Review

- **Spec coverage:** Task 1 (scaffold CDK TS), Task 2 (VPC default/SG/DockerImageAsset/S3/IAM+instance profile/AMI/outputs — toda la sección "Stack provisiona"), Task 3 (integración outputs→`aws/config.env` + LF para infra), Task 4 (flujo de uso/README), Task 5 (bootstrap/deploy/gen/validación/teardown gated). Cubre Arquitectura, Outputs, Integración, Flujo, Teardown y Precondiciones del spec. Fuera de alcance (ECS/Batch, Terraform, multi-región, cambiar el bash) respetado.
- **Placeholder scan:** sin TBD/TODO reales; `<RUN_ID>` es entrada del usuario.
- **Type consistency:** nombres consistentes — clase `Sara3LoadTestStack`, stack id `Sara3LoadTestStack`, outputs `AwsRegion/EcrImage/S3Bucket/SubnetId/SecurityGroupId/IamInstanceProfile/AmiId`, mapeo a `AWS_REGION/ECR_IMAGE/S3_BUCKET/SUBNET_ID/SECURITY_GROUP_ID/IAM_INSTANCE_PROFILE/AMI_ID`, archivo `gen-config-env.sh`, `cdk-outputs.json`.
