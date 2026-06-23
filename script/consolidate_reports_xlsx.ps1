# ============================================
# Consolidate Multiple Test Reports (XLSX)
# Versión mejorada que lee XLSX en lugar de CSV
# ============================================

param(
    [string]$inputFolder = ".\reports_consolidation",
    [string]$outputFolder = ".\reports_consolidation",
    [string]$outputFileName = "consolidated_report",
    [switch]$NoWait = $false
)

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  CONSOLIDADOR DE REPORTES XLSX" -ForegroundColor Cyan
Write-Host "  Multiple XLSX Report Consolidation (v2)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Crear carpeta de entrada si no existe
if (-not (Test-Path $inputFolder)) {
    New-Item -ItemType Directory -Path $inputFolder | Out-Null
    Write-Host "[INFO] Carpeta creada: $inputFolder" -ForegroundColor Green
}

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# ============================================
# Función para leer XLSX usando método alternativo
# ============================================
function Read-XlsxSheetSimple {
    param(
        [string]$XlsxPath,
        [string]$SheetName = "Todos los Pasos"
    )
    
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    
    if (-not (Test-Path $XlsxPath)) {
        return @()
    }
    
    $tempDir = Join-Path $env:TEMP "xlsx_read_$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        # Extraer XLSX (es un ZIP)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($XlsxPath, $tempDir)
        
        # Leer workbook.xml para encontrar el sheet
        $workbookPath = "$tempDir\xl\workbook.xml"
        if (-not (Test-Path $workbookPath)) {
            return @()
        }
        
        [xml]$workbookXml = Get-Content $workbookPath -Encoding UTF8
        $sheet = $workbookXml.workbook.sheets.sheet | Where-Object { $_.name -eq $SheetName }
        if (-not $sheet) {
            # Si no encuentra por nombre, tomar el primero
            $sheet = $workbookXml.workbook.sheets.sheet[0]
        }
        
        if (-not $sheet) {
            return @()
        }
        
        # Acceder al atributo r:id correctamente (con namespace)
        $rId = $sheet.GetAttribute('id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
        if (-not $rId) {
            # Fallback
            $rId = $sheet.Attributes['id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'].Value
        }
        if (-not $rId) {
            return @()
        }
        
        # Leer rels
        $relsPath = "$tempDir\xl\_rels\workbook.xml.rels"
        if (-not (Test-Path $relsPath)) {
            return @()
        }
        
        [xml]$relsXml = Get-Content $relsPath -Encoding UTF8
        $rel = $relsXml.Relationships.Relationship | Where-Object { $_.Id -eq $rId }
        if (-not $rel) {
            return @()
        }
        
        $sheetFile = $rel.Target
        $sheetPath = "$tempDir\xl\$sheetFile"
        
        if (-not (Test-Path $sheetPath)) {
            return @()
        }
        
        # Leer sheet (NO buscamos sharedStrings, los valores están directamente en las celdas)
        [xml]$sheetXml = Get-Content $sheetPath -Encoding UTF8
        
        # Procesar filas
        $result = @()
        $headers = @()
        $rowNum = 0
        
        foreach ($row in $sheetXml.worksheet.sheetData.row) {
            $rowNum++
            $rowData = @()
            
            foreach ($cell in $row.c) {
                # Los valores están directamente en $cell.v
                $cellValue = $cell.v
                $rowData += @($cellValue)
            }
            
            if ($rowNum -eq 1) {
                # Primera fila = headers
                $headers = $rowData
            } else {
                # Crear objeto
                $obj = [PSCustomObject]@{}
                for ($i = 0; $i -lt $headers.Count; $i++) {
                    if ($i -lt $rowData.Count) {
                        $obj | Add-Member -NotePropertyName $headers[$i] -NotePropertyValue $rowData[$i]
                    } else {
                        $obj | Add-Member -NotePropertyName $headers[$i] -NotePropertyValue $null
                    }
                }
                $result += @($obj)
            }
        }
        
        return $result
        
    } catch {
        Write-Host "  ERROR leyendo XLSX $($XlsxPath): $_" -ForegroundColor Red
        return @()
    } finally {
        # Limpiar
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ============================================
# Buscar archivos XLSX
# ============================================
$xlsxFiles = @(Get-ChildItem -Path $inputFolder -Filter "step_details_*.xlsx" -ErrorAction SilentlyContinue)

if ($xlsxFiles.Count -eq 0) {
    Write-Host "[ADVERTENCIA] No se encontraron archivos XLSX en: $inputFolder" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Instrucciones:" -ForegroundColor Cyan
    Write-Host "1. Copia los archivos step_details_*.xlsx a: $inputFolder" -ForegroundColor White
    Write-Host "2. Ejecuta este script nuevamente" -ForegroundColor White
    Write-Host ""
    if (-not $NoWait) { pause }
    exit 0
}

Write-Host "[INFO] Encontrados $($xlsxFiles.Count) archivos XLSX para consolidar:" -ForegroundColor Green
foreach ($file in $xlsxFiles) {
    Write-Host "  - $($file.Name) ($([math]::Round($file.Length/1KB, 2)) KB)" -ForegroundColor White
}
Write-Host ""

# ============================================
# Procesar todos los XLSX
# ============================================
Write-Host "[INFO] Procesando archivos XLSX..." -ForegroundColor Cyan

$allSteps = @()

foreach ($file in $xlsxFiles) {
    Write-Host "  Leyendo: $($file.Name)..." -ForegroundColor White
    
    try {
        # Leer hoja "Todos los Pasos" del XLSX
        $xlsxData = Read-XlsxSheetSimple -XlsxPath $file.FullName -SheetName "Todos los Pasos"
        
        if ($xlsxData.Count -eq 0) {
            Write-Host "    ADVERTENCIA: Sin datos o hoja no encontrada" -ForegroundColor Yellow
            continue
        }
        
        # Agregar columna de origen (crear nuevos objetos para evitar conflictos)
        $xlsxDataWithOrigin = @($xlsxData | ForEach-Object {
            $step = $_
            $propHash = @{}
            $step.PSObject.Properties | ForEach-Object {
                $propHash[$_.Name] = $_.Value
            }
            $propHash["Archivo Origen"] = $file.Name
            [PSCustomObject]$propHash
        })
        
        $allSteps += $xlsxDataWithOrigin
        Write-Host "    OK: $($xlsxData.Count) pasos cargados" -ForegroundColor Green
        
    } catch {
        Write-Host "    ERROR: No se pudo leer el archivo: $($file.Name)" -ForegroundColor Red
        Write-Host "    Detalle: $_" -ForegroundColor Red
    }
}

Write-Host ""

if ($allSteps.Count -eq 0) {
    Write-Host "[ERROR] No se cargaron datos de XLSX" -ForegroundColor Red
    if (-not $NoWait) { pause }
    exit 1
}

Write-Host "[OK] Archivos procesados correctamente" -ForegroundColor Green
Write-Host "  - Total pasos consolidados: $($allSteps.Count)" -ForegroundColor White
Write-Host ""

# ============================================
# Generar análisis
# ============================================
Write-Host "[INFO] Generando análisis consolidado..." -ForegroundColor Cyan

# Agrupar por Test + Máquina + Usuario
$uniqueTestExecutions = $allSteps | Group-Object { "$($_.Test)|||$($_.Maquina)|||$($_.Usuario)" }

# Estadísticas por test
$testStats = $uniqueTestExecutions | ForEach-Object {
    $parts = $_.Name -split '\|\|\|'
    $testName = $parts[0]
    $maquina = $parts[1]
    $usuario = $parts[2]
    $steps = $_.Group
    $batch = ($steps | Select-Object -First 1).Batch
    
    # Estado del test (si tiene error)
    $tieneError = ($steps | Where-Object { $_."Error Type" -and $_."Error Type".Trim() -ne "" }).Count -gt 0
    $estado = if ($tieneError) { "FAILED" } else { "PASSED" }
    
    $primerError = $steps | Where-Object { $_."Error Type" -and $_."Error Type".Trim() -ne "" } | Select-Object -First 1
    $errorType = if ($primerError) { $primerError."Error Type" } else { "" }
    $errorMsg = if ($primerError) { $primerError."Error Message" } else { "" }
    $errorSource = if ($primerError) { $primerError."Origen Error" } else { "" }
    
    $totalPasos = $steps.Count
    $pasosLentos = ($steps | Where-Object { [int]$_."Tiempo (ms)" -gt 5000 }).Count
    $tiempoPromedioPasoMs = ($steps | Measure-Object -Property "Tiempo (ms)" -Average -ErrorAction SilentlyContinue).Average
    $tiempoTotalMin = if ($tiempoPromedioPasoMs) { [math]::Round($tiempoPromedioPasoMs / 60000, 3) } else { 0 }
    
    [PSCustomObject]@{
        "Test" = $testName
        "Batch" = $batch
        "Maquina" = $maquina
        "Usuario" = $usuario
        "Total Pasos" = $totalPasos
        "Pasos Lentos" = $pasosLentos
        "Tiempo Promedio Paso (min)" = $tiempoTotalMin
        "Estado" = $estado
        "Error Type" = $errorType
        "Error Message" = $errorMsg
        "Origen Error" = $errorSource
    }
}

# Pasos lentos
$slowSteps = @($allSteps | Where-Object { [int]$_."Tiempo (ms)" -gt 5000 } | Sort-Object { [int]$_."Tiempo (ms)" } -Descending)

# Resumen general
$totalTests = $testStats.Count
$totalPassed = @($testStats | Where-Object { $_.Estado -eq "PASSED" }).Count
$totalFailed = @($testStats | Where-Object { $_.Estado -eq "FAILED" }).Count
$totalSteps = $allSteps.Count
$totalSlowSteps = $slowSteps.Count

$uniqueMachines = @($allSteps | Select-Object -Unique Maquina | Where-Object { $_.Maquina -and $_.Maquina.Trim() -ne "" }).Count

$failedTests = @($testStats | Where-Object { $_.Estado -eq "FAILED" })

$resumenGeneral = @()
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Fecha Consolidación"; "Valor" = (Get-Date -Format "dd/MM/yyyy HH:mm:ss") }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Archivos Procesados"; "Valor" = $xlsxFiles.Count }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Total Máquinas"; "Valor" = $uniqueMachines }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Total Tests Ejecutados"; "Valor" = $totalTests }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Tests Exitosos"; "Valor" = $totalPassed }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Tests Fallidos"; "Valor" = $totalFailed }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Tasa de Exito %"; "Valor" = if($totalTests -gt 0) { [math]::Round(($totalPassed / $totalTests) * 100, 2) } else { 0 } }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Total Pasos Ejecutados"; "Valor" = $totalSteps }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Total Pasos Lentos (>5s)"; "Valor" = $totalSlowSteps }

