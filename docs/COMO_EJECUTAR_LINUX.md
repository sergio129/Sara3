# Cómo ejecutar SARA3 en Linux (Docker)

Guía para correr las pruebas de automatización SARA3 en Linux usando Docker.
No necesitas instalar Java ni Chrome en el host: la imagen `selenium/standalone-chrome`
ya trae Chrome + Xvfb, y el JDK 11 se incluye en la imagen.

## Requisitos

- Docker y Docker Compose v2 (`docker compose ...`)
- Conexión a internet (solo la primera build descarga imágenes y dependencias)
- ~4 GB de RAM disponibles para el contenedor

Verifica:

```bash
docker --version
docker compose version
```

## 1. Construir la imagen (solo la primera vez o tras cambiar código)

```bash
cd /ruta/al/proyecto   # raíz del repo (donde está docker-compose.yml)
docker compose build sara3-single
```

La imagen resultante se llama `sara3:latest`.

> ⚠️ El código de los tests se copia **dentro** de la imagen al construir.
> Si modificas Java, features o `*.properties`, vuelve a construir antes de ejecutar.
> Si solo cambias `docker-compose.yml` (por ejemplo `TEST_NUM`), **no** hace falta rebuild.

## 2. Ejecutar el smoke test (un runner)

Corre `CasesRunner01` (definido por `TEST_NUM` en `docker-compose.yml`):

```bash
docker compose run --rm sara3-single
```

Guardando el log (recomendado):

```bash
docker compose run --rm sara3-single > logs/smoke-casesrunner01.log 2>&1
```

### Ejecutar otro runner (01–50)

Sobreescribe `TEST_NUM` sin editar archivos (usa 2 dígitos):

```bash
docker compose run --rm -e TEST_NUM=15 sara3-single
```

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

## 3. Ver los resultados

### Reporte Serenity (HTML interactivo) — lo principal

```bash
xdg-open target/site/serenity/index.html
```

Incluye escenarios, pasos, screenshots y la causa de cada fallo.

### Resumen rápido desde el log

```bash
grep -E "BUILD SUCCESSFUL|BUILD FAILED|Tests passed|Tests failed" logs/smoke-casesrunner01.log
```

### Causa de una falla

```bash
grep -iE "STEP ERROR|Test failed at step|Exception|TimeoutException" logs/smoke-casesrunner01.log | head
```

## Interpretar el resultado

- **Exit code 0 + `BUILD SUCCESSFUL` + `Tests passed | 1`** → todo OK.
- **`BUILD FAILED` pero Gradle compiló y Xvfb levantó** → el pipeline Docker
  funciona; la falla es **funcional de la app destino** (login, timeouts,
  estado de la app), no de la infraestructura. Revisa el reporte Serenity.

## Notas técnicas

- **Headless:** Chrome corre dentro de un display virtual Xvfb (`:99`) que el
  `docker-entrypoint.sh` levanta automáticamente.
- **Volúmenes:** el reporte se monta al host en `target/site/` y `target/reports/`;
  los logs en `logs/`.
- **Recursos:** el servicio `sara3-single` está limitado a 1 CPU / 2 GB
  (configurable en `docker-compose.yml` bajo `deploy.resources`).

## Otros servicios definidos en docker-compose.yml

| Servicio | Uso |
|----------|-----|
| `sara3-single` | Un runner individual (smoke / debugging) — **el de esta guía** |
| `sara3-interactive` | Menú interactivo (`run_tests.sh`) — requiere `-it` |
| `sara3-batch` | Ejecución en paralelo (referencia `batch_test_8p.sh`, aún no incluido) |
