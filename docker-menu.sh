#!/bin/bash
set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para actualizar maxParallelForks
update_parallel_forks() {
    local forks=$1
    sed -i "s/^maxParallelForks=.*/maxParallelForks=$forks/" gradle.properties
    echo -e "${GREEN}[CONFIG] maxParallelForks configurado a: $forks${NC}"
}

# Función para generar reportes Excel/CSV/HTML (reusa el mismo .ps1 que Windows vía PowerShell Core)
generate_reports() {
    echo ""
    echo -e "${BLUE}[INFO] Generando reportes (Excel, CSV, HTML)...${NC}"
    if command -v pwsh &> /dev/null; then
        set +e
        pwsh -ExecutionPolicy Bypass -File script/generate_step_details_excel_report_CLEAN.ps1 \
            -serenityReportPath /app/target/site/serenity \
            -outputPath /app/target/reports
        set -e
        echo -e "${GREEN}[INFO] Reportes en: /app/target/reports/${NC}"
        echo "        - step_details_*.xlsx (Excel)"
        echo "        - step_details_*.csv  (CSV)"
        echo "        - step_details_*.html (HTML)"
    else
        echo -e "${YELLOW}[WARN] pwsh no disponible; se omiten reportes Excel/CSV/HTML${NC}"
    fi
}

