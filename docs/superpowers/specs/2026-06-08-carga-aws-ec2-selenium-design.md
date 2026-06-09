# Prueba de carga en AWS: flota EC2 spot con runners Selenium — Diseño

**Fecha:** 2026-06-08
**Autor:** Roberto Garcia
**Estado:** Aprobado para implementación

## Objetivo

Generar ~100 sesiones Chrome concurrentes contra la aplicación destino,
distribuidas en 10 instancias EC2 spot (10 runners cada una), reusando los
runners Selenium existentes (`CasesRunner01-50`), para medir el comportamiento
de la app bajo carga.

## Decisiones (acordadas en brainstorming)

- **Tipo de prueba:** carga/estrés (no solo funcional).
- **Motor de carga:** Selenium/Chrome real, reusando los `CasesRunner` actuales.
- **Plataforma:** EC2 spot, 10 instancias literales × 10 runners = 100
  concurrentes.
- **Credenciales:** reutilizar los 50 usuarios (`pruebas1-50`); se acepta el
  riesgo de 2 sesiones simultáneas por usuario.
- **Orquestación:** script Bash + AWS CLI (v1); Terraform queda como evolución
  futura.
- **Entorno destino:** el actual
  (`https://asistenciaapp.kit.sura-konecta.com`, definido en
  `serenity.properties`). No hay staging.

## Contexto

- Imagen Docker `sara3` (3.55 GB) ya construible vía `Dockerfile`; el batch local
  corre con `-PmaxParallelForks=N` (perilla `RUNNERS`).
- 50 clases `CasesRunner01-50`; cada una = 1 escenario para 1 usuario.
- Antecedente: con 8 concurrentes local hubo `TimeoutException` intermitentes en
  el paso "Transicionar caso adaptativo" — falla de la app bajo concurrencia, no
  de infraestructura. Es justo lo que esta prueba busca medir a mayor escala.
- Ya existe `.github/workflows/docker-batch-tests.yml` (build + push a GHCR); no
  hay IaC ni nada de AWS en el repo.

## Arquitectura

Componentes:

1. **ECR** — repositorio para publicar la imagen `sara3` (pull rápido en-región
   desde EC2).
2. **Launch template** — instancia `r5.4xlarge` (16 vCPU / 128 GB; sin
   sobre-suscripción de CPU para 10 Chrome), con Docker disponible (AMI con Docker
   o instalación en `user-data`), rol IAM con acceso de lectura a ECR y escritura
   al bucket S3, y `InstanceInitiatedShutdownBehavior=terminate`.
   - **Paralelismo:** el nº de forks paralelos = `min(maxParallelForks, --max-workers)`.
     El `user-data` pasa `--max-workers=${RUNNERS} -PmaxParallelForks=${RUNNERS}` y
     `gradle.properties` tiene `org.gradle.workers.max=16` (antes 8 topaba a 8 forks).
3. **`user-data` por instancia** — recibe `SHARD`, `RUNNERS`, `S3_BUCKET`,
   `RUN_ID`; hace login a ECR, `docker run` de la imagen con el `--tests` de su
   shard, sube `target/site` + logs a S3 y ejecuta `shutdown` (→ terminate).
4. **S3** — bucket de resultados:
   `s3://<bucket>/run-<RUN_ID>/instance-<id>/`.
5. **Script orquestador** `aws/launch-load-test.sh` — lanza las N instancias con
   su `SHARD`, las etiqueta (`Project=sara3-loadtest`, `RunId=<RUN_ID>`), espera,
   descarga reportes y consolida un resumen. Incluye `--kill` para terminar por
   tag.

Flujo: script → N spot arrancan ~a la vez → cada una corre 10 runners (Chrome) →
suben reportes a S3 → se auto-terminan → script descarga y agrega.

## Modelo de sharding y concurrencia

Gradle paraleliza clases distintas (no corre la misma clase dos veces por
invocación). Para 100 concurrentes con 50 clases, se **duplican shards** entre
pares de instancias. `shard = índice_instancia % 5`:

| Instancia | Shard | Clases (`maxParallelForks=10`) |
|-----------|-------|--------------------------------|
| 0 y 5 | 0 | CasesRunner01–10 |
| 1 y 6 | 1 | CasesRunner11–20 |
| 2 y 7 | 2 | CasesRunner21–30 |
| 3 y 8 | 3 | CasesRunner31–40 |
| 4 y 9 | 4 | CasesRunner41–50 |