# Estadísticas por Máquina
$statsByMachine = @($testStats | Where-Object { $_.Maquina -and $_.Maquina.Trim() -ne "" } | Group-Object Maquina | ForEach-Object {
    $machine = $_.Name
    $tests = $_.Group
    $passed = @($tests | Where-Object { $_.Estado -eq "PASSED" }).Count
    $failed = @($tests | Where-Object { $_.Estado -eq "FAILED" }).Count
    $avgTime = ($tests | Measure-Object -Property "Tiempo Promedio Paso (min)" -Average -ErrorAction SilentlyContinue).Average
    
    [PSCustomObject]@{
        "Máquina" = $machine
        "Usuario" = ($tests | Select-Object -First 1).Usuario
        "Total Tests" = $tests.Count
        "Tests Exitosos" = $passed
        "Tests Fallidos" = $failed
        "Tasa Éxito %" = if($tests.Count -gt 0) { [math]::Round(($passed / $tests.Count) * 100, 2) } else { 0 }
        "Tiempo Promedio Paso (min)" = if ($avgTime) { [math]::Round($avgTime, 3) } else { 0 }
    }
} | Sort-Object "Tests Fallidos" -Descending)

# Estadísticas por Usuario
$statsByUser = @($testStats | Where-Object { $_.Usuario -and $_.Usuario.Trim() -ne "" } | Group-Object Usuario | ForEach-Object {
    $usuario = $_.Name
    $tests = $_.Group
    $passed = @($tests | Where-Object { $_.Estado -eq "PASSED" }).Count
    $failed = @($tests | Where-Object { $_.Estado -eq "FAILED" }).Count
    $avgTime = ($tests | Measure-Object -Property "Tiempo Promedio Paso (min)" -Average -ErrorAction SilentlyContinue).Average
    $maquinas = @($tests | Select-Object -Unique Maquina).Count
    
    [PSCustomObject]@{
        "Usuario" = $usuario
        "Total Tests" = $tests.Count
        "Tests Exitosos" = $passed
        "Tests Fallidos" = $failed
        "Tasa Exito %" = if($tests.Count -gt 0) { [math]::Round(($passed / $tests.Count) * 100, 2) } else { 0 }
        "Tiempo Promedio Paso (min)" = if ($avgTime) { [math]::Round($avgTime, 3) } else { 0 }
        "Maquinas Usadas" = $maquinas
        "Pasos Lentos" = ($tests | Measure-Object -Property "Pasos Lentos" -Sum -ErrorAction SilentlyContinue).Sum
    }
} | Sort-Object "Tests Fallidos" -Descending)

