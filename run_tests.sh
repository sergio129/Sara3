#!/bin/bash
# ============================================================
# SARA3 - LINUX HEADLESS TEST RUNNER
# Equivalente a run_tests.bat para Linux
# ============================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================
# VALIDAR Y CORREGIR JAVA_HOME ANTES DE LLAMAR A GRADLEW
# ============================================================
validate_java() {
    if [ -n "$JAVA_HOME" ]; then
        if [ ! -f "$JAVA_HOME/bin/java" ]; then
            echo -e "${YELLOW}ADVERTENCIA: JAVA_HOME invalido: $JAVA_HOME${NC}"
            unset JAVA_HOME
        fi
    fi
    
    if [ -z "$JAVA_HOME" ]; then
        # Buscar JDK 1.8 o superior
        if [ -d "/usr/lib/jvm/java-8-openjdk-amd64" ]; then
            export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
        elif [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
            export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
        elif [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
            export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
        elif [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
            export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
        elif command -v java &> /dev/null; then
            JAVA_PATH=$(readlink -f $(which java))
            export JAVA_HOME="${JAVA_PATH%/bin/java}"
        else
            echo -e "${RED}ERROR: No se encontro una instalacion de Java valida.${NC}"
            echo "Instala JDK 8+ o configura JAVA_HOME correctamente."
            exit 1
        fi
    fi
    
    echo -e "${GREEN}JAVA_HOME: $JAVA_HOME${NC}"
}

# ============================================================
# CONFIGURAR VARIABLES DE CHROME HEADLESS
# ============================================================
configure_chrome_headless() {
    export CHROME_BIN=$(which chromium-browser || which google-chrome || which chrome || echo "chrome")
    
    if [ ! -f "$CHROME_BIN" ]; then
        echo -e "${RED}ERROR: Chrome/Chromium no encontrado${NC}"
        echo "Instala: sudo apt-get install chromium-browser"
        exit 1
    fi
    
    # Variables de display para headless
    export DISPLAY=""
    export QT_QPA_PLATFORM="offscreen"
    
    # Opciones headless para Chrome
    export CHROME_HEADLESS="--headless"
    export CHROME_NO_SANDBOX="--no-sandbox"
    export CHROME_DISABLE_GPU="--disable-gpu"
    # NO --disable-dev-shm-usage: el contenedor usa /dev/shm amplio (--shm-size/shm_size).
    # Ver nota en serenity.properties. (Estas vars no se consumen; Chrome lee chrome.switches.)
    
    echo -e "${GREEN}Chrome Headless configurado${NC}"
}

# ============================================================
# COMPILAR PROYECTO
# ============================================================
compile_project() {
    echo ""
    echo -e "${BLUE}========================================================${NC}"
    echo -e "${BLUE}         SARA3 - Descargando dependencias...${NC}"
    echo -e "${BLUE}========================================================${NC}"
    echo ""
    echo "(Primera vez: 3-5 minutos. Siguientes: 30 segundos)"
    echo ""
    
    if ! chmod +x ./gradlew; then
        echo -e "${RED}ERROR: No se pudo dar permisos al gradlew${NC}"
        exit 1
    fi
    
    if ! ./gradlew compileTestJava -q; then
        echo ""
        echo -e "${RED}ERROR: No se pudo compilar el proyecto${NC}"
        echo "Verifica tu conexion a internet"
        echo ""
        exit 1
    fi
}

# ============================================================
# EJECUTAR TESTS CON NUMERO PERSONALIZADO DE RUNNERS
# ============================================================
run_custom_runners() {
    read -p "Numero de runners (1-50): " FORKS
    
    if ! [[ "$FORKS" =~ ^[0-9]+$ ]] || [ "$FORKS" -lt 1 ] || [ "$FORKS" -gt 50 ]; then
        echo -e "${RED}ERROR: Numero invalido${NC}"
        return
    fi
    
    sed -i "s/^maxParallelForks=.*/maxParallelForks=$FORKS/" gradle.properties
    
    echo -e "${BLUE}Ejecutando $FORKS runners en paralelo...${NC}"
    ./gradlew test --parallel
    
    echo ""
    echo -e "${GREEN}[INFO] Ejecucion completada${NC}"
    generate_reports
}

# ============================================================
# EJECUTAR N RUNNERS EN PARALELO
# ============================================================
run_n_parallel() {
    local FORKS=$1
    
    sed -i "s/^maxParallelForks=.*/maxParallelForks=$FORKS/" gradle.properties
    
    echo -e "${BLUE}Ejecutando $FORKS runners en paralelo...${NC}"
    ./gradlew test --parallel
    
    echo ""
    echo -e "${GREEN}[INFO] Ejecucion completada${NC}"
    generate_reports
}

# ============================================================
# EJECUTAR 1 RUNNER INDIVIDUAL
# ============================================================
run_one_runner() {
    read -p "Numero del runner (1-50): " RUNNER_NUM
    
    if ! [[ "$RUNNER_NUM" =~ ^[0-9]+$ ]] || [ "$RUNNER_NUM" -lt 1 ] || [ "$RUNNER_NUM" -gt 50 ]; then
        echo -e "${RED}ERROR: Numero invalido${NC}"
        return
    fi
    
    # Agregar cero a la izquierda si es menor a 10
    RUNNER_FORMATTED=$(printf "%02d" "$RUNNER_NUM")
    
    sed -i "s/^maxParallelForks=.*/maxParallelForks=1/" gradle.properties
    
    echo -e "${BLUE}Ejecutando runner: CasesRunner$RUNNER_FORMATTED${NC}"
    ./gradlew test --tests "com.sara.automation.runners.CasesRunner$RUNNER_FORMATTED"
    
    echo ""
    echo -e "${GREEN}[INFO] Ejecucion completada del runner individual${NC}"
    generate_reports
}

# ============================================================
# EJECUTAR 1 SCENARIO SIN PARALELO
# ============================================================
run_one_no_parallel() {
    read -p "Numero del scenario (1-50): " BATCH_NUM
    
    if ! [[ "$BATCH_NUM" =~ ^[0-9]+$ ]] || [ "$BATCH_NUM" -lt 1 ] || [ "$BATCH_NUM" -gt 50 ]; then
        echo -e "${RED}ERROR: Numero invalido${NC}"
        return
    fi
    
    BATCH_NUM_FORMATTED=$(printf "%02d" "$BATCH_NUM")
    
    sed -i "s/^maxParallelForks=.*/maxParallelForks=1/" gradle.properties
    
    echo -e "${BLUE}Ejecutando SCENARIO $BATCH_NUM SIN PARALELO...${NC}"
    ./gradlew test --tests "com.sara.automation.runners.CasesRunner$BATCH_NUM_FORMATTED" -Dgeb.env=chrome
    
    echo ""
    echo -e "${GREEN}[INFO] Ejecucion completada del scenario $BATCH_NUM${NC}"
    generate_reports
}

# ============================================================
# GENERAR REPORTES
# ============================================================
generate_reports() {
    echo ""
    echo -e "${BLUE}[INFO] Generando reportes en 3 formatos: Excel, CSV e HTML...${NC}"
    sleep 2
    
    if [ -f "script/generate_step_details_excel_report_CLEAN.ps1" ]; then
        pwsh -ExecutionPolicy Bypass -File "script/generate_step_details_excel_report_CLEAN.ps1" 2>/dev/null || true
    fi
    
    echo ""
    echo -e "${GREEN}[INFO] Reportes generados en: target/reports/${NC}"
    echo "       - step_details_*.xlsx (Excel)"
    echo "       - step_details_*.csv  (CSV)"
    echo "       - step_details_*.html (HTML)"
    echo ""
}

# ============================================================
# MENU PRINCIPAL
# ============================================================
show_menu() {
    clear
    echo ""
    echo -e "${BLUE}========================================================${NC}"
    echo -e "${BLUE}       AUTOMATIZACION SARA3 - EJECUCION DE PRUEBAS${NC}"
    echo -e "${BLUE}========================================================${NC}"
    echo ""
    echo "  1. Ejecutar numero personalizado de runners"
    echo "  2. Ejecutar  2 runners en paralelo"
    echo "  3. Ejecutar  4 runners en paralelo"
    echo "  4. Ejecutar  8 runners en paralelo"
    echo "  5. Ejecutar 12 runners en paralelo"
    echo "  6. Ejecutar 50 runners en paralelo"
    echo "  7. Ejecutar  1 runner individual (con numero 1-50)"
    echo "  8. Ejecutar 1 SCENARIO sin paralelo"
    echo "  9. Ver reporte de resultados"
    echo " 10. Salir"
    echo ""
    read -p "Selecciona opcion (1-10): " choice
}

# ============================================================
# PROGRAMA PRINCIPAL
# ============================================================
main() {
    validate_java
    configure_chrome_headless
    compile_project
    
    while true; do
        show_menu
        
        case $choice in
            1) run_custom_runners ;;
            2) run_n_parallel 2 ;;
            3) run_n_parallel 4 ;;
            4) run_n_parallel 8 ;;
            5) run_n_parallel 12 ;;
            6) run_n_parallel 50 ;;
            7) run_one_runner ;;
            8) run_one_no_parallel ;;
            9) 
                if [ -f "target/site/serenity/index.html" ]; then
                    echo "Reporte disponible en: target/site/serenity/index.html"
                else
                    echo -e "${RED}No hay reporte. Ejecuta primero los tests.${NC}"
                fi
                read -p "Presiona ENTER para continuar..."
                ;;
            10) 
                echo -e "${GREEN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *) echo -e "${RED}Opcion invalida${NC}" ;;
        esac
    done
}

# Ejecutar programa principal
main


