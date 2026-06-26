#!/bin/bash
# ============================================================
# SARA3 - AUTOMATED 8-PARALLEL BATCH TEST EXECUTOR
# Ejecuta 8 tests en paralelo y genera reportes CSV
# Diseñado para tareas programadas (cron/scheduler)
# ============================================================

set -e

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
REPORT_DIR="$SCRIPT_DIR/target/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/batch_test_${TIMESTAMP}.log"

# Número de runners en paralelo (parametrizable). Default: 8
RUNNERS="${RUNNERS:-8}"
if ! [[ "$RUNNERS" =~ ^[0-9]+$ ]] || [ "$RUNNERS" -lt 1 ] || [ "$RUNNERS" -gt 50 ]; then
    echo "ERROR: RUNNERS invalido ('$RUNNERS'). Debe ser un numero entre 1 y 50." >&2
    exit 1
fi

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# CREAR DIRECTORIOS SI NO EXISTEN
# ============================================================
mkdir -p "$LOG_DIR"
mkdir -p "$REPORT_DIR"

# ============================================================
# LOGGING
# ============================================================
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_success() { log "SUCCESS" "$@"; }
log_error() { log "ERROR" "$@"; }
log_warning() { log "WARNING" "$@"; }

# ============================================================
# VALIDACIONES PREVIAS
# ============================================================
validate_environment() {
    log_info "================================"
    log_info "VALIDANDO ENTORNO"
    log_info "================================"
    
    # Java
    if ! command -v java &> /dev/null; then
        log_error "Java no encontrado"
        exit 1
    fi
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    log_info "Java: $JAVA_VERSION"
    
    # Chrome
    if ! command -v chromium-browser &> /dev/null && ! command -v google-chrome &> /dev/null; then
        log_error "Chrome/Chromium no encontrado"
        exit 1
    fi
    CHROME_VERSION=$(chromium-browser --version 2>/dev/null || google-chrome --version 2>/dev/null)
    log_info "Chrome: $CHROME_VERSION"
    
    # ChromeDriver (opcional: Selenium Manager lo resuelve automáticamente si falta)
    if command -v chromedriver &> /dev/null; then
        CHROMEDRIVER_VERSION=$(chromedriver --version 2>/dev/null | cut -d' ' -f1-3)
        log_info "ChromeDriver: $CHROMEDRIVER_VERSION"
    else
        log_warning "chromedriver no está en PATH; Selenium Manager lo descargará/resolverá en runtime"
    fi
    
    # Gradle
    if [ ! -f "$SCRIPT_DIR/gradlew" ]; then
        log_error "gradlew no encontrado en $SCRIPT_DIR"
        exit 1
    fi
    
    # Serenity config
    if ! grep -q "headless" "$SCRIPT_DIR/serenity.properties" 2>/dev/null; then
        log_warning "serenity.properties no tiene configuración headless, pero continuando..."
    fi
    
    log_success "Validaciones completadas"
}

# ============================================================
# CONFIGURAR VARIABLES DE ENTORNO
# ============================================================
setup_environment() {
    log_info "Configurando variables de entorno para headless..."
    
    export DISPLAY=""
    export QT_QPA_PLATFORM="offscreen"
    export JAVA_OPTS="-Xmx2048m -Xms512m"
    
    # Detectar Chrome binary
    if command -v chromium-browser &> /dev/null; then
        export CHROME_BIN="/usr/bin/chromium-browser"
    elif command -v google-chrome &> /dev/null; then
        export CHROME_BIN="/usr/bin/google-chrome"
    fi
    
    log_info "Chrome binary: $CHROME_BIN"
    log_success "Variables configuradas"
}

