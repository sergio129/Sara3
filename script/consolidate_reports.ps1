# ============================================
# Consolidate Multiple Test Reports (CSV)
# ============================================
# Este script consolida múltiples reportes CSV de diferentes máquinas
# en un solo reporte unificado con análisis comparativo
# 
# USO:
# 1. Copia los archivos step_details_*.csv de cada máquina a: .\reports_consolidation\
# 2. Ejecuta consolidate_reports.bat
# 3. El reporte consolidado se genera en: .\reports_consolidation\consolidated_report_*.xlsx

param(
    [string]$inputFolder = ".\reports_consolidation",
    [string]$outputFolder = ".\reports_consolidation",
    [string]$outputFileName = "consolidated_report",
    [switch]$NoWait = $false
)

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  CONSOLIDADOR DE REPORTES CSV" -ForegroundColor Cyan
Write-Host "  Multiple Machines Report Consolidation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Crear carpeta de entrada si no existe
if (-not (Test-Path $inputFolder)) {
    New-Item -ItemType Directory -Path $inputFolder | Out-Null
    Write-Host "[INFO] Carpeta creada: $inputFolder" -ForegroundColor Green
    Write-Host "[INFO] Copia aquí los archivos step_details_*.csv de otras máquinas" -ForegroundColor Yellow
    Write-Host ""
}

# Crear carpeta de salida si no existe (misma que entrada)
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Buscar todos los archivos CSV en la carpeta de entrada
$csvFiles = Get-ChildItem -Path $inputFolder -Filter "step_details_*.csv" -ErrorAction SilentlyContinue

if ($csvFiles.Count -eq 0) {
    Write-Host "[ADVERTENCIA] No se encontraron archivos CSV en: $inputFolder" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Instrucciones:" -ForegroundColor Cyan
    Write-Host "1. Copia los archivos step_details_*.csv de cada máquina a: $inputFolder" -ForegroundColor White
    Write-Host "2. Ejecuta este script nuevamente (o usa consolidate_reports.bat)" -ForegroundColor White
    Write-Host ""
    pause
    exit 0
}

Write-Host "[INFO] Encontrados $($csvFiles.Count) archivos CSV para consolidar:" -ForegroundColor Green
foreach ($file in $csvFiles) {
    Write-Host "  - $($file.Name) ($([math]::Round($file.Length/1KB, 2)) KB)" -ForegroundColor White
}
Write-Host ""

# ============================================
# PROCESAR TODOS LOS ARCHIVOS CSV
# ============================================
Write-Host "[INFO] Procesando archivos CSV..." -ForegroundColor Cyan

$allSteps = @()

