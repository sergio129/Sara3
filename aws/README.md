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
./aws/launch-load-test.sh --instances 2 --runners 2 --on-demand --dry-run

# Corrida reducida real (4 sesiones concurrentes) para validar el pipeline:
./aws/launch-load-test.sh --instances 2 --runners 2 --on-demand

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

## Paralelismo por instancia

Cada instancia corre `RUNNERS` runners (Chrome) en paralelo. El nº real de forks
es `min(maxParallelForks, --max-workers)`; el orquestador pasa
`--max-workers=$RUNNERS -PmaxParallelForks=$RUNNERS`, y `gradle.properties` tiene
`org.gradle.workers.max=16` para no topar (antes 8 limitaba a 8 forks). Para
`RUNNERS=10` se usa `r5.4xlarge` (16 vCPU / 128 GB), sin sobre-suscripción de CPU.

## Resultados

`s3://<bucket>/run-<RUN_ID>/instance-<id>/` (reporte Serenity + log). El
`--download` los baja a `results/run-<RUN_ID>/` y produce `summary.csv` con
tests completados/fallidos y `TimeoutException` por instancia.
