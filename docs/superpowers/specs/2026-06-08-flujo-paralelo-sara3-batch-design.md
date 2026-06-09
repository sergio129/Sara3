# Flujo paralelo configurable `sara3-batch` — Diseño

**Fecha:** 2026-06-08
**Autor:** Roberto Garcia
**Estado:** Aprobado para implementación

## Objetivo

Ejecutar las 50 clases `CasesRunner01-50` con un grado de paralelismo
configurable mediante una sola perilla, generando el reporte Serenity agregado.
Reemplaza el `command` roto del servicio `sara3-batch` (apunta a un
`batch_test_8p.sh` que no existe en el repo).

## Contexto

- `build.gradle:66` lee el paralelismo como project property:
  `maxParallelForks = project.hasProperty('maxParallelForks') ? ... : 2`. Por
  tanto se puede fijar con `-PmaxParallelForks=N` en la línea de comandos, sin
  editar `gradle.properties` con `sed` (como hace `run_tests.sh`).
- `./gradlew test` **sin** filtro `--tests` ejecuta las 50 clases
  `CasesRunner01-50`. Con `maxParallelForks=N` corren N forks (JVM + Chrome) en
  paralelo.
- Cada fork usa `maxHeapSize=2048m` (`build.gradle:69`); el daemon Gradle usa
  `-Xmx4096m` (`gradle.properties`). 8 forks ≈ 20 GB, 12 ≈ 28 GB de RAM.
- Hardware del host: 20 cores, ~39 GB libres.
- El servicio `sara3-batch` ya existe en `docker-compose.yml` pero con
  `command: ./batch_test_8p.sh` (archivo inexistente) y `CHROME_BIN` apuntando a
  `chromium-browser` (la imagen Selenium usa `google-chrome`).
- El entrypoint (`docker-entrypoint.sh`) ejecuta el comando recibido con
  `bash -c "$@"`. Por eso el `command` debe ir como **string único** (no envuelto
  en otro `bash -c`), igual que el fix ya aplicado a `sara3-single`.

## Decisiones (acordadas en brainstorming)

- El batch corre **siempre las 50 clases**, con N en paralelo (N = grado de
  paralelismo). No hay segunda perilla de "cuántas ejecutar".
- Default **N = 8** (punto cómodo para el hardware: ~20 GB, holgura amplia,
  amable con la app destino).

## Arquitectura — una sola perilla `RUNNERS`

Cambios, todos en el servicio `sara3-batch` de `docker-compose.yml`:

### 1. `command` (reemplaza `./batch_test_8p.sh`)

```yaml
command: ["./gradlew test --parallel --continue -PmaxParallelForks=$${RUNNERS}"]
```

- String único → el `bash -c "$@"` del entrypoint lo ejecuta y expande
  `${RUNNERS}` desde el entorno.
- Sin filtro `--tests` → corre las 50 clases.
- `--continue` → si un runner falla, los demás continúan y el reporte sale
  completo.
- `$${RUNNERS}` → Compose lo pasa como literal `${RUNNERS}` al contenedor.

### 2. `environment`

- Añadir/usar `RUNNERS: "8"` como valor por defecto.
- Corregir `CHROME_BIN: "/usr/bin/google-chrome"` (hoy `chromium-browser`).

### 3. Tope de recursos del contenedor (fijo, independiente de `RUNNERS`)

```yaml
deploy:
  resources:
    limits:
      cpus: '16'
      memory: 32G
    reservations:
      cpus: '2'
      memory: 4G
```

Techo seguro para este host (deja RAM al OS + el contenedor Postgres). Soporta
holgadamente N=8 (~20 GB) y N=12 (~28 GB). Si en el futuro se sube `RUNNERS` por
encima de ~12, hay que elevar también este techo.

## Uso

```bash
# Default (8 en paralelo, las 50 clases)
docker compose run --rm sara3-batch

# Override del paralelismo sin editar archivos
docker compose run --rm -e RUNNERS=12 sara3-batch
```

## Reportes

Sin cambios: los volúmenes ya montan `target/site`, `target/reports` y `logs`.
El índice agregado queda en `target/site/serenity/index.html` con las 50 clases.

## Verificación de éxito

- `docker compose config --quiet` pasa (exit 0).
- `docker compose config sara3-batch` muestra el `command` como string único con
  `-PmaxParallelForks=${RUNNERS}` y `CHROME_BIN: /usr/bin/google-chrome`.
- Una corrida con `RUNNERS=2` (rápida de validar) arranca varios forks/Chrome en
  paralelo (visible en el log de Gradle: múltiples `Test worker`), genera
  `target/site/serenity/index.html` y termina sin error de infraestructura.

## Fuera de alcance (YAGNI)

- No se crea `batch_test_8p.sh` (el `command` inline lo reemplaza).
- No se toca `sara3-single` ni `sara3-interactive`.
- No se añade segunda perilla ("cuántas clases ejecutar").
- No se modifica `gradle.properties` (el paralelismo va por `-P`).

## Riesgo conocido

Muchos forks pegan a la misma app remota
(`asistenciaapp.kit.sura-konecta.com`) → mayor probabilidad de
`TimeoutException`. Mitigado con default 8 y `--continue` (un timeout no tumba la
corrida completa).