# ============================================
# Insights clave para el Resumen General (facilita lectura rapida / IA)
# ============================================
$peorMaquina = $statsByMachine | Where-Object { $_."Tests Fallidos" -gt 0 } | Select-Object -First 1
$peorUsuario = $statsByUser | Where-Object { $_."Tests Fallidos" -gt 0 } | Select-Object -First 1

$errorMasFrecuente = $allSteps |
    Where-Object { $_."Error Type" -and $_."Error Type".Trim() -ne "" } |
    Group-Object "Error Type" | Sort-Object Count -Descending | Select-Object -First 1

$tiempoTotalMin = [math]::Round((($allSteps | Measure-Object -Property "Tiempo (ms)" -Sum -ErrorAction SilentlyContinue).Sum) / 60000, 2)

$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Tiempo Total Ejecucion (min)"; "Valor" = $tiempoTotalMin }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Maquina con mas Fallos"; "Valor" = if ($peorMaquina) { "$($peorMaquina.'Máquina') ($($peorMaquina.'Tests Fallidos') fallidos)" } else { "Ninguna" } }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Usuario con mas Fallos"; "Valor" = if ($peorUsuario) { "$($peorUsuario.Usuario) ($($peorUsuario.'Tests Fallidos') fallidos)" } else { "Ninguno" } }
$resumenGeneral += [PSCustomObject]@{ "Metrica" = "Error mas Frecuente"; "Valor" = if ($errorMasFrecuente) { "$($errorMasFrecuente.Name) ($($errorMasFrecuente.Count) veces)" } else { "Ninguno" } }

