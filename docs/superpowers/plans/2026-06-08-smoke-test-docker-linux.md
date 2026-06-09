# Smoke test SARA3 vía Docker en Linux — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir la imagen Docker de SARA3 y ejecutar `CasesRunner01` de extremo a extremo en Linux, validando el pipeline completo (compilación, Chrome+Xvfb, ejecución, reporte Serenity) antes de escalar a paralelo.

**Architecture:** Se usa el servicio `sara3-single` ya definido en `docker-compose.yml`, sobre una imagen multi-stage (builder `eclipse-temurin:11-jdk-jammy` + runtime `selenium/standalone-chrome`). Dos edits de infraestructura desbloquean la corrida no-interactiva; luego se ejecuta y se verifica con evidencia (exit code, log, reporte en host).

**Tech Stack:** Docker, Docker Compose, Gradle, JDK 11, Selenium standalone-chrome, Serenity BDD, Xvfb.

**Nota sobre verificación:** Este plan modifica scripts de infraestructura, no código con tests unitarios. La "prueba" de cada tarea es evidencia observable real (contenido de archivo, exit code, líneas de log, archivo generado), no aserciones de un framework de test.

---

## Estructura de archivos

- Modify: `docker-entrypoint.sh` — guard de TTY para no caer al menú interactivo sin terminal.
- Modify: `docker-compose.yml` (servicio `sara3-single`) — alinear `CHROME_BIN` a `google-chrome`.
- Genera (no se versiona): `target/site/serenity/index.html` — reporte de salida en el host.

---

## Task 1: Guard de TTY en el entrypoint

**Files:**
- Modify: `docker-entrypoint.sh` (bloque de modo comando directo, ~líneas 60-75)

**Contexto:** Hoy, cuando se pasa un comando y este falla, el entrypoint ejecuta
`bash /app/docker-menu.sh` (menú interactivo con `read` sobre stdin). En
`docker compose run` sin `-it` no hay TTY, lo que provoca EOF/loop. El fix hace
que solo caiga al menú si hay terminal interactiva.

- [ ] **Step 1: Leer el bloque actual para confirmar el texto exacto**

Run: `grep -n "El comando falló con código" docker-entrypoint.sh`
Expected: una línea que muestra el `echo` dentro del bloque `else` del modo comando directo.

- [ ] **Step 2: Aplicar el edit**

Reemplazar este bloque:

```bash
    # Modo comando directo - ejecutar lo que se pasó como argumento
    echo "Ejecutando comando: $@"
    bash -c "$@"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo ""
        echo "⚠️ El comando falló con código $EXIT_CODE. Regresando al menú principal..."
        echo ""
        bash /app/docker-menu.sh
        EXIT_CODE=$?
    fi
```

por:

```bash
    # Modo comando directo - ejecutar lo que se pasó como argumento
    echo "Ejecutando comando: $@"
    bash -c "$@"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo ""
        echo "⚠️ El comando falló con código $EXIT_CODE."
        if [ -t 0 ]; then
            echo "Regresando al menú principal..."
            echo ""
            bash /app/docker-menu.sh
            EXIT_CODE=$?
        else
            echo "Sin TTY: finalizando con el código de error del comando."
        fi
    fi
```

- [ ] **Step 3: Verificar la sintaxis del script**

Run: `bash -n docker-entrypoint.sh`
Expected: sin salida (exit 0 = sintaxis válida).

- [ ] **Step 4: Verificar que el guard quedó en el archivo**

Run: `grep -n "Sin TTY: finalizando" docker-entrypoint.sh`
Expected: una línea con el nuevo mensaje.

- [ ] **Step 5: Commit**

```bash
git add docker-entrypoint.sh
git commit -m "fix(docker): no caer al menu interactivo sin TTY en modo comando

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 1b: Normalizar CRLF→LF en el Dockerfile

**Files:**
- Modify: `Dockerfile` (stage `builder` y stage runtime)

**Contexto (hallazgo en ejecución):** El repo tiene `core.autocrlf=true` y todos
los scripts shell (`docker-entrypoint.sh`, `docker-menu.sh`, `gradlew`,
`run-tests-linux.sh`, ...) están con CRLF en el working tree. El `Dockerfile` los
copia tal cual, por lo que el `ENTRYPOINT` y `gradlew` fallarían dentro de la
imagen (el kernel buscaría `/bin/bash\r`). Decisión del usuario: normalizar
**dentro del Dockerfile** (no tocar el working tree ni el flujo Windows).

- [ ] **Step 1: Normalizar en el stage builder (antes del chmod)**

Reemplazar:

```dockerfile
RUN chmod +x gradlew run-tests-linux.sh && \
    ./gradlew --version && ./gradlew dependencies --write-locks 2>&1 || true