- Cada instancia corre 10 clases distintas en paralelo (10 Chrome). 10
  instancias → 100 Chrome concurrentes; cada escenario corre en 2 instancias a la
  vez → ejercita la reutilización de usuario aceptada.
- Invocación por shard (el script genera el patrón `--tests` exacto), ej. shard 0:
  ```
  ./gradlew test --continue -PmaxParallelForks=10 \
    --tests "com.sara.automation.runners.CasesRunner01" \
    --tests "com.sara.automation.runners.CasesRunner02" \
    ... \
    --tests "com.sara.automation.runners.CasesRunner10"
  ```
- Configurable: `INSTANCES` (default 10) y `RUNNERS` (default 10). Con
  `shard = i % 5`, subir `INSTANCES` repite más veces los shards (más
  concurrencia por escenario).

## Resultados

- Cada instancia sube a `s3://<bucket>/run-<RUN_ID>/instance-<id>/`: reporte
  Serenity (`target/site`) y log completo.
- El orquestador descarga todo al finalizar.
- **Métricas de carga** = duraciones por paso (capturadas por Serenity) + conteo
  de fallos por instancia. Un script de consolidación produce un CSV con: %
  éxito global, fallos por tipo de paso (p. ej. nº de `TimeoutException` en
  "Transicionar caso"), y tiempos p50/p95 por paso.
- La agregación nativa de Serenity en un único HTML es opcional; v1 entrega los
  reportes por-instancia + el resumen CSV.

## Teardown

- Cada instancia hace `terminate` al terminar (vía
  `InstanceInitiatedShutdownBehavior=terminate` + `shutdown`, con respaldo
  `aws ec2 terminate-instances`).
- El script ofrece `--kill`: termina todas las instancias con tag
  `Project=sara3-loadtest` (y opcionalmente filtra por `RunId`) para no dejar
  spot colgadas.

## Costos (orden de magnitud)

10× `r5.4xlarge` (on-demand ≈ ~US$1.0/h c/u; spot ≈ ~US$0.30–0.50/h c/u). Una
corrida on-demand de ~30–40 min ≈ ~US$5–7; en spot ≈ ~US$2–3 (se auto-terminan).

## Riesgos y mitigaciones

1. **Carga sobre la app destino (entorno actual, sin staging):** 100 sesiones
   reales contra `asistenciaapp.kit.sura-konecta.com`. Debe ser testing
   **autorizado** y en **ventana acordada** con los dueños de la app. El plan
   incluirá un parámetro de concurrencia para empezar bajo (p. ej. `INSTANCES=2`)
   y escalar gradualmente.
2. **Reutilización de usuario:** colisiones de sesión pueden inflar fallos; el
   resumen debe distinguir "fallo por carga real" vs "posible colisión de
   usuario" (mismo `pruebasN` activo en 2 instancias).
3. **Prerrequisitos AWS:** cuenta con credenciales CLI, VPC/subred con salida a
   internet, security group, rol IAM (lectura ECR + escritura S3), y AMI con
   Docker (o instalación en `user-data`). El plan los listará como precondiciones.
4. **Disponibilidad de spot:** fallback a on-demand o reintento en otra AZ.

## Fuera de alcance (YAGNI)

- Terraform / IaC declarativa (evolución futura).
- Herramientas de carga a nivel protocolo (k6/Gatling).
- Ampliación del pool de usuarios más allá de los 50 existentes.
- Agregación Serenity en un único HTML consolidado (v1 = reportes por instancia +
  CSV resumen).
- Autoescalado dinámico / dashboards en tiempo real.

## Verificación de éxito

- Una corrida reducida (`INSTANCES=2`, `RUNNERS=2`) lanza 2 spot, cada una corre
  su shard, sube resultados a S3 y se auto-termina; el script descarga los
  reportes y genera el CSV resumen.
- Escalado a `INSTANCES=10`, `RUNNERS=10` produce ~100 sesiones concurrentes
  (verificable por los timestamps solapados de los logs de las 10 instancias) y
  un resumen consolidado de éxito/fallos y tiempos.