# ============================================
# Generar reportes
# ============================================
Write-Host ""
Write-Host "[INFO] Generando reportes consolidados..." -ForegroundColor Cyan

# 1. CSV Consolidado (TODOS LOS PASOS) - con tiempo en minutos
$csvConsolidatedPath = "$outputFolder\${outputFileName}_$timestamp.csv"
$allStepsWithMin = $allSteps | ForEach-Object {
    $tiempoMs = [int]$_."Tiempo (ms)"
    $tiempoMin = [math]::Round($tiempoMs / 60000, 3)
    [PSCustomObject]@{
        "Test" = $_.Test
        "Batch" = $_.Batch
        "Maquina" = $_.Maquina
        "Usuario" = $_.Usuario
        "Descripcion" = $_.Descripcion
        "Accion" = $_.Accion
        "Elemento" = $_.Elemento
        "Valor" = $_.Valor
        "Tiempo (ms)" = $tiempoMs
        "Tiempo (s)" = $_."Tiempo (s)"
        "Tiempo (min)" = $tiempoMin
        "Estado" = $_.Estado
        "Error Type" = $_."Error Type"
        "Error Message" = $_."Error Message"
        "Origen Error" = $_."Origen Error"
        "Archivo Origen" = $_."Archivo Origen"
    }
}
$allStepsWithMin | Export-Csv -Path $csvConsolidatedPath -NoTypeInformation -Encoding UTF8
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