# Función para ejecutar tests
run_tests() {
    local test_class=$1
    local parallel_flag=$2
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  EJECUTANDO TESTS${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    set +e
    if [ -z "$test_class" ]; then
        ./gradlew test $parallel_flag --continue --no-daemon
    else
        ./gradlew test --tests "$test_class" $parallel_flag --continue --no-daemon
    fi
    TEST_RESULT=$?
    set -e
    
    echo ""
    if [ $TEST_RESULT -eq 0 ]; then
        echo -e "${GREEN}✓ TESTS COMPLETADOS${NC}"
    else
        echo -e "${YELLOW}⚠ Tests completados con algunos errores (Exit: $TEST_RESULT)${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}[INFO] Reporte disponible en: target/site/serenity/index.html${NC}"

    # Generar reportes Excel/CSV/HTML automáticamente al terminar (igual que run_tests.bat en Windows)
    generate_reports

    echo ""
    read -p "Presiona ENTER para continuar..."
}

# Función para mostrar el menú
show_menu() {
    clear
    echo ""
    echo -e "${CYAN}========================================================${NC}"
    echo -e "${CYAN}       SARA3 DOCKER - MENU DE EJECUCION DE TESTS${NC}"
    echo -e "${CYAN}========================================================${NC}"
    echo ""
    echo -e "${GREEN} 1.${NC} Ejecutar número personalizado de runners"
    echo -e "${GREEN} 2.${NC} Ejecutar  2 runners en paralelo"
    echo -e "${GREEN} 3.${NC} Ejecutar  4 runners en paralelo"
    echo -e "${GREEN} 4.${NC} Ejecutar  8 runners en paralelo"
    echo -e "${GREEN} 5.${NC} Ejecutar 12 runners en paralelo"
    echo -e "${GREEN} 6.${NC} Ejecutar 50 runners en paralelo (TODOS)"
    echo -e "${GREEN} 7.${NC} Ejecutar 1 runner individual (número 1-50)"
    echo -e "${GREEN} 8.${NC} Ver reporte HTML (copiar ruta para abrir en host)"
    echo -e "${GREEN} 9.${NC} Ver configuración actual"
    echo -e "${GREEN}10.${NC} Limpiar reportes"
    echo -e "${GREEN}11.${NC} Salir del contenedor"
    echo ""
    echo -ne "${YELLOW}Selecciona opción (1-11): ${NC}"
}

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1)
            echo ""
            read -p "Número de runners (1-50): " forks
            if [[ $forks =~ ^[0-9]+$ ]] && [ $forks -ge 1 ] && [ $forks -le 50 ]; then
                update_parallel_forks $forks
                run_tests "" "--parallel"
            else
                echo -e "${RED}Error: Ingresa un número entre 1 y 50${NC}"
                read -p "Presiona ENTER para continuar..."
            fi
            ;;
        2)
            update_parallel_forks 2
            run_tests "" "--parallel"
            ;;
        3)
            update_parallel_forks 4
            run_tests "" "--parallel"
            ;;
        4)
            update_parallel_forks 8
            run_tests "" "--parallel"
            ;;
        5)
            update_parallel_forks 12
            run_tests "" "--parallel"
            ;;
        6)
            echo ""
            echo -e "${YELLOW}ADVERTENCIA: Ejecutar 50 tests en paralelo requiere recursos significativos${NC}"
            read -p "¿Continuar? (s/n): " confirm
            if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                update_parallel_forks 50
                run_tests "" "--parallel"
            fi
            ;;
        7)
            echo ""
            read -p "Número del runner (1-50): " runner_num
            if [[ $runner_num =~ ^[0-9]+$ ]] && [ $runner_num -ge 1 ] && [ $runner_num -le 50 ]; then
                # Formatear con cero a la izquierda
                runner_formatted=$(printf "%02d" $runner_num)
                update_parallel_forks 1
                run_tests "com.sara.automation.runners.CasesRunner$runner_formatted" ""
            else
                echo -e "${RED}Error: Ingresa un número entre 1 y 50${NC}"
                read -p "Presiona ENTER para continuar..."
            fi
            ;;
        8)
            clear
            echo ""
            echo -e "${CYAN}========================================${NC}"
            echo -e "${CYAN}  UBICACIÓN DEL REPORTE${NC}"
            echo -e "${CYAN}========================================${NC}"
            echo ""
            if [ -f "target/site/serenity/index.html" ]; then
                echo -e "${GREEN}✓ Reporte generado${NC}"
                echo ""
                echo "Ruta en el contenedor:"
                echo "  /app/target/site/serenity/index.html"
                echo ""
                echo "Ruta en tu host (si usaste volumen):"
                echo "  <tu_carpeta_proyecto>/target/site/serenity/index.html"
                echo ""
                echo "Comando Docker para montar volumen:"
                echo -e "${YELLOW}  docker run --rm -v \"\$PWD/target:/app/target\" sara3:latest${NC}"
            else
                echo -e "${YELLOW}⚠ No hay reporte generado aún${NC}"
                echo "Ejecuta los tests primero (opción 1-7)"
            fi
            echo ""
            read -p "Presiona ENTER para continuar..."
            ;;
        9)
            clear
            echo ""
            echo -e "${CYAN}========================================${NC}"
            echo -e "${CYAN}  CONFIGURACIÓN ACTUAL${NC}"
            echo -e "${CYAN}========================================${NC}"
            echo ""
            echo "DISPLAY: $DISPLAY"
            echo "JAVA_VERSION: $(java -version 2>&1 | head -1)"
            echo "CHROME_BIN: $CHROME_BIN"
            echo ""
            if [ -f "gradle.properties" ]; then
                echo "Configuración Gradle:"
                grep "maxParallelForks" gradle.properties || echo "  maxParallelForks no encontrado"
            fi
            echo ""
            if command -v google-chrome &> /dev/null; then
                echo "Google Chrome: $(google-chrome --version)"
            elif command -v chromium-browser &> /dev/null; then
                echo "Chromium: $(chromium-browser --version 2>&1 || echo 'no disponible')"
            fi
            echo ""
            read -p "Presiona ENTER para continuar..."
            ;;
        10)
            clear
            echo ""
            echo -e "${YELLOW}Limpiando reportes...${NC}"
            rm -rf target/site/serenity/* 2>/dev/null || true
            rm -rf target/test-results/* 2>/dev/null || true
            rm -rf build/reports/* 2>/dev/null || true
            echo -e "${GREEN}✓ Reportes limpiados${NC}"
            echo ""
            read -p "Presiona ENTER para continuar..."
            ;;
        11)
            clear
            echo ""
            echo -e "${GREEN}Saliendo del menú...${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}Opción inválida. Selecciona 1-11${NC}"
            sleep 2
            ;;
    esac
done