foreach ($file in $csvFiles) {
    Write-Host "  Leyendo: $($file.Name)..." -ForegroundColor White
    
    try {
        # Leer CSV con encoding UTF-8
        $csvData = Import-Csv -Path $file.FullName -Encoding UTF8
        
        # Agregar columna de origen (nombre del archivo)
        $csvData | ForEach-Object {
            $_ | Add-Member -NotePropertyName "Archivo Origen" -NotePropertyValue $file.Name -Force
        }
        
        $allSteps += $csvData
        Write-Host "    OK: $($csvData.Count) pasos cargados" -ForegroundColor Green
        
    } catch {
        Write-Host "    ERROR: No se pudo leer el archivo: $($file.Name)" -ForegroundColor Red
        Write-Host "    Detalle: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[OK] Archivos procesados correctamente" -ForegroundColor Green
Write-Host "  - Total pasos consolidados: $($allSteps.Count)" -ForegroundColor White
Write-Host ""

# ============================================
# GENERAR ANÁLISIS CONSOLIDADO
# ============================================
Write-Host "[INFO] Generando análisis consolidado..." -ForegroundColor Cyan

# Obtener lista única de tests (agrupando por Test + Máquina + Usuario para preservar todos los usuarios)
# Esto crea una "ejecución" única por cada combinación test/máquina/usuario
$uniqueTestExecutions = $allSteps | Group-Object { "$($_.Test)|||$($_.Maquina)|||$($_.Usuario)" }

# Calcular estadísticas por test
$testStats = $uniqueTestExecutions | ForEach-Object {
    $parts = $_.Name -split '\|\|\|'
    $testName = $parts[0]
    $maquina = $parts[1]
    $usuario = $parts[2]
    $steps = $_.Group
    $batch = ($steps | Select-Object -First 1).Batch
    
    # El test FALLÓ si algún paso tiene "Error Type" con valor (el report_clean solo llena esa
    # columna en pasos con fallo, con categoría Selenium/UI/Data/Validacion/Otros).
    # NOTA: antes se comparaba con el literal "ERROR", que NUNCA aparece en ese CSV -> contaba
    # todo como PASSED. Ahora se detecta por "Error Type" no vacío.
    $pasosConError = $steps | Where-Object { $_."Error Type" -and ([string]$_."Error Type").Trim() -ne "" }
    $tieneError = @($pasosConError).Count -gt 0
    $estado = if ($tieneError) { "FAILED" } else { "PASSED" }

    # Error type, message y origen (archivo:linea) del primer paso con error
    $primerError = $pasosConError | Select-Object -First 1
    $errorType = if ($primerError) { $primerError."Error Type" } else { "" }
    $errorMsg = if ($primerError) { $primerError."Error Message" } else { "" }
    $errorSource = if ($primerError) { $primerError."Origen Error" } else { "" }

    $totalPasos = $steps.Count
    $pasosLentos = ($steps | Where-Object { $_."Tiempo (ms)" -gt 5000 }).Count
    $tiempoTotalMs = ($steps | Measure-Object -Property "Tiempo (ms)" -Sum).Sum
    $tiempoTotalMin = [math]::Round($tiempoTotalMs / 60000, 2)

    [PSCustomObject]@{
        "Test" = $testName
        "Batch" = $batch
        "Maquina" = $maquina
        "Usuario" = $usuario
        "Total Pasos" = $totalPasos
        "Pasos Lentos" = $pasosLentos
        "Tiempo Total (min)" = $tiempoTotalMin
        "Estado" = $estado
        "Error Type" = $errorType
        "Error Message" = $errorMsg
        "Origen Error" = $errorSource
    }
}

# Pasos lentos (>5s)
$slowSteps = $allSteps | Where-Object { $_."Tiempo (ms)" -gt 5000 } | Sort-Object { [int]$_."Tiempo (ms)" } -Descending

# Resumen General Consolidado
$totalTests = $testStats.Count
$totalPassed = ($testStats | Where-Object { $_.Estado -eq "PASSED" }).Count
$totalFailed = ($testStats | Where-Object { $_.Estado -eq "FAILED" }).Count
$totalSteps = $allSteps.Count
$totalSlowSteps = $slowSteps.Count

# Contar máquinas únicas del CSV original (no de testStats)
$uniqueMachines = @($allSteps | Select-Object -Unique Maquina | Where-Object { $_.Maquina -and $_.Maquina.Trim() -ne "" }).Count
if ($uniqueMachines -eq 0) {
    $uniqueMachines = ($allSteps | Select-Object -Unique Maquina).Count
}

# Tests fallidos
$failedTests = $testStats | Where-Object { $_.Estado -eq "FAILED" }

$resumenGeneral = @()
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Fecha Consolidación"; "Valor" = (Get-Date -Format "dd/MM/yyyy HH:mm:ss") }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Archivos Procesados"; "Valor" = $csvFiles.Count }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Total Máquinas"; "Valor" = $uniqueMachines }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Total Tests Ejecutados"; "Valor" = $totalTests }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Tests Exitosos"; "Valor" = $totalPassed }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Tests Fallidos"; "Valor" = $totalFailed }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Tasa de Éxito %"; "Valor" = if($totalTests -gt 0) { [math]::Round(($totalPassed / $totalTests) * 100, 2) } else { 0 } }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Total Pasos Ejecutados"; "Valor" = $totalSteps }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Total Pasos Lentos (>5s)"; "Valor" = $totalSlowSteps }

