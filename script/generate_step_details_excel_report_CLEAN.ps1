#!/usr/bin/env powershell
# Script para generar reportes de detalles de pasos (Excel, CSV, HTML)
# Extrae datos de Serenity JSON y JUnit XML
# Genera Excel con COM API (funciona con Excel y LibreOffice)

param(
    [string]$serenityReportPath = ".\target\site\serenity",
    [string]$junitPath = ".\build\test-results\test",
    [string]$outputPath = ".\target\reports"
)

# Crear directorio de salida
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$machineName = $env:COMPUTERNAME
$userName = $env:USERNAME

# ===== FUNCIONES UTILITARIAS =====

# Función de HtmlEncode compatible que no depende de versiones de .NET
function Encode-HtmlSpecialChars {
    param([string]$text)
    
    if ([string]::IsNullOrEmpty($text)) { return "" }
    
    $text = $text -replace '&', '&amp;'
    $text = $text -replace '<', '&lt;'
    $text = $text -replace '>', '&gt;'
    $text = $text -replace '"', '&quot;'
    $text = $text -replace "'", '&#39;'
    
    return $text
}

function Get-ErrorType {
    param([string]$errorMessage)
    
    $patterns = @{
        "Selenium" = @("selenium", "webdriver", "driver executable", "session not created", "cannot start", "chrome not reachable", "invalid session id");
        "UI" = @("nosuchelement", "element not found", "not visible", "not interactable", "stale element", "timeout", "field not", "combo", "selector not found", "invisible");
        "Data" = @("illegalargumentexception", "not a valid", "missing value", "required value", "no se encontro", "null reference");
        "Validacion" = @("assert", "assertion", "expected but was", "comparison failed");
    }
    
    foreach ($category in $patterns.GetEnumerator()) {
        foreach ($pattern in $category.Value) {
            if ($errorMessage -like "*$pattern*") {
                return $category.Key
            }
        }
    }
    
    return "Otros"
}

# Función para crear un archivo XLSX real sin depender de Excel COM o LibreOffice
function Create-XlsxFileDirect {
    param(
        [string]$filePath,
        [array]$sheetData,
        [array]$sheetNames
    )
    
    try {
        Add-Type -AssemblyName System.IO.Compression
        
        # Crear ZIP de forma manual para evitar problemas de estructura
        $zipFilePath = $filePath
        Remove-Item $zipFilePath -ErrorAction SilentlyContinue
        
        $zipStream = New-Object System.IO.FileStream($zipFilePath, [System.IO.FileMode]::Create)
        $zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
        
        # 1. Crear [Content_Types].xml
        $contentTypes = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
    <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
"@
        
        for ($i = 0; $i -lt $sheetData.Count; $i++) {
            $contentTypes += "`n    <Override PartName=""/xl/worksheets/sheet$($i+1).xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml""/>"
        }
        
        $contentTypes += "`n</Types>"
        
        $entry = $zipArchive.CreateEntry("[Content_Types].xml")
        $writer = New-Object System.IO.StreamWriter($entry.Open())
        $writer.Write($contentTypes)
        $writer.Close()
        
        # 2. Crear _rels/.rels
        $relsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
"@
        
        $entry = $zipArchive.CreateEntry("_rels/.rels")
        $writer = New-Object System.IO.StreamWriter($entry.Open())
        $writer.Write($relsXml)
        $writer.Close()
        
        # 3. Crear xl/workbook.xml
        $workbookXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
    <sheets>
"@
        
        for ($i = 0; $i -lt $sheetData.Count; $i++) {
            $workbookXml += "`n        <sheet name=""$($sheetNames[$i])"" sheetId=""$($i+1)"" r:id=""rId$($i+2)""/>"
        }
        
        $workbookXml += "`n    </sheets>`n</workbook>"
        
        $entry = $zipArchive.CreateEntry("xl/workbook.xml")
        $writer = New-Object System.IO.StreamWriter($entry.Open())
        $writer.Write($workbookXml)
        $writer.Close()
        
        # 4. Crear xl/_rels/workbook.xml.rels
        $workbookRels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
"@
        
        for ($i = 0; $i -lt $sheetData.Count; $i++) {
            $workbookRels += "`n    <Relationship Id=""rId$($i+2)"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"" Target=""worksheets/sheet$($i+1).xml""/>"
        }
        
        $workbookRels += "`n</Relationships>"
        
        $entry = $zipArchive.CreateEntry("xl/_rels/workbook.xml.rels")
        $writer = New-Object System.IO.StreamWriter($entry.Open())
        $writer.Write($workbookRels)
        $writer.Close()
        
        # 5. Crear xl/styles.xml
        $stylesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
    <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
    <fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
    <borders count="1"><border><left/><right/><top/><bottom/></border></borders>
    <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
    <cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/></cellXfs>
</styleSheet>
"@
        
        $entry = $zipArchive.CreateEntry("xl/styles.xml")
        $writer = New-Object System.IO.StreamWriter($entry.Open())
        $writer.Write($stylesXml)
        $writer.Close()
        
        # 6. Crear worksheets
        # IMPORTANTE: se ESCRIBE DIRECTO al StreamWriter fila por fila en vez de acumular un
        # string con '+=' (que en PowerShell es O(n^2) y, con la hoja "Log Consola" de miles de
        # filas, hace que la generación parezca "colgada" durante minutos).
        for ($i = 0; $i -lt $sheetData.Count; $i++) {
            $sheet = $sheetData[$i]
            if ($null -eq $sheet -or $sheet.Count -eq 0) { continue }

            $entry = $zipArchive.CreateEntry("xl/worksheets/sheet$($i+1).xml")
            $writer = New-Object System.IO.StreamWriter($entry.Open())
            $writer.Write("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>`n<worksheet xmlns=""http://schemas.openxmlformats.org/spreadsheetml/2006/main"">`n    <sheetData>")

            $rowNum = 1
            $firstItem = $sheet | Select-Object -First 1

            if ($firstItem) {
                # Headers
                $colNum = 1
                $writer.Write("`n        <row r=""$rowNum"">")
                foreach ($prop in $firstItem.PSObject.Properties) {
                    $cellRef = [char]([byte][char]'A' + $colNum - 1) + "$rowNum"
                    if ($colNum -gt 26) {
                        $cellRef = ([char]([byte][char]'A' + [math]::Floor(($colNum-1)/26) - 1)) + ([char]([byte][char]'A' + (($colNum-1) % 26))) + "$rowNum"
                    }
                    $writer.Write("`n            <c r=""$cellRef"" t=""inlineStr""><is><t xml:space=""preserve"">$([Security.SecurityElement]::Escape($prop.Name))</t></is></c>")
                    $colNum++
                }
                $writer.Write("`n        </row>")
                $rowNum++

                # Data rows
                foreach ($item in $sheet) {
                    $colNum = 1
                    $writer.Write("`n        <row r=""$rowNum"">")
                    foreach ($prop in $item.PSObject.Properties) {
                        $val = if ($null -eq $prop.Value) { "" } else { [string]$prop.Value }
                        $cellRef = [char]([byte][char]'A' + $colNum - 1) + "$rowNum"
                        if ($colNum -gt 26) {
                            $cellRef = ([char]([byte][char]'A' + [math]::Floor(($colNum-1)/26) - 1)) + ([char]([byte][char]'A' + (($colNum-1) % 26))) + "$rowNum"
                        }
                        $writer.Write("`n            <c r=""$cellRef"" t=""inlineStr""><is><t xml:space=""preserve"">$([Security.SecurityElement]::Escape($val))</t></is></c>")
                        $colNum++
                    }
                    $writer.Write("`n        </row>")
                    $rowNum++
                }
            }

            $writer.Write("`n    </sheetData>`n</worksheet>")
            $writer.Close()
        }
        
        # Cerrar ZIP
        $zipArchive.Dispose()
        $zipStream.Close()
        
        Write-Host "    Archivo Excel generado exitosamente (método nativo PowerShell)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "    Error creando XLSX nativo: $_" -ForegroundColor Yellow
        return $false
    }
}