```

por:

```dockerfile
RUN find . -type f \( -name "*.sh" -o -name "gradlew" \) -exec sed -i 's/\r$//' {} + && \
    chmod +x gradlew run-tests-linux.sh && \
    ./gradlew --version && ./gradlew dependencies --write-locks 2>&1 || true
```

- [ ] **Step 2: Normalizar los scripts re-copiados desde el host en el stage runtime**

Reemplazar:

```dockerfile
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-menu.sh /app/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /app/docker-menu.sh && \
    chmod +x gradlew run-tests-linux.sh && \
    mkdir -p logs target/reports
```

por:

```dockerfile
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-menu.sh /app/
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh /app/docker-menu.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh /app/docker-menu.sh && \
    chmod +x gradlew run-tests-linux.sh && \
    mkdir -p logs target/reports
```

- [ ] **Step 3: Verificar sintaxis del Dockerfile vía compose**

Run: `docker compose config --quiet`
Expected: sin errores.

- [ ] **Step 4: Confirmar los edits**

Run: `grep -n "sed -i 's/\\\\r\$//'" Dockerfile`
Expected: dos coincidencias (stage builder y stage runtime).

- [ ] **Step 5: Commit**

```bash
git add Dockerfile
git commit -m "fix(docker): normalizar CRLF a LF en scripts dentro de la imagen

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Corregir docker-compose.yml (CHROME_BIN + compose válido)

**Files:**
- Modify: `docker-compose.yml`

**Contexto:** Dos arreglos en el mismo archivo:
1. **CHROME_BIN** del servicio `sara3-single` apunta a `/usr/bin/chromium-browser`,
   pero la imagen `selenium/standalone-chrome` y el `Dockerfile` usan
   `/usr/bin/google-chrome`.
2. **Hallazgo en ejecución:** `docker compose config` falla porque `resources` y
   `restart_policy` están directamente bajo los servicios; en la spec de Compose
   deben ir bajo `deploy:`. Compose valida el archivo completo, así que esto
   bloquea `build`/`run` de cualquier servicio. Fix mínimo e intent-preserving:
   envolver esos bloques bajo `deploy:` en los tres servicios.

- [ ] **Step 0a: Mover `resources` + `restart_policy` bajo `deploy:` en `sara3-batch`**

Reemplazar:

```yaml
    # Recursos
    resources:
      limits:
        cpus: '2'
        memory: 4G
      reservations:
        cpus: '1'
        memory: 2G
    
    # Restarts
    restart_policy:
      condition: on-failure
      delay: 5s
      max_attempts: 3
      window: 120s
```

por:

```yaml
    # Recursos
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
```

- [ ] **Step 0b: Mover `resources` bajo `deploy:` en `sara3-interactive`**

Reemplazar (el bloque que está entre `volumes:` y `logging:` de `sara3-interactive`, con `cpus: '2'`):

```yaml
    resources:
      limits:
        cpus: '2'
        memory: 4G
      reservations:
        cpus: '1'
        memory: 2G
    
    logging:
```

por:

```yaml
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
    
    logging:
```

- [ ] **Step 0c: Mover `resources` bajo `deploy:` en `sara3-single`**

Reemplazar (el bloque con `cpus: '1'` / `cpus: '0.5'`):

```yaml
    resources:
      limits:
        cpus: '1'
        memory: 2G
      reservations:
        cpus: '0.5'
        memory: 1G
```

por:

```yaml
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
```

- [ ] **Step 1: Localizar la línea CHROME_BIN dentro de sara3-single**

Run: `grep -n "chromium-browser\|TEST_NUM" docker-compose.yml`
Expected: ver el `TEST_NUM: "01"` y, justo arriba en ese mismo servicio, la línea `CHROME_BIN: "/usr/bin/chromium-browser"`.

- [ ] **Step 2: Aplicar el edit (solo en el bloque de sara3-single)**

En el bloque `environment` del servicio `sara3-single`, reemplazar:

```yaml
      CHROME_BIN: "/usr/bin/chromium-browser"
      TEST_NUM: "01"  # Cambiar número de test
```

por:

```yaml
      CHROME_BIN: "/usr/bin/google-chrome"
      TEST_NUM: "01"  # Cambiar número de test
```

> El par `CHROME_BIN` + `TEST_NUM` juntos identifican de forma única el bloque de `sara3-single` (los otros servicios no tienen `TEST_NUM`).

- [ ] **Step 3: Validar el compose**

Run: `docker compose config --quiet`
Expected: sin errores (YAML válido y servicios resolubles).

- [ ] **Step 4: Confirmar que sara3-single quedó con google-chrome**

Run: `docker compose config | grep -A1 "TEST_NUM"`
Expected: el contexto muestra `CHROME_BIN` apuntando a `/usr/bin/google-chrome` junto al `TEST_NUM`.

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml
git commit -m "fix(docker): CHROME_BIN a google-chrome en servicio sara3-single

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Construir la imagen

**Files:** ninguno (operación de build)