# ============================================
# Generar Excel
# ============================================
$excelGenerated = $false
Write-Host "[INFO] Intentando generar Excel..." -ForegroundColor Cyan

try {
    Import-Module ImportExcel -WarningAction SilentlyContinue -ErrorAction Stop
    
    $excelPath = "$outputFolder\${outputFileName}_$timestamp.xlsx"
    Write-Host "  Generando: $excelPath" -ForegroundColor White
    
    # Hoja 1: Resumen General
    $resumenGeneral | Export-Excel -Path $excelPath -WorksheetName "Resumen General" -AutoSize -TableStyle "Medium2"
    Write-Host "  OK Hoja 1: Resumen General" -ForegroundColor Green
    
    # Hoja 2: Por Usuario
    if ($statsByUser.Count -gt 0) {
        $statsByUser | Export-Excel -Path $excelPath -WorksheetName "Por Usuario" -AutoSize -TableStyle "Medium2" -AutoFilter -FreezeTopRow -Append
        Write-Host "  OK Hoja 2: Por Usuario ($($statsByUser.Count) usuarios)" -ForegroundColor Green
    }
    
    # Hoja 3: Por Maquina
    if ($statsByMachine.Count -gt 0) {
        $statsByMachine | Export-Excel -Path $excelPath -WorksheetName "Por Maquina" -AutoSize -TableStyle "Medium2" -AutoFilter -FreezeTopRow -Append
        Write-Host "  OK Hoja 3: Por Maquina" -ForegroundColor Green
    }
    
    # Hoja 4: Estadísticas por Test
    if ($testStats.Count -gt 0) {
        $testStats | Export-Excel -Path $excelPath -WorksheetName "Estadisticas por Test" -AutoSize -TableStyle "Light1" -AutoFilter -FreezeTopRow -Append
        Write-Host "  OK Hoja 4: Estadisticas por Test" -ForegroundColor Green
    }
    
    # Hoja 5: Detalles Paso a Paso (con tiempo en minutos)
    if ($allSteps.Count -gt 0) {
        $pasosParaMostrar = @($allSteps | ForEach-Object {
            $tiempoMs = [int]$_."Tiempo (ms)"
            $tiempoMin = [math]::Round($tiempoMs / 60000, 3)
            [PSCustomObject]@{
                "Test" = $_.Test
                "Batch" = $_.Batch
                "Maquina" = $_.Maquina
                "Usuario" = $_.Usuario
                "Descripcion" = $_.Descripcion
                "Elemento" = $_.Elemento
                "Valor" = $_.Valor
                "Accion" = $_.Accion
                "Nivel" = $_.Nivel
                "Tiempo (ms)" = $tiempoMs
                "Tiempo (s)" = $_."Tiempo (s)"
                "Tiempo (min)" = $tiempoMin
                "Error Type" = $_."Error Type"
                "Error Message" = $_."Error Message"
                "Origen Error" = $_."Origen Error"
            }
        })
        $pasosParaMostrar | Export-Excel -Path $excelPath -WorksheetName "Detalles Paso a Paso" -AutoSize -TableStyle "Light1" -AutoFilter -FreezeTopRow -Append
        Write-Host "  OK Hoja 5: Detalles Paso a Paso ($($allSteps.Count) pasos)" -ForegroundColor Green
    }
    
    # Hoja 6: Tests Fallidos
    if ($failedTests.Count -gt 0) {
        $failedTestsDetailed = @($failedTests | Select-Object Test, Batch, Maquina, Usuario, "Total Pasos", "Pasos Lentos", "Tiempo Promedio Paso (min)", "Error Type", "Error Message", "Origen Error")
        $failedTestsDetailed | Export-Excel -Path $excelPath -WorksheetName "Tests Fallidos + Errores" -AutoSize -TableStyle "Light1" -AutoFilter -FreezeTopRow -Append
        Write-Host "  OK Hoja 6: Tests Fallidos + Errores ($($failedTests.Count))" -ForegroundColor Green
    }
    
    # Hoja 7: Errores Comunes
    $erroresComunes = @()
    if ($allSteps.Count -gt 0) {
        $stepsConError = @($allSteps | Where-Object { $_."Error Type" -and $_."Error Type".Trim() -ne "" })
        if ($stepsConError.Count -gt 0) {
            $tiposError = @($stepsConError | Group-Object "Error Type" | ForEach-Object {
                $errorType = $_.Name
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
            } | Sort-Object Cantidad -Descending)
            $erroresComunes = $tiposError
        }
    }
    
    if ($erroresComunes.Count -gt 0) {
        @($erroresComunes) | Export-Excel -Path $excelPath -WorksheetName "Errores Comunes" -AutoSize -TableStyle "Light1" -AutoFilter -FreezeTopRow -Append
        Write-Host "  OK Hoja 7: Errores Comunes ($($erroresComunes.Count) tipos)" -ForegroundColor Green
    }
    
    # Hoja 8: Pasos Lentos (con tiempo en minutos)
    if ($slowSteps.Count -gt 0) {
        $slowStepsWithMin = @($slowSteps | ForEach-Object {
            $tiempoMs = [int]$_."Tiempo (ms)"
            $tiempoMin = [math]::Round($tiempoMs / 60000, 3)
            [PSCustomObject]@{
                "Test" = $_.Test
                "Batch" = $_.Batch
                "Maquina" = $_.Maquina
                "Usuario" = $_.Usuario
                "Descripcion" = $_.Descripcion
                "Elemento" = $_.Elemento
                "Valor" = $_.Valor
                "Accion" = $_.Accion
                "Nivel" = $_.Nivel
                "Tiempo (ms)" = $tiempoMs
                "Tiempo (s)" = $_."Tiempo (s)"
                "Tiempo (min)" = $tiempoMin
                "Estado" = $_.Estado
                "Error Type" = $_."Error Type"
                "Error Message" = $_."Error Message"
            }
        })
        $slowStepsWithMin | Export-Excel -Path $excelPath -WorksheetName "Pasos Lentos" -AutoSize -TableStyle "Light1" -AutoFilter -FreezeTopRow -Append
        Write-Host "  OK Hoja 8: Pasos Lentos ($($slowSteps.Count) pasos)" -ForegroundColor Green
    }
    
    $excelFileInfo = Get-Item $excelPath
    $excelSizeMB = [math]::Round($excelFileInfo.Length / 1MB, 2)
    Write-Host "  - Excel generado: $excelPath ($excelSizeMB MB)" -ForegroundColor Green
    $excelGenerated = $true
    
} catch {
    Write-Host "  - Excel NO generado: $_" -ForegroundColor Yellow
}

