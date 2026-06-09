# Infra de carga en AWS con CDK (TypeScript) — Diseño

**Fecha:** 2026-06-08
**Autor:** Roberto Garcia
**Estado:** Aprobado para implementación

## Objetivo

Un stack AWS CDK en TypeScript que provisiona toda la infraestructura durable de
la prueba de carga y emite los valores que el orquestador `aws/` ya consume. El
bash orquestador **no cambia** (sigue lanzando la flota spot 10×10); el CDK solo
levanta y desmonta la infra, reemplazando los pasos manuales de precondición.

## Decisiones (acordadas en brainstorming)

- **Imagen ECR:** `DockerImageAsset` — CDK construye y sube la imagen (3.55 GB) en
  cada `cdk deploy`, al repo de assets gestionado por CDK.
- **Red:** VPC default de la cuenta, subred pública (salida directa a internet,
  sin NAT).
- **Separación de responsabilidades:** CDK = infra durable; el orquestador bash
  `aws/launch-load-test.sh` (ya construido y testeado) = lanzamiento de la flota.
- **Lenguaje/ubicación:** TypeScript, proyecto nuevo bajo `infra/`.

## Contexto

- Entorno local: Node v22, npm 10.9, CDK 2.1126 instalados; no hay proyecto CDK.
- El orquestador `aws/launch-load-test.sh` requiere estas variables (hoy en
  `aws/config.env`): `AWS_REGION, ECR_IMAGE, S3_BUCKET, INSTANCE_TYPE, AMI_ID,
  SUBNET_ID, SECURITY_GROUP_ID, IAM_INSTANCE_PROFILE`.
- `Dockerfile` en la raíz construye la imagen `sara3` (multi-stage, runtime
  `selenium/standalone-chrome`).
- Hay `.gitattributes` con `aws/** text eol=lf` (los scripts bash deben quedar en
  LF).

## Arquitectura

Proyecto CDK TS estándar en `infra/`: `cdk.json`, `package.json`, `tsconfig.json`,
`bin/sara3-loadtest.ts`, `lib/sara3-loadtest-stack.ts`.

### Stack `Sara3LoadTestStack` provisiona

1. **VPC default** — `ec2.Vpc.fromLookup(this, 'Vpc', { isDefault: true })`. Se
   usa una subred pública (`vpc.publicSubnets[0]`).
2. **Security Group** — `ec2.SecurityGroup` con `allowAllOutbound: true`, sin
   ingress (las instancias solo hacen salida hacia la app, ECR y S3).
3. **DockerImageAsset** — `new ecr_assets.DockerImageAsset(this, 'Image', {
   directory: path.join(__dirname, '..', '..') })` (contexto = raíz del repo,
   donde está el `Dockerfile`). Su `imageUri` (tag por hash) → output `ECR_IMAGE`.
4. **Bucket S3** de resultados — `removalPolicy: RemovalPolicy.DESTROY` +
   `autoDeleteObjects: true` (datos efímeros; `cdk destroy` limpio).
5. **IAM Role + Instance Profile** — `iam.Role` con
   `assumedBy: ServicePrincipal('ec2.amazonaws.com')`, managed policy
   `AmazonEC2ContainerRegistryReadOnly`; además `image.repository.grantPull(role)`
   y `bucket.grantWrite(role)`. `new iam.InstanceProfile(this, 'Profile', { role })`
   → su `instanceProfileName` → output `IAM_INSTANCE_PROFILE`.
6. **AMI** — `ec2.MachineImage.latestAmazonLinux2023()`; el `imageId` resuelto →
   output `AMI_ID`.

### Outputs (CfnOutput)

`AWS_REGION` (region del stack), `ECR_IMAGE`, `S3_BUCKET`, `SUBNET_ID`,
`SECURITY_GROUP_ID`, `IAM_INSTANCE_PROFILE`, `AMI_ID`.

### Integración con el orquestador bash

- Deploy con `cdk deploy --outputs-file cdk-outputs.json`.
- Script `infra/gen-config-env.sh <cdk-outputs.json>` transforma los outputs en
  `aws/config.env`, añadiendo defaults `INSTANCE_TYPE=r5.2xlarge`, `INSTANCES=10`,
  `RUNNERS=10`.

## Flujo de uso

```bash
# 1. (una vez por cuenta/región) bootstrap
cd infra && npm install && npx cdk bootstrap

# 2. Levantar infra (build+push imagen, S3/IAM/SG, resuelve AMI)
npx cdk deploy --outputs-file cdk-outputs.json

# 3. Generar aws/config.env desde los outputs
./gen-config-env.sh cdk-outputs.json

# 4. Lanzar la carga con el orquestador existente
cd .. && ./aws/launch-load-test.sh --instances 2 --runners 2 --dry-run
./aws/launch-load-test.sh --instances 10 --runners 10
./aws/launch-load-test.sh --download <RUN_ID>

# 5. Desmontar infra al terminar
cd infra && npx cdk destroy
```

## Teardown y costos

- `cdk destroy` elimina S3 (con objetos), IAM e SG. La imagen vive en el repo de
  assets compartido de CDK (no se borra con el stack; almacenamiento mínimo).
- Las instancias spot se auto-terminan; respaldo `./aws/launch-load-test.sh --kill`.
- Infra en reposo ≈ US$0. El costo real es la flota spot durante la corrida
  (~US$1–2).

## Precondiciones

- Credenciales AWS válidas (hoy el token está expirado — renovar con
  `aws sso login` / `aws configure`).
- `cdk bootstrap` (requiere permisos elevados una vez).
- Permisos para crear ECR/S3/IAM/EC2.

## Verificación de éxito

- `cd infra && npm install && npx cdk synth` produce el template sin errores
  (validable parcialmente sin credenciales; `fromLookup` y bootstrap requieren
  cuenta).
- Tras `cdk deploy` + `gen-config-env.sh`, `aws/config.env` queda con las 8
  variables pobladas y `./aws/launch-load-test.sh --instances 2 --runners 2 --dry-run`
  imprime los `run-instances` con esos valores reales.
- La corrida real (Task gated del plan de carga) y `cdk destroy` quedan a criterio
  del usuario (requieren cuenta + autorización).

## Riesgos y mitigaciones

1. **Deploy lento la primera vez** por build+push de 3.55 GB (DockerImageAsset).
   Mitigación: cache de capas Docker entre deploys.
2. **`cdk bootstrap` requiere permisos elevados** una vez por cuenta/región.
3. **La carga real golpea la app de producción** (sin staging) — testing
   autorizado y en ventana acordada; arranque gradual (`INSTANCES=2`).
4. **Credenciales expiradas** bloquean synth con `fromLookup` y el deploy —
   renovar antes.

## Fuera de alcance (YAGNI)

- Mover el lanzamiento de la flota a CDK/ECS/Batch (el bash se queda).
- Terraform; multi-región; pipeline CI de deploy.
- Cambios al orquestador `aws/` (solo se consume vía `config.env`).
- Ampliación del pool de usuarios.
