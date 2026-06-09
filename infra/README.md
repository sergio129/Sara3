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
./aws/launch-load-test.sh `--instances 2 --runners 2 --on-demand  --dry-run`   # ensayo
./aws/launch-load-test.sh --instances 10 --runners 10 --on-demand           # carga objetivo
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