# ============================================
# Mostrar resumen
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  CONSOLIDACION COMPLETADA (XLSX)" -ForegroundColor Green
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
Write-Host ("  - Archivos XLSX procesados: " + $xlsxFiles.Count) -ForegroundColor White
Write-Host ("  - Maquinas unicas: " + $uniqueMachines) -ForegroundColor White
Write-Host ("  - Total tests ejecutados: " + $totalTests) -ForegroundColor White
Write-Host ("  - Tests exitosos: " + $totalPassed) -ForegroundColor Green
Write-Host ("  - Tests fallidos: " + $totalFailed) -ForegroundColor Red
$tasaExito = if($totalTests -gt 0) { [math]::Round(($totalPassed / $totalTests) * 100, 2) } else { 0 }
Write-Host ("  - Tasa de exito: " + $tasaExito + "%") -ForegroundColor Cyan
Write-Host ("  - Total pasos: " + $totalSteps) -ForegroundColor White
Write-Host ("  - Pasos lentos (>5s): " + $totalSlowSteps) -ForegroundColor White
Write-Host ""

if (-not $NoWait) {
    Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
    pause
}

# Auto-abrir Excel si existe
if ($excelGenerated) {
    try {
        & $excelPath
    } catch {
        # Intentar con explorer
        try {
            Invoke-Expression ("explorer.exe '$excelPath'")
        } catch { }
    }
}