# Estadísticas por Máquina
$statsByMachine = $testStats | Where-Object { $_.Maquina -and $_.Maquina.Trim() -ne "" } | Group-Object Maquina | ForEach-Object {
    $machine = $_.Name
    $tests = $_.Group
    $passed = ($tests | Where-Object { $_.Estado -eq "PASSED" }).Count
    $failed = ($tests | Where-Object { $_.Estado -eq "FAILED" }).Count
    $avgTime = ($tests | Measure-Object -Property "Tiempo Total (min)" -Average).Average
    
    [PSCustomObject]@{
        "Máquina" = $machine
        "Usuario" = ($tests | Select-Object -First 1).Usuario
        "Total Tests" = $tests.Count
        "Tests Exitosos" = $passed
        "Tests Fallidos" = $failed
        "Tasa Éxito %" = if($tests.Count -gt 0) { [math]::Round(($passed / $tests.Count) * 100, 2) } else { 0 }
        "Tiempo Promedio (min)" = [math]::Round($avgTime, 2)
    }
} | Sort-Object "Tests Fallidos" -Descending

# Estadísticas por Usuario
$statsByUser = $testStats | Where-Object { $_.Usuario -and $_.Usuario.Trim() -ne "" } | Group-Object Usuario | ForEach-Object {
    $usuario = $_.Name
    $tests = $_.Group
    $passed = ($tests | Where-Object { $_.Estado -eq "PASSED" }).Count
    $failed = ($tests | Where-Object { $_.Estado -eq "FAILED" }).Count
    $avgTime = ($tests | Measure-Object -Property "Tiempo Total (min)" -Average).Average
    $maquinas = ($tests | Select-Object -Unique Maquina).Count
    
    [PSCustomObject]@{
        "Usuario" = $usuario
        "Total Tests" = $tests.Count
        "Tests Exitosos" = $passed
        "Tests Fallidos" = $failed
        "Tasa Exito %" = if($tests.Count -gt 0) { [math]::Round(($passed / $tests.Count) * 100, 2) } else { 0 }
        "Tiempo Promedio (min)" = [math]::Round($avgTime, 2)
        "Maquinas Usadas" = $maquinas
        "Pasos Lentos" = ($tests | Measure-Object -Property "Pasos Lentos" -Sum).Sum
    }
} | Sort-Object "Tests Fallidos" -Descending

# Distribución de Errores Consolidada
$errorDistribution = $null
if ($totalFailed -gt 0) {
    $errorDistribution = $failedTests | Group-Object "Error Type" | 
        Select-Object @{N="Error Type"; E={$_.Name}},
                      @{N="Cantidad"; E={$_.Count}},
                      @{N="Porcentaje"; E={[math]::Round(($_.Count / $totalFailed) * 100, 2)}} |
        Sort-Object Cantidad -Descending
}

# Estadísticas por Batch Consolidadas
$statsByBatch = $testStats | Group-Object Batch | ForEach-Object {
    $batch = $_.Name
    $tests = $_.Group
    $passed = ($tests | Where-Object { $_.Estado -eq "PASSED" }).Count
    $failed = ($tests | Where-Object { $_.Estado -eq "FAILED" }).Count
    
    [PSCustomObject]@{
        "Batch" = $batch
        "Total Tests" = $tests.Count
        "Exitosos" = $passed
        "Fallidos" = $failed
        "Tasa Error %" = if($tests.Count -gt 0) { [math]::Round(($failed / $tests.Count) * 100, 2) } else { 0 }
        "Máquinas Ejecutoras" = ($tests | Select-Object -Unique Maquina).Count
    }
} | Sort-Object Batch

# ============================================
# GENERAR REPORTES CONSOLIDADOS
# ============================================
Write-Host ""
Write-Host "[INFO] Generando reportes consolidados..." -ForegroundColor Cyan