function Create-ExcelFile {
    param(
        [string]$filePath,
        [array]$sheetData,
        [array]$sheetNames,
        [string]$csvPath  # Ruta del CSV para fallback
    )
    
    # Fallback 1: Generar Excel nativo usando PowerShell puro (MÉTODO PRIMARIO - funciona en TODAS las máquinas)
    Write-Host "    Generando Excel nativo con PowerShell..." -ForegroundColor Cyan
    if (Create-XlsxFileDirect -filePath $filePath -sheetData $sheetData -sheetNames $sheetNames) {
        return $true
    }
    
    # Fallback 2: Intentar con Excel COM (si está instalado)
    $hasExcel = $false
    
    try {
        $excel = New-Object -ComObject Excel.Application -ErrorAction Stop
        $hasExcel = $true
    }
    catch {
        $hasExcel = $false
    }
    
    if ($hasExcel) {
        Write-Host "    Intentando Excel COM (método alternativo)..." -ForegroundColor Cyan
        try {
            $excel.Visible = $false
            $excel.DisplayAlerts = $false
            $workbook = $excel.Workbooks.Add()
            
            for ($i = 0; $i -lt $sheetData.Count; $i++) {
                $sheet = $sheetData[$i]
                if ($null -eq $sheet -or $sheet.Count -eq 0) { continue }
                
                $worksheet = if ($i -eq 0) { $workbook.Worksheets(1) } else { $workbook.Worksheets.Add() }
                $worksheet.Name = $sheetNames[$i]
                
                $row = 1
                $firstItem = $sheet | Select-Object -First 1
                
                if ($firstItem) {
                    # Headers
                    $col = 1
                    foreach ($prop in $firstItem.PSObject.Properties) {
                        $worksheet.Cells($row, $col).Value = [string]$prop.Name
                        $worksheet.Cells($row, $col).Font.Bold = $true
                        $col++
                    }
                    $row++
                    
                    # Data
                    foreach ($item in $sheet) {
                        $col = 1
                        foreach ($prop in $item.PSObject.Properties) {
                            $val = $prop.Value
                            $worksheet.Cells($row, $col).Value = if ($null -eq $val) { "" } else { [string]$val }
                            $col++
                        }
                        $row++
                    }
                    
                    # AutoFit
                    try {
                        $worksheet.UsedRange.EntireColumn.AutoFit() | Out-Null
                    }
                    catch { }
                }
            }
            
            $absolutePath = [System.IO.Path]::GetFullPath($filePath)
            $workbook.SaveAs($absolutePath, 51)  # 51 = xlOpenXMLWorkbook (Excel 2007+)
            $workbook.Close($false)
            $excel.Quit()
            
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) | Out-Null
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
            [gc]::Collect()
            
            Write-Host "    Archivo Excel generado exitosamente via COM" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "    Error Excel COM: $_" -ForegroundColor Yellow
            try { $workbook.Close($false); $excel.Quit() } catch { }
            [gc]::Collect()
        }
    }
    
    # Fallback 3: Usar LibreOffice CLI para convertir CSV a XLSX
    if ($null -ne $csvPath -and (Test-Path $csvPath)) {
        try {
            $libreOfficePath = (Get-Command soffice -ErrorAction SilentlyContinue).Source
            if ($null -eq $libreOfficePath) {
                $libreOfficePath = "C:\Program Files\LibreOffice\program\soffice.exe"
            }
            
            if (Test-Path $libreOfficePath) {
                $outputDir = Split-Path $filePath -Parent
                $absolutePath = [System.IO.Path]::GetFullPath($filePath)
                $csvAbsPath = [System.IO.Path]::GetFullPath($csvPath)
                $csvBaseName = Split-Path $csvAbsPath -Leaf
                
                # Convertir CSV a XLSX usando LibreOffice CLI
                Write-Host "    Convirtiendo CSV a XLSX con LibreOffice..." -ForegroundColor Cyan
                & $libreOfficePath --headless --convert-to xlsx --outdir $outputDir $csvAbsPath 2>&1 | Out-Null
                
                # Esperar a que se complete la conversión
                Start-Sleep -Milliseconds 2000
                
                # Buscar el archivo generado por LibreOffice
                $expectedXlsx = Join-Path $outputDir ($csvBaseName.Replace(".csv", ".xlsx"))
                Write-Host "    Buscando archivo generado: $expectedXlsx" -ForegroundColor Cyan
                
                # Intentar múltiples estrategias para encontrar el archivo
                $foundXlsx = $null
                
                if (Test-Path $expectedXlsx) {
                    $foundXlsx = $expectedXlsx
                } else {
                    # Buscar archivos .xlsx generados recientemente en el directorio
                    $recentXlsx = Get-ChildItem -Path $outputDir -Filter "*.xlsx" -ErrorAction SilentlyContinue | 
                        Where-Object { $_.LastWriteTime -gt (Get-Date).AddSeconds(-30) } | 
                        Sort-Object LastWriteTime -Descending | 
                        Select-Object -First 1
                    
                    if ($recentXlsx) {
                        $foundXlsx = $recentXlsx.FullName
                        Write-Host "    Archivo encontrado: $foundXlsx" -ForegroundColor Cyan
                    }
                }
                
                if ($foundXlsx -and (Test-Path $foundXlsx)) {
                    # Mover/renombrar el archivo al destino final
                    Remove-Item $absolutePath -ErrorAction SilentlyContinue
                    Move-Item -Path $foundXlsx -Destination $absolutePath -Force -ErrorAction SilentlyContinue
                    if (Test-Path $absolutePath) {
                        Write-Host "    Archivo Excel generado exitosamente via LibreOffice" -ForegroundColor Green
                        return $true
                    }
                } else {
                    Write-Host "    No se encontró archivo XLSX generado por LibreOffice" -ForegroundColor Yellow
                }
            } else {
                Write-Host "    LibreOffice no encontrada en: $libreOfficePath" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "    Error LibreOffice CLI: $_" -ForegroundColor Yellow
        }
    }
    
    # Fallback Final: SIEMPRE copiar CSV como XLSX (Excel lo puede abrir)
    # Fallback Final 4: Copiar CSV como XLSX (último recurso - Excel lo abre automáticamente)
    # Solo se usa si TODOS los métodos anteriores fallan
    if ($null -ne $csvPath -and (Test-Path $csvPath)) {
        try {
            $absolutePath = [System.IO.Path]::GetFullPath($filePath)
            $csvAbsPath = [System.IO.Path]::GetFullPath($csvPath)
            
            Write-Host "    ADVERTENCIA: Usando CSV como XLSX (último recurso)" -ForegroundColor Yellow
            Remove-Item $absolutePath -ErrorAction SilentlyContinue
            Copy-Item -Path $csvAbsPath -Destination $absolutePath -Force
            
            if (Test-Path $absolutePath) {
                Write-Host "    Archivo generado como CSV+XLSX (fallback final)" -ForegroundColor Yellow
                return $true
            }
        }
        catch {
            Write-Host "    Error en fallback final: $_" -ForegroundColor Yellow
        }
    }
    
    return $false
}

