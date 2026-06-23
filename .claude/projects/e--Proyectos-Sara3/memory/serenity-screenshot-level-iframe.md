---
name: serenity-screenshot-level-iframe
description: Subir el nivel de capturas de Serenity rompe la automatización en apps con iframe (Form.io)
metadata:
  type: project
---

En Sara3, subir `serenity.take.screenshots` a `FOR_EACH_ACTION` y activar `full.page.screenshot.enabled = true` (en `serenity.conf`) ROMPE la automatización: la captura full-page hace `switchTo().defaultContent()` después de cada acción, sacando el contexto del iframe `form_onescript_iframe`. El siguiente `Enter`/`findElement` falla con `NoSuchElementException` (ej. `input[name='data[direccion_servicio]']` tras seleccionar municipio) aunque el campo exista. También causa `Connection reset` en el WebSocket.

Config estable (commit 26d0ddd): `serenity.conf` → `take.screenshots = FOR_FAILURES`; `serenity.properties` → `AFTER_EACH_STEP` (el `.conf` tiene prioridad, así que el nivel efectivo es FOR_FAILURES).

**Why:** El formulario es Form.io dentro de un iframe; las capturas agresivas cambian el frame activo y desestabilizan la sesión.

**How to apply:** Para ver el motivo de un fallo NO subir el nivel de capturas. Los scripts de reporte ya extraen el detalle del error del JSON de Serenity (`step.exception` → Error Type / Error Message / Origen Error archivo:línea). Mantener `FOR_FAILURES`. Ver [[report-error-extraction-serenity-json]].
