# Flujo paralelo configurable `sara3-batch` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dejar el servicio `sara3-batch` ejecutando las 50 clases `CasesRunner01-50` con un grado de paralelismo configurable por la perilla `RUNNERS` (default 8), reemplazando el `command` roto que apunta a un script inexistente.

**Architecture:** Edición de un único bloque (`sara3-batch`) en `docker-compose.yml`: el `command` pasa a ser un string único `./gradlew test --parallel --continue -PmaxParallelForks=${RUNNERS}` (el entrypoint hace `bash -c "$@"` y expande `${RUNNERS}`), se corrige `CHROME_BIN`, se ajusta el techo de recursos del contenedor y se documenta el uso.

**Tech Stack:** Docker Compose, Gradle 8.10.2 (project property `maxParallelForks`), Serenity BDD, Selenium standalone-chrome.

**Nota sobre verificación:** Cambios de infraestructura, sin tests unitarios. La verificación es: `docker compose config` (estático) + una corrida ligera sin app (gradle `help` con `-PmaxParallelForks`) que prueba la expansión de `${RUNNERS}` end-to-end. NO se valida corriendo las 50 clases (tardaría horas y golpea la app remota).

---

## Estructura de archivos

- Modify: `docker-compose.yml` — servicio `sara3-batch` (command, environment, deploy.resources).
- Modify: `docs/COMO_EJECUTAR_LINUX.md` — documentar el uso del batch configurable.

---

## Task 1: Reconfigurar el servicio `sara3-batch`

**Files:**
- Modify: `docker-compose.yml` (bloque `sara3-batch`, ~líneas 7-52)

**Contexto:** Hoy `sara3-batch` tiene `command: ./batch_test_8p.sh` (archivo
inexistente), `CHROME_BIN` a `chromium-browser` (la imagen Selenium usa
`google-chrome`), una env `maxParallelForks: "8"` que no llega a Gradle, y un
techo de recursos de 2 CPU / 4 GB (insuficiente para 8 forks). Estos tres bloques
están dentro del servicio `sara3-batch`; el bloque de `deploy` de `sara3-batch`
es identificable porque va seguido de `restart_policy:` (único de este servicio).

- [ ] **Step 1: Corregir `environment` (CHROME_BIN + RUNNERS)**

Reemplazar:

```yaml
      CHROME_BIN: "/usr/bin/chromium-browser"
      maxParallelForks: "8"
```

por:

```yaml
      CHROME_BIN: "/usr/bin/google-chrome"
      RUNNERS: "8"
```

- [ ] **Step 2: Subir el techo de recursos del contenedor**

Reemplazar (el bloque `limits`/`reservations` de `sara3-batch`, el que está
inmediatamente seguido de `restart_policy:`):

```yaml
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
      restart_policy:
```

por:

```yaml
    deploy:
      resources:
        limits:
          cpus: '16'
          memory: 32G
        reservations:
          cpus: '2'
          memory: 4G
      restart_policy:
```

- [ ] **Step 3: Reemplazar el `command` roto**

Reemplazar:

```yaml
    # Comando
    command: ./batch_test_8p.sh
```

por:

```yaml
    # Comando: corre las 50 clases con N forks en paralelo (RUNNERS).
    # El entrypoint ya hace `bash -c "$@"`, por eso va como string único
    # (sin envolver en otro bash -c) para que ${RUNNERS} se expanda en el contenedor.
    command: ["./gradlew test --parallel --continue -PmaxParallelForks=$${RUNNERS}"]
```

- [ ] **Step 4: Validar el compose**

Run: `docker compose config --quiet`
Expected: exit 0 (solo posible warning cosmético de `version`, no bloqueante).

- [ ] **Step 5: Confirmar la resolución del servicio**

Run: `docker compose config sara3-batch | grep -E "command:|RUNNERS|CHROME_BIN|memory:|cpus:" `
Expected: el `command` aparece como lista con
`./gradlew test --parallel --continue -PmaxParallelForks=$${RUNNERS}`;
`CHROME_BIN: /usr/bin/google-chrome`; `RUNNERS: "8"`; `memory: "32G"` y
`cpus: "16"` en limits.

- [ ] **Step 6: Commit**