# 1. CSV Consolidado (TODOS LOS PASOS)
$csvConsolidatedPath = "$outputFolder\${outputFileName}_$timestamp.csv"
$allSteps | Export-Csv -Path $csvConsolidatedPath -NoTypeInformation -Encoding UTF8
Write-Host "  - CSV generado: $csvConsolidatedPath" -ForegroundColor Green

# 2. CSV de Estadísticas por Test
$csvStatsPath = "$outputFolder\${outputFileName}_stats_$timestamp.csv"
$testStats | Export-Csv -Path $csvStatsPath -NoTypeInformation -Encoding UTF8
Write-Host "  - CSV Stats generado: $csvStatsPath" -ForegroundColor Green

# 3. CSV de Estadísticas por Máquina
$csvMachinePath = "$outputFolder\${outputFileName}_by_machine_$timestamp.csv"
$statsByMachine | Export-Csv -Path $csvMachinePath -NoTypeInformation -Encoding UTF8
Write-Host "  - CSV Máquinas generado: $csvMachinePath" -ForegroundColor Green

# 4. CSV de Estadísticas por Usuario
$csvUserPath = "$outputFolder\${outputFileName}_by_user_$timestamp.csv"
$statsByUser | Export-Csv -Path $csvUserPath -NoTypeInformation -Encoding UTF8
Write-Host "  - CSV Usuarios generado: $csvUserPath" -ForegroundColor Green

# 4. Intentar generar Excel (si ImportExcel está disponible)
$excelGenerated = $false
Write-Host "[INFO] Intentando generar Excel..." -ForegroundColor Cyan