**Contexto:** El build necesita red (descarga Gradle, dependencias e imagen
base Selenium) y puede tardar varios minutos la primera vez. Se ejecuta fuera
del sandbox.

- [ ] **Step 1: Construir el servicio**

Run: `docker compose build sara3-single`
Expected: termina con la imagen `sara3:latest` construida; el último mensaje indica build exitoso (sin `ERROR`).

- [ ] **Step 2: Verificar que la imagen existe**

Run: `docker images sara3:latest`
Expected: una fila listando el repositorio `sara3` tag `latest`.

> Si el build falla por red/dependencias, revisar conectividad y reintentar. No continuar a Task 4 hasta tener la imagen.

---

## Task 4: Ejecutar el smoke y verificar

**Files:** genera `target/site/serenity/index.html` en el host (vía volumen)

**Contexto:** Esta es la verificación de extremo a extremo del pipeline. Se
distingue "falla de infra" (Xvfb/Chrome/compilación) de "falla de test" (app
destino: login/credenciales/URL).

- [ ] **Step 1: Ejecutar el runner único**

Run: `docker compose run --rm sara3-single 2>&1 | tee logs/smoke-casesrunner01.log`
Expected: el log muestra Xvfb iniciado en `:99` y la ejecución de Gradle.

- [ ] **Step 2: Verificar arranque de Xvfb (infra OK)**

Run: `grep -i "Xvfb está listo\|Xvfb iniciado" logs/smoke-casesrunner01.log`
Expected: al menos una línea confirmando que Xvfb levantó.

- [ ] **Step 3: Verificar resultado de Gradle**

Run: `grep -iE "BUILD SUCCESSFUL|BUILD FAILED|Tests.*completed" logs/smoke-casesrunner01.log`
Expected: aparece `BUILD SUCCESSFUL` o una línea de `Tests ... completed`.
- Si `BUILD SUCCESSFUL` → pipeline e test OK.
- Si `BUILD FAILED` pero Xvfb y compilación funcionaron → pipeline Docker validado; la falla es de la app destino (documentar el motivo del log).

- [ ] **Step 4: Verificar reporte generado en el host**

Run: `ls -la target/site/serenity/index.html`
Expected: el archivo existe (reporte Serenity generado y montado al host).

- [ ] **Step 5: Resumen de evidencia**

Documentar en un breve comentario (o en el log) el exit code de la corrida, si
hubo `BUILD SUCCESSFUL`, y la ruta del reporte. No se hace commit de artefactos
(`target/`, `logs/` están en `.dockerignore`/build output).

---

## Self-Review

- **Spec coverage:** Task 1 cubre el fix de TTY del entrypoint; Task 2 el
  `CHROME_BIN`; Tasks 3-4 los comandos de ejecución y los 3 criterios de
  verificación de éxito (exit code, reporte en host, líneas de log). Riesgos del
  spec (red, tiempo de build, falla de app vs infra) están reflejados en Tasks 3
  y 4. Fuera de alcance (batch, maxParallelForks, README) no aparece — correcto.
- **Placeholder scan:** sin TBD/TODO; cada step tiene comando y salida esperada
  concretos.
- **Type consistency:** nombres consistentes (`sara3-single`, `TEST_NUM=01`,
  `CasesRunner01`, `/usr/bin/google-chrome`, `target/site/serenity/index.html`)
  en todas las tareas.

---

## Notas de ejecución y resultado (2026-06-08)

Durante la ejecución se descubrieron 3 bloqueos preexistentes que el plan no
anticipaba; los tres se resolvieron como parte del trabajo:

1. **CRLF en scripts shell** (`core.autocrlf=true`): rompía el ENTRYPOINT y
   `gradlew` dentro de la imagen. → Task 1b (normalización en Dockerfile).
   Commit `5fd8421`.
2. **`docker-compose.yml` inválido**: `resources`/`restart_policy` fuera de
   `deploy:` hacían fallar `docker compose config`. → Task 2 ampliada.
   Commit `eb17f18`.
3. **Doble `bash -c` + comillas simples** en el `command` de `sara3-single`:
   el test "pasaba" (exit 0) pero Gradle nunca corría. Lo detectó la
   verificación de la Task 4. → `command` como string único.
   Commit `977db8b`.

Otros commits: Task 1 (guard TTY) `a85a80e`.

**Resultado final:** pipeline Docker **validado de extremo a extremo**. Tras el
fix #3, la corrida ejecutó realmente: Gradle compiló, Chrome arrancó en Xvfb,
interactuó con la app real y se generó `target/site/serenity/index.html`. El
test funcional **falló** (`1 test completed, 1 failed`) por un
`org.openqa.selenium.TimeoutException` (120s) en el paso de negocio
"Transicionar caso adaptativo" — falla de la **app destino**, no de la
infraestructura. Objetivo del smoke (validar el pipeline) **cumplido**.