# ============================================================
# LIMPIAR BUILDS ANTERIORES
# ============================================================
clean_previous_builds() {
    log_info "Limpiando builds anteriores..."

    # Borrar el CONTENIDO, no los directorios: target/ suele ser un bind-mount de Docker
    # y eliminar el punto de montaje falla ("device busy") y aborta el script.
    rm -rf "$SCRIPT_DIR/build"/* "$SCRIPT_DIR/build"/.[!.]* 2>/dev/null || true
    rm -rf "$SCRIPT_DIR/target"/* "$SCRIPT_DIR/target"/.[!.]* 2>/dev/null || true
    mkdir -p "$REPORT_DIR" "$SCRIPT_DIR/target/site"

    log_success "Limpieza completada"
}

# ============================================================
# COMPILAR PROYECTO
# ============================================================
compile_project() {
    log_info "================================"
    log_info "COMPILANDO PROYECTO"
    log_info "================================"
    
    cd "$SCRIPT_DIR"
    chmod +x gradlew
    
    if ! ./gradlew compileTestJava -q; then
        log_error "Compilación fallida"
        exit 1
    fi
    
    log_success "Compilación completada"
}

# ============================================================
# CONFIGURAR PARALELO A 8
# ============================================================
configure_parallel() {
    log_info "Configurando $RUNNERS runners en paralelo..."

    # Actualizar gradle.properties
    if grep -q "^maxParallelForks=" "$SCRIPT_DIR/gradle.properties"; then
        sed -i "s/^maxParallelForks=.*/maxParallelForks=$RUNNERS/" "$SCRIPT_DIR/gradle.properties"
    else
        echo "maxParallelForks=$RUNNERS" >> "$SCRIPT_DIR/gradle.properties"
    fi
    
    PARALLEL_SETTING=$(grep "^maxParallelForks=" "$SCRIPT_DIR/gradle.properties")
    log_info "Configuración: $PARALLEL_SETTING"
    log_success "Paralelo configurado"
}

# ============================================================
# EJECUTAR TESTS
# ============================================================
run_tests() {
    log_info "================================"
    log_info "EJECUTANDO $RUNNERS TESTS EN PARALELO"
    log_info "================================"
    
    cd "$SCRIPT_DIR"
    
    # Capturar tiempo de inicio
    TEST_START=$(date +%s)
    
    # Ejecutar tests (permitir fallos para completar la ejecución)
    if ./gradlew test --parallel 2>&1 | tee -a "$LOG_FILE"; then
        TEST_RESULT="SUCCESS"
        log_success "Todos los tests pasaron"
    else
        TEST_RESULT="PARTIAL_FAILURE"
        log_warning "Algunos tests fallaron, pero continuando con reportes..."
    fi
    
    # Capturar tiempo de fin
    TEST_END=$(date +%s)
    TEST_DURATION=$((TEST_END - TEST_START))
    
    log_info "Duración total: ${TEST_DURATION}s"
    log_info "Resultado: $TEST_RESULT"
}

# ============================================================
# GENERAR REPORTES CSV
# ============================================================
generate_csv_reports() {
    log_info "================================"
    log_info "GENERANDO REPORTES CSV"
    log_info "================================"
    
    cd "$SCRIPT_DIR"
    
    # Usar PowerShell si está disponible para generar reportes avanzados
    if command -v pwsh &> /dev/null; then
        if [ -f "script/generate_step_details_excel_report_CLEAN.ps1" ]; then
            log_info "Ejecutando script PowerShell de reportes..."
            pwsh -ExecutionPolicy Bypass -File "script/generate_step_details_excel_report_CLEAN.ps1" 2>/dev/null || {
                log_warning "Script PowerShell ejecutado pero puede haber advertencias"
            }
        fi
    fi
    
    # Generar CSV adicional simple de resultados
    if [ -d "build/test-results/test" ]; then
        generate_simple_csv_report
    else
        log_warning "No se encontraron resultados de tests en build/test-results/"
    fi
    
    log_success "Reportes CSV generados"
}

# ============================================================
# GENERAR REPORTE CSV SIMPLE
# ============================================================
generate_simple_csv_report() {
    local output_file="$REPORT_DIR/test_results_${TIMESTAMP}.csv"
    
    log_info "Generando reporte CSV simple: $output_file"
    
    # Crear encabezado
    echo "Test Name,Status,Duration (ms),Timestamp" > "$output_file"
    
    # Procesar archivos XML de resultados
    if [ -f "build/test-results/test/TEST-*.xml" ]; then
        grep -r 'testcase\|system-out\|system-err' "build/test-results/test/" 2>/dev/null | \
        while read line; do
            # Extraer información del test (simplificado)
            echo "$line,$(date +%s)" >> "$output_file" 2>/dev/null || true
        done
    fi
    
    if [ -s "$output_file" ]; then
        log_success "CSV generado: $output_file"
        wc -l "$output_file" | awk '{print "Total líneas:", $1}' | xargs log_info
    fi
}