try {
    # Intentar cargar ImportExcel sin verificaciones previas
    Import-Module ImportExcel -WarningAction SilentlyContinue -ErrorAction Stop
    
    $excelPath = "$outputFolder\${outputFileName}_$timestamp.xlsx"
    Write-Host "  Generando: $excelPath" -ForegroundColor White
    
    # Hoja 1: Resumen General
    $resumenGeneral | Export-Excel -Path $excelPath -WorksheetName "Resumen General" -AutoSize -TableStyle "Medium2"
    Write-Host "  OK Hoja 1: Resumen General" -ForegroundColor Green
    
    # Hoja 2: Estadísticas por Usuario
    if ($statsByUser.Count -gt 0) {
        $statsByUser | Export-Excel -Path $excelPath -WorksheetName "Por Usuario" -AutoSize -TableStyle "Medium2" -Append
        Write-Host "  OK Hoja 2: Por Usuario ($($statsByUser.Count) usuarios)" -ForegroundColor Green
    }
    
    # Hoja 3: Estadísticas por Máquina
    if ($statsByMachine.Count -gt 0) {
        $statsByMachine | Export-Excel -Path $excelPath -WorksheetName "Por Maquina" -AutoSize -TableStyle "Medium2" -Append
        Write-Host "  OK Hoja 3: Por Maquina" -ForegroundColor Green
    }
    
    # Hoja 4: Estadísticas por Test
    if ($testStats.Count -gt 0) {
        $testStats | Export-Excel -Path $excelPath -WorksheetName "Estadisticas por Test" -AutoSize -TableStyle "Light1" -Append
        Write-Host "  OK Hoja 4: Estadisticas por Test" -ForegroundColor Green
    }
    
    # Hoja 5: Detalles de Pasos Completos (paso a paso con elemento, valor, acción)
    if ($allSteps.Count -gt 0) {
        $pasosParaMostrar = $allSteps | Select-Object Test, Batch, Maquina, Usuario, Descripcion, Elemento, Valor, Accion, Nivel, "Tiempo (ms)", "Error Type", "Error Message" | Select-Object -First 5000
        $pasosParaMostrar | Export-Excel -Path $excelPath -WorksheetName "Detalles Paso a Paso" -AutoSize -TableStyle "Light1" -Append
        Write-Host "  OK Hoja 5: Detalles Paso a Paso (primeros 5000 de $($allSteps.Count))" -ForegroundColor Green
    }
    
    # Hoja 6: Tests Fallidos con Errores
    if ($failedTests.Count -gt 0) {
        $failedTestsDetailed = $failedTests | Select-Object Test, Batch, Maquina, Usuario, "Total Pasos", "Pasos Lentos", "Tiempo Total (min)", "Error Type", "Error Message"
        $failedTestsDetailed | Export-Excel -Path $excelPath -WorksheetName "Tests Fallidos + Errores" -AutoSize -TableStyle "Light1" -Append
        Write-Host "  OK Hoja 6: Tests Fallidos + Errores ($($failedTests.Count))" -ForegroundColor Green
    }
    
    # Hoja 7: Análisis de Errores Comunes
    $erroresComunes = @()
    if ($allSteps.Count -gt 0) {
        $stepsConError = $allSteps | Where-Object { $_."Error Type" -and $_."Error Type".Trim() -ne "" }
        
        if ($stepsConError.Count -gt 0) {
            # Extraer tipo de error
            $tiposError = $stepsConError | Group-Object "Error Type" | ForEach-Object {
                $errorType = $_.Name
                # Obtener primer mensaje de error como ejemplo
                $primerMensaje = ($_.Group | Select-Object -First 1 -ExpandProperty "Error Message")
                $resumenError = if ($primerMensaje) { 
                    $primerMensaje.Split([Environment]::NewLine)[0].Substring(0, [Math]::Min(100, $primerMensaje.Length)) 
                } else { 
                    "Sin detalle" 
                }
                
                [PSCustomObject]@{
                    "Tipo Error" = $errorType
                    "Cantidad" = $_.Count
                    "Porcentaje %" = [math]::Round(($_.Count / $stepsConError.Count) * 100, 2)
                    "Ejemplo Mensaje" = $resumenError
                }
            } | Sort-Object Cantidad -Descending | Select-Object -First 30
            
            $erroresComunes = @($tiposError)
        }
    }
    
    if ($erroresComunes.Count -gt 0) {
        $erroresComunes | Export-Excel -Path $excelPath -WorksheetName "Errores Comunes" -AutoSize -TableStyle "Light1" -Append
        Write-Host "  OK Hoja 7: Errores Comunes (Top $($erroresComunes.Count))" -ForegroundColor Green
    }
    
    # Hoja 8: Pasos Lentos (solo top 1000)
    if ($slowSteps.Count -gt 0) {
        $slowSteps | Select-Object -First 1000 | Export-Excel -Path $excelPath -WorksheetName "Pasos Lentos (Top 1k)" -AutoSize -TableStyle "Light1" -Append
        Write-Host "  OK Hoja 8: Pasos Lentos (primeros 1000 de $($slowSteps.Count))" -ForegroundColor Green
    }
    
    $excelFileInfo = Get-Item $excelPath
    $excelSizeMB = [math]::Round($excelFileInfo.Length / 1MB, 2)
    Write-Host "  - Excel generado: $excelPath" -ForegroundColor Green
    Write-Host "    Tamano: $excelSizeMB MB" -ForegroundColor Green
    $excelGenerated = $true
    
} catch {
    Write-Host "  - Excel NO generado: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================"  -ForegroundColor Green
Write-Host "  CONSOLIDACION COMPLETADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "ARCHIVOS GENERADOS:" -ForegroundColor Yellow
Write-Host "  - $csvConsolidatedPath" -ForegroundColor Cyan
Write-Host "  - $csvStatsPath" -ForegroundColor Cyan
Write-Host "  - $csvMachinePath" -ForegroundColor Cyan
Write-Host "  - $csvUserPath" -ForegroundColor Cyan
if ($excelGenerated) {
    Write-Host "  - $excelPath" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "RESUMEN CONSOLIDADO:" -ForegroundColor Yellow
Write-Host ("  - Archivos CSV procesados: " + $csvFiles.Count) -ForegroundColor White
Write-Host ("  - Maquinas unicas: " + $uniqueMachines) -ForegroundColor White
Write-Host ("  - Total tests ejecutados: " + $totalTests) -ForegroundColor White
Write-Host ("  - Tests exitosos: " + $totalPassed) -ForegroundColor Green
Write-Host ("  - Tests fallidos: " + $totalFailed) -ForegroundColor Red
$tasaExito = if($totalTests -gt 0) { [math]::Round(($totalPassed / $totalTests) * 100, 2) } else { 0 }
Write-Host ("  - Tasa de exito: " + $tasaExito + "%") -ForegroundColor Cyan
Write-Host ("  - Total pasos: " + $totalSteps) -ForegroundColor White
Write-Host ("  - Pasos lentos (>5s): " + $totalSlowSteps) -ForegroundColor White
Write-Host ""
Write-Host "ESTADISTICAS POR MAQUINA:" -ForegroundColor Yellow
foreach ($item in $statsByMachine) {
    $maq = $item."Máquina"
    $tot = $item."Total Tests"
    $ok = $item."Tests Exitosos"
    $fail = $item."Tests Fallidos"
    $colorMaq = if($fail -eq 0) { "Green" } else { "Yellow" }
    Write-Host ("  - " + $maq + ": " + $tot + " tests (" + $ok + " OK, " + $fail + " FAIL)") -ForegroundColor $colorMaq
}
Write-Host ""
Write-Host "ESTADISTICAS POR USUARIO:" -ForegroundColor Yellow
foreach ($item in $statsByUser | Select-Object -First 15) {
    $usr = $item.Usuario
    $tot = $item."Total Tests"
    $ok = $item."Tests Exitosos"
    $fail = $item."Tests Fallidos"
    $tasa = $item."Tasa Exito %"
    $colorUsr = if($fail -eq 0) { "Green" } elseif($tasa -ge 50) { "Yellow" } else { "Red" }
    Write-Host ("  - " + $usr + ": " + $tot + " tests (" + $ok + " OK, " + $fail + " FAIL) - $tasa%") -ForegroundColor $colorUsr
}
if ($statsByUser.Count -gt 15) {
    Write-Host ("  ... y " + ($statsByUser.Count - 15) + " usuarios mas") -ForegroundColor Gray
}
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  METRICAS AVANZADAS DEL CONSOLIDADO" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# Analizar tests fallidos por tipo de error
if ($testStats -and $testStats.Count -gt 0) {
    Write-Host "TESTS FALLIDOS POR TIPO DE ERROR:" -ForegroundColor Yellow
    
    $failedTestsAnalysis = $testStats | Where-Object { $_.Estado -eq "FAILED" } | Group-Object "Error Type" | Sort-Object Count -Descending
    
    foreach ($errorGroup in $failedTestsAnalysis) {
        $errorName = if ([string]::IsNullOrWhiteSpace($errorGroup.Name)) { "(Sin especificar)" } else { $errorGroup.Name }
        $pct = [math]::Round(($errorGroup.Count / ($testStats | Where-Object { $_.Estado -eq "FAILED" }).Count) * 100, 2)
        Write-Host "  - $errorName`: $($errorGroup.Count) tests ($pct%)" -ForegroundColor Red
    }
    Write-Host ""
}

# Analizar pasos lentos por descripcion
if ($allSteps -and $allSteps.Count -gt 0) {
    Write-Host "TOP 5 PASOS MAS LENTOS (Bottlenecks):" -ForegroundColor Yellow
    
    $slowStepsByDesc = $allSteps | 
        Where-Object { [int]$_."Tiempo (ms)" -gt 5000 } | 
        Group-Object "Descripcion" | 
        ForEach-Object {
            $tiempos = @($_.Group | ForEach-Object { [int]$_."Tiempo (ms)" })
            [PSCustomObject]@{
                Descripcion = $_.Name
                Promedio = [math]::Round(($tiempos | Measure-Object -Average).Average, 0)
                Maximo = ($tiempos | Measure-Object -Maximum).Maximum
                Veces = $_.Count
            }
        } | 
        Sort-Object Promedio -Descending | 
        Select-Object -First 5
    
    foreach ($step in $slowStepsByDesc) {
        $desc = if ($step.Descripcion.Length -gt 50) { $step.Descripcion.Substring(0, 50) + "..." } else { $step.Descripcion }
        Write-Host "  - $desc" -ForegroundColor Yellow
        Write-Host "    Promedio: $($step.Promedio)ms, Max: $($step.Maximo)ms, Veces: $($step.Veces)" -ForegroundColor Gray
    }
    Write-Host ""
}

# Analizar distribucion de errores en pasos
if ($allSteps -and $allSteps.Count -gt 0) {
    Write-Host "DISTRIBUCION DE PASOS POR ESTADO:" -ForegroundColor Yellow
    
    $errorDistribution = $allSteps | Group-Object "Error Type" | Sort-Object Count -Descending
    
    foreach ($dist in $errorDistribution) {
        $pct = [math]::Round(($dist.Count / $allSteps.Count) * 100, 2)
        $color = if ($dist.Name -eq "ERROR") { "Red" } elseif ($dist.Name -eq "SKIPPED") { "Yellow" } else { "Green" }
        Write-Host "  - $($dist.Name): $($dist.Count) pasos ($pct%)" -ForegroundColor $color
    }
    Write-Host ""
}

# Analizar rendimiento relativo de maquinas
if ($statsByMachine -and $statsByMachine.Count -gt 1) {
    Write-Host "RANKING DE CONFIABILIDAD POR MAQUINA:" -ForegroundColor Yellow
    
    $machineRanking = $statsByMachine | Sort-Object "Tasa Exito %" -Descending | Select-Object -First 5
    
    $rank = 1
    foreach ($maq in $machineRanking) {
        $estado = if ($maq."Tasa Exito %" -ge 75) { "[OK]" } elseif ($maq."Tasa Exito %" -ge 50) { "[?]" } else { "[X]" }
        $color = if ($maq."Tasa Exito %" -ge 75) { "Green" } elseif ($maq."Tasa Exito %" -ge 50) { "Yellow" } else { "Red" }
        Write-Host "  $rank. $($maq.Maquina): $($maq.'Tasa Exito %')% $estado" -ForegroundColor $color
        $rank++
    }
    Write-Host ""
}

# Diagnostico: Es problema de test o herramienta?
Write-Host "DIAGNOSTICO:" -ForegroundColor Magenta
if ($totalFailed -gt 0) {
    $errorTestsPct = if ($totalTests -gt 0) { [math]::Round(($totalFailed / $totalTests) * 100, 2) } else { 0 }
    
    if ($errorTestsPct -gt 80) {
        Write-Host ("  ALERTA: Tasa fallo MUY alta (" + $errorTestsPct + "%)") -ForegroundColor Red
        Write-Host "  - Posible: Tests mal diseñados O infraestructura inestable" -ForegroundColor Yellow
    } elseif ($errorTestsPct -gt 50) {
        Write-Host ("  ALERTA: Tasa fallo significativa (" + $errorTestsPct + "%)") -ForegroundColor Red
        Write-Host "  - Revisar pasos lentos (bottlenecks)" -ForegroundColor Yellow
        Write-Host "  - Validar timeouts en configuracion" -ForegroundColor Yellow
    } else {
        Write-Host ("  Nivel de fallo moderado (" + $errorTestsPct + "%)") -ForegroundColor Yellow
        Write-Host "  - Enfocarse en los tests fallidos criticos" -ForegroundColor White
    }
} else {
    Write-Host "  EXCELENTE: Todos los tests pasaron!" -ForegroundColor Green
}

Write-Host ""
if (-not $NoWait) {
    Write-Host "Presiona cualquier tecla para continuar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
} else {
    Write-Host "Script ejecutado en modo automatico (sin pausas)" -ForegroundColor Green
}

