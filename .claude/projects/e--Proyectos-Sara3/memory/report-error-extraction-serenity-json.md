---
name: report-error-extraction-serenity-json
description: Cómo los reportes Excel/CSV/HTML de Sara3 extraen el detalle del error desde el JSON de Serenity
metadata:
  type: project
---

Los reportes de pasos en Sara3 se generan con `script/generate_step_details_excel_report_CLEAN.ps1` (invocado por `run_tests.bat` opción 14) y se consolidan con `script/consolidate_reports_xlsx.ps1`. Leen los JSON de `target/site/serenity/*.json`.

El detalle del error de cada paso está en `step.exception` como OBJETO: `{ errorType, message, stackTrace }` (NO string). Los fallos se marcan con `result` en ERROR/FAILURE/COMPROMISED. El origen (archivo:línea) sale del primer frame de `stackTrace` cuyo `declaringClass` empieza por `com.sara.automation.*`.

Columnas resultantes: `Error Type` (categoría vía Get-ErrorType), `Error Message` (`[clase] mensaje`), `Origen Error` (`Archivo.java:línea`). Presentes en CSV, hoja Excel "Todos los Pasos"/HTML y propagadas al consolidado.

**Why:** Antes el script tenía bugs: asignaba `step.exception` (objeto) como string y llamaba `Get-ErrorType -message` cuando el parámetro es `-errorMessage`, por lo que no capturaba nada útil.

**How to apply:** Esta extracción es independiente del nivel de capturas — da el motivo del fallo en texto sin necesidad de subir screenshots. Ver [[serenity-screenshot-level-iframe]].