function Format-WithComma {
    param([double]$Value, [int]$Decimals = 2)
    $rounded = [math]::Round($Value, $Decimals)
    return $rounded.ToString("N$Decimals", [System.Globalization.CultureInfo]::GetCultureInfo("es-CO"))
}

function Extract-StepDetails {
    param([string]$Description)
    
    $actionType = "Otra"
    $element = ""
    $value = ""
    
    if ($Description -like "*enters*") {
        $actionType = "Escribe"
        if ($Description -match "'([^']*)'.*into\s+(.+)") {
            $value = $matches[1]
            $element = $matches[2]
        }
    }
    elseif ($Description -like "*clicks*" -or $Description -like "*click*") {
        $actionType = "Click/Selecciona"
        if ($Description -match "on\s+(.+)$") {
            $element = $matches[1]
        }
        elseif ($Description -match "click\s+(.+)$") {
            $element = $matches[1]
        }
    }
    elseif ($Description -like "*switch*") {
        $actionType = "Navega/Cambia"
        if ($Description -match "to\s+(.+)") {
            $element = $matches[1]
        }
    }
    elseif ($Description -like "*open*") {
        $actionType = "Abre"
        if ($Description -match "at\s+(.+)") {
            $element = $matches[1]
        }
    }
    elseif ($Description -like "*fill*") {
        $actionType = "Completa"
        $element = $Description
    }
    elseif ($Description -like "*And*" -or $Description -like "*Given*" -or $Description -like "*When*") {
        $actionType = "Ejecuta"
        $element = $Description
    }
    
    return @{
        Accion = $actionType
        Elemento = $element
        Valor = $value
    }
}

