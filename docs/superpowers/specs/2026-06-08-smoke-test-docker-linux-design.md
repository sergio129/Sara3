# Smoke test de un runner SARA3 vía Docker en Linux — Diseño

**Fecha:** 2026-06-08
**Autor:** Roberto Garcia
**Estado:** Aprobado para implementación

## Objetivo

Construir la imagen Docker del proyecto SARA3 y ejecutar **un solo runner**
(`CasesRunner01`) de extremo a extremo en este equipo Linux, confirmando que el
pipeline completo funciona antes de escalar a ejecución paralela.

Criterios de "pipeline funcionando":
- La imagen compila el proyecto (Gradle + JDK 11).
- El contenedor levanta Chrome + Xvfb (display virtual).
- El test se ejecuta.
- Se genera el reporte Serenity y queda accesible en el host.

## Contexto del entorno

Equipo Linux donde se ejecuta:
- Docker 29.5.3 ✓
- Docker Compose v5.1.4 ✓
- Google Chrome 149 ✓ (en el host; no se usa para el smoke, la imagen trae el suyo)
- 20 cores, 62 GB RAM
- **Java NO instalado** en el host → razón principal para usar Docker en vez de nativo.

El `docs/README.md` está escrito solo para Windows (`run_tests.bat`), pero el
proyecto ya incluye infraestructura Linux/Docker:
- `Dockerfile` (multi-stage: builder con `eclipse-temurin:11-jdk-jammy`,
  runtime sobre `selenium/standalone-chrome:latest` que ya trae Chrome + Xvfb).
- `docker-compose.yml` con servicios `sara3-batch`, `sara3-interactive`,
  `sara3-single`.
- `docker-entrypoint.sh` (levanta Xvfb en `:99`, modo comando o menú interactivo).

## Enfoque

Se evaluaron 3 caminos:

- **A — `docker compose run sara3-single` (elegido):** el servicio ya existe,
  monta volúmenes de reportes a `./target/site` y define `TEST_NUM`. Es el
  camino diseñado para correr un test individual.
- B — `docker build` + `docker run` manual con el comando Gradle: más control
  pero reinventa lo que ya hay en compose.
- C — `docker run -it` + menú interactivo: bueno para explorar, malo para
  repetir/automatizar.

## Arquitectura de la corrida

1. `docker compose build sara3-single` → construye `sara3:latest`.
2. `docker compose run --rm sara3-single` → el entrypoint levanta Xvfb en `:99`
   y ejecuta `./gradlew test --tests com.sara.automation.runners.CasesRunner${TEST_NUM}`
   (con `TEST_NUM=01`).
3. El reporte queda en el host vía volumen: `./target/site/serenity/index.html`.

Notas de configuración relevantes:
- `serenity.properties` tiene `--headless` comentado; Chrome corre en modo
  "headed" dentro del display virtual Xvfb, lo cual es correcto en el contenedor.
- `chrome.switches` ya incluye `--no-sandbox` (necesario para Docker root) y
  `--disable-dev-shm-usage`.

## Cambios requeridos (mínimos, enfocados al smoke)

### 1. `docker-entrypoint.sh` — evitar cuelgue sin TTY

Hoy, cuando el comando directo falla, el entrypoint cae al menú interactivo
(`bash /app/docker-menu.sh`), que hace `read` sobre stdin. En `docker compose
run` sin `-it` no hay TTY → EOF inmediato y posible loop.

Fix: caer al menú **solo si hay terminal interactiva** (`[ -t 0 ]`); de lo
contrario, salir con el código de error del comando.

### 2. `docker-compose.yml` (servicio `sara3-single`) — alinear CHROME_BIN

Cambiar `CHROME_BIN: "/usr/bin/chromium-browser"` →
`CHROME_BIN: "/usr/bin/google-chrome"`, consistente con el `Dockerfile` y con la
imagen `selenium/standalone-chrome` (no trae `chromium-browser`).

## Fuera de alcance (YAGNI)

- `batch_test_8p.sh` faltante (referenciado por `sara3-batch`).
- Ajuste de `maxParallelForks` para paralelo.
- Reescritura del `README.md` para Linux.

Todo lo anterior pertenece al flujo de ejecución paralela, no al smoke.

## Comandos de ejecución

```bash
docker compose build sara3-single
docker compose run --rm sara3-single
```

## Verificación de éxito (evidencia, no suposición)

- El comando termina con **exit code 0**.
- Se crea/actualiza `./target/site/serenity/index.html` en el host.
- El log muestra Xvfb iniciado en `:99`, `BUILD SUCCESSFUL` y la línea de
  `Tests ... completed` de Gradle.

## Riesgos conocidos

- El `docker compose build` requiere red (descarga Gradle, dependencias e imagen
  Selenium). Se ejecuta fuera del sandbox.
- La primera build puede tardar varios minutos.
- Si el test falla por la aplicación destino (login/credenciales/URL), el
  pipeline Docker queda igualmente validado; se distinguirá "falla de infra" vs
  "falla de test" revisando el log.