```bash
git add docker-compose.yml
git commit -m "feat(docker): sara3-batch corre las 50 clases con paralelismo configurable (RUNNERS)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Validación ligera de la expansión de RUNNERS (sin app)

**Files:** ninguno (corrida de verificación; requiere Docker y red, fuera de sandbox)

**Contexto:** Validar end-to-end que el comando único llega al entrypoint, que
`${RUNNERS}` se expande, y que Gradle acepta `-PmaxParallelForks` — sin correr las
50 clases ni tocar la app remota. Se usa `./gradlew help` (rápido) con un
`RUNNERS` de prueba, sobreescribiendo el `command` con un string único (el
entrypoint lo ejecuta vía `bash -c "$@"`).

- [ ] **Step 1: Ejecutar la verificación con RUNNERS=7**

Run:
```bash
docker compose run --rm -e RUNNERS=7 sara3-batch 'echo PARALELISMO=$RUNNERS && ./gradlew help -q -PmaxParallelForks=$RUNNERS && echo GRADLE_ACEPTA_P_OK' 2>&1 | tee logs/batch-validate.log
```
Expected: en el log aparecen `PARALELISMO=7` y `GRADLE_ACEPTA_P_OK`, sin
`BUILD FAILED`. (Las comillas simples evitan que el shell del host expanda
`$RUNNERS`; lo expande el bash del contenedor con `RUNNERS=7`.)

- [ ] **Step 2: Confirmar la evidencia**

Run: `grep -E "PARALELISMO=7|GRADLE_ACEPTA_P_OK|BUILD SUCCESSFUL" logs/batch-validate.log`
Expected: las tres líneas presentes (expansión OK + Gradle acepta `-PmaxParallelForks` + build de `help` exitoso).

> Esto prueba el mecanismo completo. La corrida real de las 50 clases
> (`docker compose run --rm sara3-batch`) queda a criterio del usuario por su
> duración (horas) y carga sobre la app destino.

---

## Task 3: Documentar el batch en COMO_EJECUTAR_LINUX.md

**Files:**
- Modify: `docs/COMO_EJECUTAR_LINUX.md`

**Contexto:** La guía actual solo cubre `sara3-single`. Añadir una sección para el
flujo paralelo, alineada con el `command` y la perilla `RUNNERS` de la Task 1.

- [ ] **Step 1: Añadir la sección de batch**

Insertar, después de la sección "## 2. Ejecutar el smoke test (un runner)" y
antes de "## 3. Ver los resultados", el siguiente bloque:

```markdown
## 2b. Ejecutar en paralelo (todas las clases)

El servicio `sara3-batch` corre las **50 clases** `CasesRunner01-50` con N en
paralelo. La perilla es la variable `RUNNERS` (default `8`):

```bash
# Default: 8 en paralelo
docker compose run --rm sara3-batch

# Cambiar el paralelismo sin editar archivos
docker compose run --rm -e RUNNERS=12 sara3-batch
```

Guía rápida de capacidad en este hardware (~39 GB libres, 20 cores), a ~2 GB por
runner:

| RUNNERS | RAM aprox. | Recomendación |
|---------|-----------|----------------|
| 4  | ~8 GB  | Conservador, máxima estabilidad |
| 8  | ~20 GB | **Recomendado** |
| 12 | ~28 GB | Agresivo; vigilar timeouts de la app |

> Subir `RUNNERS` por encima de ~12 requiere elevar también el techo de recursos
> del contenedor (`deploy.resources.limits` de `sara3-batch`, hoy 16 CPU / 32 GB).
> Muchos forks golpean la misma app remota → más probabilidad de `TimeoutException`;
> el batch usa `--continue` para que un fallo no tumbe la corrida completa.
```

- [ ] **Step 2: Verificar que la sección quedó**

Run: `grep -n "2b. Ejecutar en paralelo\|RUNNERS=12" docs/COMO_EJECUTAR_LINUX.md`
Expected: dos coincidencias.

- [ ] **Step 3: Commit**

```bash
git add docs/COMO_EJECUTAR_LINUX.md
git commit -m "docs: documentar flujo paralelo sara3-batch (RUNNERS) en guia Linux

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

- **Spec coverage:** Task 1 implementa el `command` único, `RUNNERS`, `CHROME_BIN`
  y el techo de recursos (todas las secciones de Arquitectura del spec). Task 2
  cubre "Verificación de éxito" (config + arranque/parallelismo) de forma
  práctica sin correr las 50. Task 3 cubre la sección "Uso" del spec en la guía.
  Fuera de alcance (no crear `batch_test_8p.sh`, no tocar single/interactive, sin
  segunda perilla, sin tocar `gradle.properties`) respetado.
- **Placeholder scan:** sin TBD/TODO; cada step tiene comando y salida esperada
  concretos.
- **Type consistency:** nombres consistentes en todas las tareas — `sara3-batch`,
  `RUNNERS` (env), `-PmaxParallelForks` (gradle property), `/usr/bin/google-chrome`,
  límites `16` CPU / `32G`.