function Extract-TestSteps {
    param([array]$steps, [int]$level = 0, [string]$testName, [string]$batch = "")
    $result = @()
    
    foreach ($step in $steps) {
        $timeMs = [int]$step.duration
        $timeS = Format-WithComma -Value ($timeMs / 1000) -Decimals 2
        $stepDetails = Extract-StepDetails -Description $step.description
        
        # Extraer error del paso si existe.
        # Serenity marca fallos como ERROR / FAILURE / COMPROMISED y guarda el detalle
        # en step.exception como OBJETO: { errorType, message, stackTrace }
        $stepError = ""
        $stepErrorType = "Sin Error"
        $stepErrorSource = ""
        $esFallo = @("ERROR", "FAILURE", "COMPROMISED") -contains $step.result
        if ($esFallo) {
            $exMsg = ""
            $exClass = ""
            if ($step.exception) {
                $exMsg = [string]$step.exception.message
                $exClass = [string]$step.exception.errorType
                # Fallback si exception no es objeto (string plano)
                if ([string]::IsNullOrWhiteSpace($exMsg)) { $exMsg = [string]$step.exception }

                # Origen del fallo (archivo:linea): preferir el primer frame del codigo del proyecto
                if ($step.exception.stackTrace) {
                    $frame = $step.exception.stackTrace | Where-Object { $_.declaringClass -like "com.sara.automation.*" } | Select-Object -First 1
                    if (-not $frame) { $frame = $step.exception.stackTrace | Select-Object -First 1 }
                    if ($frame -and $frame.fileName) {
                        $stepErrorSource = "$($frame.fileName):$($frame.lineNumber)"
                    }
                }
            }
            # Construir mensaje detallado: [clase de excepcion] mensaje
            if ($exClass) {
                $stepError = "[$exClass] $exMsg"
            } else {
                $stepError = $exMsg
            }
            $stepErrorType = Get-ErrorType -errorMessage $stepError
        }

        $result += [PSCustomObject]@{
            Test = $testName
            Batch = $batch
            Descripcion = $step.description
            Accion = $stepDetails.Accion
            Elemento = $stepDetails.Elemento
            Valor = $stepDetails.Valor
            Tiempo_ms = $timeMs
            Tiempo_s = $timeS
            Estado = $step.result
            EsFallo = $esFallo
            ErrorMessage = $stepError
            ErrorType = $stepErrorType
            ErrorSource = $stepErrorSource
        }
        
        if ($step.children -and $step.children.Count -gt 0) {
            $result += Extract-TestSteps -steps $step.children -level ($level + 1) -testName $testName -batch $batch
        }
    }
    return $result
}

# ===== CARGAR DATOS =====

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generando reportes de detalles de pasos" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Cargar JSON de Serenity
$jsonFiles = Get-ChildItem -Path $serenityReportPath -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "index" }
# Listas .NET (Add O(1)) en vez de arrays con '+=' (O(n^2)): con 50 escenarios y miles de
# pasos/líneas de consola, el '+=' hacía que la generación pareciera "colgada".
$allSteps = [System.Collections.Generic.List[object]]::new()
$testStats = @()

# ===== CARGAR LOG DE CONSOLA POR ESCENARIO (system-out del JUnit XML) =====
# Se construye ANTES del loop para usarlo como propiedad directa de cada test.
# IMPORTANTE: el log de las tasks queda en el XML del FEATURE (testcase name="Test Usuario NN - ..."),
# NO en el del runner (system-out vacio). Se extrae con regex sobre texto crudo (no [xml], que
# fallaba por caracteres de control) y se mapea por NOMBRE DE TEST (= titulo de Serenity).
$logByTest = @{}
if (Test-Path $junitPath) {
    Get-ChildItem -Path $junitPath -Filter "*.xml" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $raw = Get-Content $_.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            $mOut = [regex]::Match($raw, '<system-out><!\[CDATA\[(.*?)\]\]></system-out>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if (-not $mOut.Success) { return }
            $logTxt = $mOut.Groups[1].Value
            if ([string]::IsNullOrWhiteSpace($logTxt)) { return }  # runner XML: system-out vacio
            # Sanitizar chars de control invalidos en XML (si no, romperian el xlsx de salida).
            # NOTA: ya NO truncamos: el log va linea por fila, asi que no aplica el limite de celda.
            $logTxt = [regex]::Replace($logTxt, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
            foreach ($mc in [regex]::Matches($raw, 'testcase\s+name="([^"]*)"')) {
                $tcName = $mc.Groups[1].Value -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"' -replace '&#39;', "'"
                if (-not [string]::IsNullOrWhiteSpace($tcName)) { $logByTest[$tcName.Trim()] = $logTxt }
            }
        } catch {
            Write-Host "  [WARN] No se pudo leer system-out de $($_.Name): $_" -ForegroundColor Yellow
        }
    }
    Write-Host "Logs de consola cargados para $($logByTest.Count) escenario(s)" -ForegroundColor Green
}

foreach ($jsonFile in $jsonFiles) {
    $jsonContent = Get-Content $jsonFile.FullName | ConvertFrom-Json
    $testName = $jsonContent.title
    
    # Extraer Batch del tag (batch25, batch50, etc.)
    $batch = ""
    if ($jsonContent.tags) {
        $batchTag = $jsonContent.tags | Where-Object { $_.name -like "batch*" } | Select-Object -First 1
        if ($batchTag) {
            $batch = $batchTag.name
        }
    }
    
    if ($jsonContent.testSteps) {
        $steps = Extract-TestSteps -steps $jsonContent.testSteps -testName $testName -batch $batch
        if ($steps) { $allSteps.AddRange([object[]]@($steps)) }
        
        $slowSteps = $steps | Where-Object { $_.Tiempo_ms -gt 5000 }
        $totalMs = ($steps | Measure-Object -Property Tiempo_ms -Sum).Sum
        $totalMin = Format-WithComma -Value ($totalMs / 60000) -Decimals 2
        
        # Detectar estado del test
        $errorSteps = $steps | Where-Object { $_.EsFallo }
        $testState = if ($errorSteps.Count -gt 0) { "FAILED" } else { "PASSED" }
        
        $testErrorMsg = ""
        $testErrorType = "Sin Error"
        if ($errorSteps.Count -gt 0) {
            $firstError = $errorSteps | Select-Object -First 1
            $testErrorMsg = $firstError.ErrorMessage
            $testErrorType = $firstError.ErrorType
        }
        
        $logConsola = ""
        $tnKey = if ($testName) { ([string]$testName).Trim() } else { "" }
        if ($logByTest.ContainsKey($tnKey)) { $logConsola = $logByTest[$tnKey] }

        $testStats += [PSCustomObject]@{
            Test = $testName
            Batch = $batch
            TotalPasos = $steps.Count
            PasosLentos = $slowSteps.Count
            TiempoTotal_min = $totalMin
            Estado = $testState
            ErrorType = $testErrorType
            ErrorMessage = $testErrorMsg
            LogConsola = $logConsola
        }
    }
}