# ============================================================
# GENERAR RESUMEN EJECUTIVO
# ============================================================
generate_summary() {
    local summary_file="$REPORT_DIR/execution_summary_${TIMESTAMP}.txt"
    
    log_info "Generando resumen ejecutivo..."
    
    cat > "$summary_file" << EOF
================================================================================
                     SARA3 BATCH TEST EXECUTION SUMMARY
================================================================================
Execution Date: $(date '+%Y-%m-%d %H:%M:%S')
Log File: $LOG_FILE
Report Directory: $REPORT_DIR

CONFIGURATION:
  - Parallel Runners: 8
  - Mode: Headless
  - Java: $(java -version 2>&1 | head -1)
  - Chrome: $(chromium-browser --version 2>/dev/null || google-chrome --version)

REPORTS GENERATED:
  - target/site/serenity/index.html (Serenity HTML Report)
  - target/reports/step_details_*.csv (Step-by-step CSV)
  - target/reports/step_details_*.html (HTML Details)
  - $summary_file (This Summary)

NEXT STEPS:
  1. Review CSV reports in: $REPORT_DIR
  2. Download full HTML report from: target/site/serenity/index.html
  3. Check logs: $LOG_FILE

FOR SCHEDULED EXECUTION:
  - Add to cron: crontab -e
  - Example (daily at 2 AM): 0 2 * * * $SCRIPT_DIR/batch_test_8p.sh

================================================================================
EOF
    
    log_success "Resumen generado: $summary_file"
}

# ============================================================
# VALIDAR REPORTES
# ============================================================
validate_reports() {
    log_info "Validando reportes generados..."
    
    local reports_found=0
    
    # CSV reports
    if ls "$REPORT_DIR"/step_details_*.csv 1>/dev/null 2>&1; then
        local csv_count=$(ls "$REPORT_DIR"/step_details_*.csv | wc -l)
        log_success "Reportes CSV encontrados: $csv_count"
        reports_found=$((reports_found + csv_count))
    fi
    
    # HTML reports
    if ls "$REPORT_DIR"/step_details_*.html 1>/dev/null 2>&1; then
        local html_count=$(ls "$REPORT_DIR"/step_details_*.html | wc -l)
        log_success "Reportes HTML encontrados: $html_count"
        reports_found=$((reports_found + html_count))
    fi
    
    # Serenity report
    if [ -f "$SCRIPT_DIR/target/site/serenity/index.html" ]; then
        log_success "Reporte Serenity HTML encontrado"
        reports_found=$((reports_found + 1))
    fi
    
    if [ $reports_found -eq 0 ]; then
        log_warning "No se encontraron reportes. Esto podría ser normal si hay fallos"
    else
        log_success "Total reportes: $reports_found"
    fi
}

# ============================================================
# CLEANUP Y FINALIZACIÓN
# ============================================================
cleanup() {
    log_info "Realizando cleanup..."
    
    # Crear archivo de marker para indicar última ejecución
    touch "$LOG_DIR/.last_execution_$(date +%s)"
    
    # Mantener solo los últimos 7 logs
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "batch_test_*.log" -mtime +7 -delete
        log_info "Logs antiguos (>7 días) eliminados"
    fi
}

# ============================================================
# MANEJO DE ERRORES
# ============================================================
error_handler() {
    local line_no=$1
    log_error "Error en línea $line_no"
    log_error "Ejecución interrumpida"
    cleanup
    exit 1
}

trap 'error_handler ${LINENO}' ERR

# ============================================================
# PROGRAMA PRINCIPAL
# ============================================================
main() {
    log_info "=================================================="
    log_info "  SARA3 AUTOMATED 8-PARALLEL BATCH TEST RUNNER"
    log_info "=================================================="
    
    validate_environment
    setup_environment
    clean_previous_builds
    compile_project
    configure_parallel
    run_tests
    generate_csv_reports
    generate_summary
    validate_reports
    cleanup
    
    log_success "=================================================="
    log_success "  EJECUCIÓN COMPLETADA CON ÉXITO"
    log_success "=================================================="
    log_info "Reportes disponibles en: $REPORT_DIR"
    log_info "Logs disponibles en: $LOG_FILE"
}

# Ejecutar
main