# ===== GENERAR CSV =====

$csvPath = "$outputPath\step_details_$timestamp.csv"
$csvLines = [System.Collections.Generic.List[object]]::new()
$csvLines.Add('"Test","Batch","Maquina","Usuario","Descripcion","Accion","Elemento","Valor","Tiempo (ms)","Tiempo (s)","Tiempo (min)","Estado","Error Type","Error Message","Origen Error"')

foreach ($step in $allSteps) {
    $desc = $step.Descripcion -replace '"', '""'
    $errorMsg = $step.ErrorMessage -replace '"', '""'
    $errorType = if($step.EsFallo) { $step.ErrorType } else { "" }
    $errorMsg = if($step.EsFallo) { $errorMsg } else { "" }
    $errorSource = if($step.EsFallo) { $step.ErrorSource } else { "" }
    
    $line = @(
        "`"$($step.Test)`""
        "`"$($step.Batch)`""
        "`"$machineName`""
        "`"$userName`""
        "`"$desc`""
        "`"$($step.Accion)`""
        "`"$($step.Elemento)`""
        "`"$($step.Valor)`""
        "$($step.Tiempo_ms)"
        "$($step.Tiempo_s)"
        "$($step.Tiempo_min)"
        "`"$($step.Estado)`""
        "`"$errorType`""
        "`"$errorMsg`""
        "`"$errorSource`""
    ) -join ","

    $csvLines.Add($line)
}

$csvLines | Out-File -FilePath $csvPath -Encoding UTF8
Write-Host "CSV generado: $csvPath" -ForegroundColor Green

# ===== GENERAR EXCEL CON COM =====

$excelPath = "$outputPath\step_details_$timestamp.xlsx"
$failedTests = ($testStats | Where-Object { $_.Estado -eq "FAILED" }).Count
$passedTests = ($testStats | Where-Object { $_.Estado -eq "PASSED" }).Count

# Hoja 1: Todos los pasos con información completa
$stepsSheet = $allSteps | Select-Object @{N="Test"; E={$_.Test}},
                                        @{N="Batch"; E={$_.Batch}},
                                        @{N="Maquina"; E={$machineName}},
                                        @{N="Usuario"; E={$userName}},
                                        @{N="Descripcion"; E={$_.Descripcion}},
                                        @{N="Accion"; E={$_.Accion}},
                                        @{N="Elemento"; E={if([string]::IsNullOrEmpty($_.Elemento)) { "N/A" } else { $_.Elemento }}},
                                        @{N="Valor"; E={if([string]::IsNullOrEmpty($_.Valor)) { "N/A" } else { $_.Valor }}},
                                        @{N="Tiempo (ms)"; E={$_.Tiempo_ms}},
                                        @{N="Tiempo (s)"; E={$_.Tiempo_s}},
                                        @{N="Estado"; E={$_.Estado}},
                                        @{N="Error Type"; E={if($_.EsFallo) { $_.ErrorType } else { "" }}},
                                        @{N="Error Message"; E={if($_.EsFallo) { $_.ErrorMessage } else { "" }}},
                                        @{N="Origen Error"; E={if($_.EsFallo) { $_.ErrorSource } else { "" }}}

# Hoja 2: Pasos lentos
$slowSteps = $allSteps | Where-Object { $_.Tiempo_ms -gt 5000 } | Sort-Object Tiempo_ms -Descending
$slowSheet = if ($slowSteps.Count -gt 0) {
    $slowSteps | Select-Object @{N="Test"; E={$_.Test}},
                               @{N="Batch"; E={$_.Batch}},
                               @{N="Maquina"; E={$machineName}},
                               @{N="Usuario"; E={$userName}},
                               @{N="Descripcion"; E={$_.Descripcion}},
                               @{N="Accion"; E={$_.Accion}},
                               @{N="Elemento"; E={if([string]::IsNullOrEmpty($_.Elemento)) { "N/A" } else { $_.Elemento }}},
                               @{N="Tiempo (ms)"; E={$_.Tiempo_ms}},
                               @{N="Tiempo (s)"; E={$_.Tiempo_s}},
                               @{N="Estado"; E={$_.Estado}},
                               @{N="Error Type"; E={if($_.EsFallo) { $_.ErrorType } else { "" }}}
} else {
    @([PSCustomObject]@{ Mensaje = "Sin pasos lentos" })
}

# Hoja 3: Resumen de errores
$errorSummary = $testStats | Where-Object { $_.Estado -eq "FAILED" } | 
                Group-Object ErrorType | 
                Select-Object @{N="Error Type"; E={$_.Name}},
                              @{N="Cantidad"; E={$_.Count}},
                              @{N="Porcentaje"; E={Format-WithComma -Value (($_.Count / $failedTests) * 100) -Decimals 1}} |
                Sort-Object Cantidad -Descending
if ($errorSummary.Count -eq 0) {
    $errorSummary = @([PSCustomObject]@{ "Error Type" = "Sin Errores"; Cantidad = 0; Porcentaje = 0 })
}

# Hoja 4: Estadísticas por Test (sin el log completo: el log va en su propia hoja, linea por fila)
$testSummary = $testStats | Select-Object @{N="Test"; E={$_.Test}},
                                           @{N="Batch"; E={$_.Batch}},
                                           @{N="Maquina"; E={$machineName}},
                                           @{N="Usuario"; E={$userName}},
                                           @{N="Total Pasos"; E={$_.TotalPasos}},
                                           @{N="Pasos Lentos"; E={$_.PasosLentos}},
                                           @{N="Tiempo Total (min)"; E={$_.TiempoTotal_min}},
                                           @{N="Estado"; E={$_.Estado}},
                                           @{N="Error Type"; E={$_.ErrorType}},
                                           @{N="Error Message"; E={$_.ErrorMessage}}

# Hoja 5: Log Consola (UNA LINEA POR FILA -> filtrable/buscable, facil de revisar).
# Incluye Maquina/Usuario para que la consolidacion solo tenga que concatenar estas hojas.
$logLinesSheet = [System.Collections.Generic.List[object]]::new()
foreach ($ts in $testStats) {
    if ([string]::IsNullOrEmpty($ts.LogConsola)) { continue }
    $n = 0
    foreach ($ln in ($ts.LogConsola -split "`n")) {
        $n++
        $lineaLimpia = ($ln -replace "`r", "")
        # Marca de error para metricas (contar/filtrar lineas de fallo).
        $esError = if ($lineaLimpia -match '(?i)error|fall(o|a|ó|aron)|fail|exception|no se pudo|timeout|✗|✘') { "SI" } else { "" }
        $logLinesSheet.Add([PSCustomObject]@{
            Test    = $ts.Test
            Batch   = $ts.Batch
            Maquina = $machineName
            Usuario = $userName
            Nro     = $n
            EsError = $esError
            Linea   = $lineaLimpia
        })
    }
}
if (@($logLinesSheet).Count -eq 0) {
    $logLinesSheet = @([PSCustomObject]@{ Test = ""; Batch = ""; Maquina = $machineName; Usuario = $userName; Nro = 0; EsError = ""; Linea = "(sin log de consola)" })
}

Write-Host "Generando Excel..." -ForegroundColor Cyan
$excelSuccess = Create-ExcelFile -filePath $excelPath `
                                 -sheetData @($stepsSheet, $slowSheet, $errorSummary, $testSummary, $logLinesSheet) `
                                 -sheetNames @("Todos los Pasos", "Pasos Lentos (>5s)", "Resumen de Errores", "Resumen por Test", "Log Consola") `
                                 -csvPath $csvPath

if ($excelSuccess) {
    Write-Host "Excel generado: $excelPath" -ForegroundColor Green
} else {
    Write-Host "No se generó Excel (LibreOffice/Excel no disponibles)" -ForegroundColor Yellow
}

# ===== GENERAR HTML PROFESIONAL =====

$htmlPath = "$outputPath\step_details_$timestamp.html"

$successCount = @($allSteps | Where-Object { $_.Estado -eq 'SUCCESS' }).Count
$errorCount = @($allSteps | Where-Object { $_.EsFallo }).Count
$slowCount = @($allSteps | Where-Object { $_.Tiempo_ms -gt 5000 }).Count
$totalTime = ($allSteps | Measure-Object -Property Tiempo_s -Sum).Sum

$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SARA3 - Reporte de Pasos Detallado</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            min-height: 100vh; 
            padding: 30px 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 10px; box-shadow: 0 10px 40px rgba(0,0,0,0.3); }
        .header { 
            background: linear-gradient(135deg, #0078d4 0%, #106ebe 100%); 
            color: white; 
            padding: 40px 30px; 
            border-radius: 10px 10px 0 0;
            border-bottom: 5px solid #ff6b6b;
        }
        .header h1 { font-size: 32px; margin-bottom: 10px; }
        .header p { font-size: 14px; opacity: 0.95; }
        .info-bar { 
            background: #f8f9fa; 
            padding: 15px 30px; 
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            border-bottom: 1px solid #ddd;
            flex-wrap: wrap;
            gap: 20px;
        }
        .info-item { display: flex; align-items: center; gap: 8px; font-size: 13px; }
        .info-label { font-weight: 600; color: #333; }
        .info-value { color: #0078d4; }
        
        .stats-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); 
            gap: 20px; 
            padding: 30px;
            background: #f8f9fa;
        }
        .stat-card { 
            background: white; 
            padding: 25px; 
            border-radius: 8px; 
            border-left: 5px solid #0078d4;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        .stat-card:hover { transform: translateY(-5px); }
        .stat-card.success { border-left-color: #28a745; }
        .stat-card.error { border-left-color: #dc3545; }
        .stat-card.slow { border-left-color: #ffc107; }
        .stat-icon { font-size: 30px; margin-bottom: 10px; }
        .stat-value { font-size: 36px; font-weight: bold; color: #0078d4; }
        .stat-card.success .stat-value { color: #28a745; }
        .stat-card.error .stat-value { color: #dc3545; }
        .stat-card.slow .stat-value { color: #ffc107; }
        .stat-label { color: #666; font-size: 13px; margin-top: 8px; }
        
        .tabs { 
            display: flex; 
            gap: 0; 
            border-bottom: 2px solid #ddd;
            padding: 0 30px;
            background: white;
        }
        .tab-button { 
            padding: 15px 25px; 
            border: none; 
            background: transparent; 
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            color: #666;
            border-bottom: 3px solid transparent;
            transition: all 0.2s;
        }
        .tab-button:hover { color: #0078d4; }
        .tab-button.active { 
            color: #0078d4; 
            border-bottom-color: #0078d4;
            background: #f8f9fa;
        }
        .tab-content { display: none; padding: 30px; }
        .tab-content.active { display: block; }
        
        table { 
            width: 100%; 
            border-collapse: collapse; 
            font-size: 13px;
        }
        th { 
            background: linear-gradient(135deg, #0078d4, #106ebe); 
            color: white; 
            padding: 15px; 
            text-align: left;
            font-weight: 600;
        }
        td { 
            padding: 12px 15px; 
            border-bottom: 1px solid #eee;
        }
        tr:hover { background-color: #f8f9fa; }
        tr.SUCCESS { background-color: #f1f8f5; }
        tr.ERROR { background-color: #fff5f5; }
        
        .badge { 
            display: inline-block; 
            padding: 4px 12px; 
            border-radius: 20px; 
            font-size: 12px; 
            font-weight: 600;
        }
        .badge-success { background: #d4edda; color: #155724; }
        .badge-error { background: #f8d7da; color: #721c24; }
        .badge-warning { background: #fff3cd; color: #856404; }
        
        .error-summary { 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 8px; 
            margin-bottom: 20px;
        }
        .error-row { 
            display: flex; 
            justify-content: space-between; 
            padding: 10px 0; 
            border-bottom: 1px solid #ddd;
        }
        .error-row:last-child { border-bottom: none; }
        .error-type { font-weight: 600; color: #333; }
        .error-count { 
            color: #dc3545; 
            font-weight: 700; 
            font-size: 18px;
        }
        .error-percentage { color: #666; font-size: 12px; }
        
        .chart-container { 
            position: relative; 
            height: 300px; 
            margin-bottom: 30px;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        footer { 
            padding: 20px 30px; 
            background: #f8f9fa; 
            border-top: 1px solid #ddd;
            font-size: 12px;
            color: #666;
            text-align: center;
            border-radius: 0 0 10px 10px;
        }
        
        .search-box { 
            margin-bottom: 20px;
            display: flex;
            gap: 10px;
        }
        .search-box input { 
            flex: 1;
            padding: 10px 15px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 13px;
        }
        .search-box input:focus { 
            outline: none;
            border-color: #0078d4;
            box-shadow: 0 0 5px rgba(0,120,212,0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>&#128202; Reporte de Detalles de Pasos - SARA3</h1>
            <p>An&aacute;lisis completo de ejecuci&oacute;n de casos y pruebas automatizadas</p>
        </div>
        
        <div class="info-bar">
            <div class="info-item">
                <span class="info-label">&#128187; M&aacute;quina:</span>
                <span class="info-value">$machineName</span>
            </div>
            <div class="info-item">
                <span class="info-label">&#128100; Usuario:</span>
                <span class="info-value">$userName</span>
            </div>
            <div class="info-item">
                <span class="info-label">&#128197; Fecha:</span>
                <span class="info-value">$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</span>
            </div>
            <div class="info-item">
                <span class="info-label">&#9201; Tiempo Total:</span>
                <span class="info-value">${totalTime:N2}s</span>
            </div>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">&#128203;</div>
                <div class="stat-value">$($allSteps.Count)</div>
                <div class="stat-label">Pasos Totales</div>
            </div>
            <div class="stat-card success">
                <div class="stat-icon">&#9989;</div>
                <div class="stat-value">$successCount</div>
                <div class="stat-label">Pasos Exitosos ($(([math]::Round(($successCount/$($allSteps.Count)*100), 1)))%)</div>
            </div>
            <div class="stat-card error">
                <div class="stat-icon">&#10060;</div>
                <div class="stat-value">$errorCount</div>
                <div class="stat-label">Pasos con Error ($(([math]::Round(($errorCount/$($allSteps.Count)*100), 1)))%)</div>
            </div>
            <div class="stat-card slow">
                <div class="stat-icon">&#128034;</div>
                <div class="stat-value">$slowCount</div>
                <div class="stat-label">Pasos Lentos (&gt;5s)</div>
            </div>
        </div>
        
        <div class="tabs">
            <button class="tab-button active" onclick="showTab('resumen', this)">Resumen</button>
            <button class="tab-button" onclick="showTab('todos', this)">Todos los Pasos</button>
            <button class="tab-button" onclick="showTab('errores', this)">Errores</button>
            <button class="tab-button" onclick="showTab('lentos', this)">Pasos Lentos</button>
        </div>
        
        <div id="resumen" class="tab-content active">
            <div class="chart-container">
                <canvas id="chartEstados"></canvas>
            </div>
            <div class="chart-container">
                <canvas id="chartErrores"></canvas>
            </div>
        </div>
        
        <div id="todos" class="tab-content">
            <div class="search-box">
                <input type="text" id="filtroTodos" placeholder="&#128269; Filtrar pasos..." onkeyup="filtrarTabla('tablaTodos', this.value)">
            </div>
            <table id="tablaTodos">
                <thead>
                    <tr>
                        <th>Test</th>
                        <th>Batch</th>
                        <th>Descripción</th>
                        <th>Acción</th>
                        <th>Estado</th>
                        <th>Error Type</th>
                        <th>Tiempo (ms)</th>
                    </tr>
                </thead>
                <tbody>
"@

# Filas en una lista y un solo join (evita '+=' por paso = O(n^2) sobre miles de pasos).
$filasHtml = [System.Collections.Generic.List[object]]::new()
foreach ($step in $allSteps) {
    $badgeClass = if($step.EsFallo) { 'badge-error' } else { 'badge-success' }
    $errorDisplay = if($step.EsFallo) { $step.ErrorType } else { "-" }
    $rowClass = $step.Estado

    $filasHtml.Add(@"
                    <tr class="$rowClass">
                        <td><strong>$(Encode-HtmlSpecialChars $step.Test)</strong></td>
                        <td>$($step.Batch)</td>
                        <td>$(Encode-HtmlSpecialChars $step.Descripcion)</td>
                        <td><small>$(Encode-HtmlSpecialChars $step.Accion)</small></td>
                        <td><span class="badge $badgeClass">$($step.Estado)</span></td>
                        <td>$errorDisplay</td>
                        <td><strong>$($step.Tiempo_ms)</strong></td>
                    </tr>

"@)
}
$html += ($filasHtml -join "")

$html += @"
                </tbody>
            </table>
        </div>
        
        <div id="errores" class="tab-content">
            <h3>Resumen de Errores</h3>
            <div class="error-summary">
"@

$errorsByType = $allSteps | Where-Object { $_.EsFallo } | Group-Object -Property ErrorType | Sort-Object -Property Count -Descending
$totalErrors = $errorCount

foreach ($errorGroup in $errorsByType) {
    $percentage = if ($totalErrors -gt 0) { [math]::Round(($errorGroup.Count / $totalErrors * 100), 1) } else { 0 }
    $html += @"
                <div class="error-row">
                    <div>
                        <div class="error-type">$($errorGroup.Name)</div>
                        <div class="error-percentage">$($errorGroup.Count) ocurrencias ($percentage%)</div>
                    </div>
                    <div class="error-count">$($errorGroup.Count)</div>
                </div>

"@
}

$html += @"
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Test</th>
                        <th>Descripción</th>
                        <th>Error Type</th>
                        <th>Mensaje de Error</th>
                        <th>Origen (archivo:línea)</th>
                        <th>Tiempo (ms)</th>
                    </tr>
                </thead>
                <tbody>
"@

foreach ($step in ($allSteps | Where-Object { $_.EsFallo })) {
    $html += @"
                    <tr class="ERROR">
                        <td><strong>$(Encode-HtmlSpecialChars $step.Test)</strong></td>
                        <td>$(Encode-HtmlSpecialChars $step.Descripcion)</td>
                        <td><span class="badge badge-error">$($step.ErrorType)</span></td>
                        <td><small>$(Encode-HtmlSpecialChars $step.ErrorMessage)</small></td>
                        <td><code>$(Encode-HtmlSpecialChars $step.ErrorSource)</code></td>
                        <td>$($step.Tiempo_ms)</td>
                    </tr>

"@
}

$html += @"
                </tbody>
            </table>
        </div>
        
        <div id="lentos" class="tab-content">
            <h3>Pasos que tardaron más de 5 segundos</h3>
            <table>
                <thead>
                    <tr>
                        <th>Test</th>
                        <th>Batch</th>
                        <th>Descripción</th>
                        <th>Acción</th>
                        <th>Tiempo (s)</th>
                        <th>% del Total</th>
                    </tr>
                </thead>
                <tbody>
"@

foreach ($step in ($allSteps | Where-Object { $_.Tiempo_ms -gt 5000 } | Sort-Object -Property Tiempo_ms -Descending)) {
    $percentageOfTotal = [math]::Round(($step.Tiempo_ms / ($totalTime * 1000) * 100), 1)
    $html += @"
                    <tr>
                        <td><strong>$(Encode-HtmlSpecialChars $step.Test)</strong></td>
                        <td>$($step.Batch)</td>
                        <td>$(Encode-HtmlSpecialChars $step.Descripcion)</td>
                        <td><small>$(Encode-HtmlSpecialChars $step.Accion)</small></td>
                        <td><strong style="color: #ffc107;">$($step.Tiempo_s)</strong></td>
                        <td>$percentageOfTotal%</td>
                    </tr>

"@
}

$html += @"
                </tbody>
            </table>
        </div>
        
        <footer>
            <p>&#128200; Reporte generado autom&aacute;ticamente | Total de pasos procesados: $($allSteps.Count) | &#128295; Sara3 Automation Framework</p>
        </footer>
    </div>
    
    <script>
        function showTab(tabName, button) {
            var tabs = document.getElementsByClassName('tab-content');
            for (var i = 0; i < tabs.length; i++) {
                tabs[i].classList.remove('active');
            }
            var buttons = document.getElementsByClassName('tab-button');
            for (var i = 0; i < buttons.length; i++) {
                buttons[i].classList.remove('active');
            }
            document.getElementById(tabName).classList.add('active');
            button.classList.add('active');
            
            if (tabName === 'resumen') {
                setTimeout(function() {
                    if (chart1) chart1.resize();
                    if (chart2) chart2.resize();
                }, 100);
            }
        }
        
        function filtrarTabla(tableId, filter) {
            var table = document.getElementById(tableId);
            var rows = table.getElementsByTagName('tbody')[0].getElementsByTagName('tr');
            for (var i = 0; i < rows.length; i++) {
                var text = rows[i].textContent.toLowerCase();
                rows[i].style.display = text.indexOf(filter.toLowerCase()) > -1 ? '' : 'none';
            }
        }
        
        var chart1, chart2;
        
        var ctxEstados = document.getElementById('chartEstados').getContext('2d');
        chart1 = new Chart(ctxEstados, {
            type: 'doughnut',
            data: {
                labels: ['Exitosos', 'Con Error'],
                datasets: [{
                    data: [$successCount, $errorCount],
                    backgroundColor: ['#28a745', '#dc3545'],
                    borderColor: ['white', 'white'],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' },
                    title: { display: true, text: 'Estado de Pasos' }
                }
            }
        });
        
        var ctxErrores = document.getElementById('chartErrores').getContext('2d');
        chart2 = new Chart(ctxErrores, {
            type: 'bar',
            data: {
                labels: ['Selenium', 'UI', 'Data', 'Validacion', 'Otros'],
                datasets: [{
                    label: 'Cantidad de Errores',
                    data: [
                        $(@($allSteps | Where-Object { $_.ErrorType -eq 'Selenium' }).Count),
                        $(@($allSteps | Where-Object { $_.ErrorType -eq 'UI' }).Count),
                        $(@($allSteps | Where-Object { $_.ErrorType -eq 'Data' }).Count),
                        $(@($allSteps | Where-Object { $_.ErrorType -eq 'Validacion' }).Count),
                        $(@($allSteps | Where-Object { $_.ErrorType -eq 'Otros' }).Count)
                    ],
                    backgroundColor: '#0078d4',
                    borderColor: '#106ebe',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                indexAxis: 'y',
                plugins: {
                    legend: { display: false },
                    title: { display: true, text: 'Errores por Tipo' }
                }
            }
        });
    </script>
</body>
</html>
"@

# Guardar HTML con encoding UTF-8 BOM para máxima compatibilidad con navegadores
$utf8WithBom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($htmlPath, $html, $utf8WithBom)
Write-Host "HTML generado: $htmlPath" -ForegroundColor Green

# ===== RESUMEN =====

Write-Host ""
Write-Host "Reportes generados exitosamente:" -ForegroundColor Green
Write-Host "  - $excelPath" -ForegroundColor Cyan
Write-Host "  - $csvPath" -ForegroundColor Cyan
Write-Host "  - $htmlPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total de pasos procesados: $($allSteps.Count)" -ForegroundColor Green
