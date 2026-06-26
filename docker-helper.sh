#!/bin/bash
# ============================================================
# SARA3 - DOCKER HELPER SCRIPT
# Facilita operaciones comunes con Docker
# ============================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# FUNCIONES
# ============================================================

show_menu() {
    clear
    echo -e "${BLUE}"
    echo "=========================================================="
    echo "  SARA3 - DOCKER HELPER"
    echo "=========================================================="
    echo -e "${NC}"
    echo ""
    echo "  1. Build imagen Docker"
    echo "  2. Ejecutar batch tests 8 paralelo"
    echo "  3. Ejecutar menú interactivo"
    echo "  4. Ejecutar test individual"
    echo "  5. Ver logs del último contenedor"
    echo "  6. Limpiar imágenes y contenedores"
    echo "  7. Ver información Docker"
    echo "  8. Ejecutar con docker-compose"
    echo "  9. Salir"
    echo ""
    read -p "Selecciona opción (1-9): " choice
}

build_image() {
    echo -e "${BLUE}Construyendo imagen Docker...${NC}"
    docker build -t sara3:latest .
    echo -e "${GREEN}✓ Imagen construida exitosamente${NC}"
    docker images | grep sara3
}

run_batch_tests() {
    read -p "Numero de runners en paralelo [8]: " forks
    forks=${forks:-8}
    echo -e "${BLUE}Ejecutando $forks runners en paralelo...${NC}"
    mkdir -p target logs

    docker run --rm \
        --name "sara3-batch-$(date +%s)" \
        -e RUNNERS="$forks" \
        -v "$(pwd)/target:/app/target" \
        -v "$(pwd)/logs:/app/logs" \
        sara3:latest

    echo -e "${GREEN}✓ Tests completados${NC}"
    echo ""
    echo "Reportes disponibles en:"
    ls -lh target/reports/ 2>/dev/null || echo "No reports found"
}

run_interactive() {
    echo -e "${BLUE}Ejecutando menú interactivo...${NC}"
    mkdir -p target logs

    docker run -it --rm \
        --name "sara3-interactive-$(date +%s)" \
        -v "$(pwd)/target:/app/target" \
        -v "$(pwd)/logs:/app/logs" \
        sara3:latest
}

run_single_test() {
    read -p "Número del test (1-50): " test_num
    
    if ! [[ "$test_num" =~ ^[0-9]+$ ]] || [ "$test_num" -lt 1 ] || [ "$test_num" -gt 50 ]; then
        echo -e "${RED}Número inválido${NC}"
        return
    fi
    
    test_formatted=$(printf "%02d" "$test_num")

    echo -e "${BLUE}Ejecutando test $test_num...${NC}"
    mkdir -p target logs

    docker run --rm \
        --name "sara3-single-$(date +%s)" \
        -v "$(pwd)/target:/app/target" \
        -v "$(pwd)/logs:/app/logs" \
        sara3:latest \
        bash -c "./gradlew test --tests 'com.sara.automation.runners.CasesRunner$test_formatted'"

    echo -e "${GREEN}✓ Test completado${NC}"
}

view_logs() {
    echo -e "${BLUE}Últimos logs...${NC}"
    docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Status}}" | head -5
    
    LATEST_CONTAINER=$(docker ps -a -q --filter "ancestor=sara3:latest" | head -1)
    
    if [ -z "$LATEST_CONTAINER" ]; then
        echo -e "${YELLOW}No hay contenedores sara3 ejecutados${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}Logs del contenedor: $LATEST_CONTAINER${NC}"
    docker logs --tail=50 "$LATEST_CONTAINER"
}

cleanup() {
    echo -e "${YELLOW}Limpiando Docker...${NC}"
    
    # Contenedores parados
    echo "Eliminando contenedores parados..."
    docker container prune -f
    
    # Imágenes sin usar
    echo "Eliminando imágenes sin usar..."
    docker image prune -f
    
    # Volúmenes sin usar
    echo "Eliminando volúmenes sin usar..."
    docker volume prune -f
    
    echo -e "${GREEN}✓ Limpieza completada${NC}"
    docker system df
}

docker_info() {
    echo -e "${BLUE}========== INFORMACIÓN DOCKER ==========${NC}"
    echo ""
    
    echo -e "${YELLOW}Docker Version:${NC}"
    docker --version
    echo ""
    
    echo -e "${YELLOW}Docker Compose Version:${NC}"
    docker-compose --version 2>/dev/null || echo "No instalado"
    echo ""
    
    echo -e "${YELLOW}Imágenes Sara3:${NC}"
    docker images | grep sara3 || echo "Sin imágenes"
    echo ""
    
    echo -e "${YELLOW}Contenedores corriendo:${NC}"
    docker ps --filter "ancestor=sara3:latest" || echo "Ninguno corriendo"
    echo ""
    
    echo -e "${YELLOW}Uso de disco:${NC}"
    docker system df
}

docker_compose_menu() {
    echo -e "${BLUE}========== DOCKER COMPOSE ==========${NC}"
    echo ""
    echo "  1. Up - Iniciar servicios"
    echo "  2. Down - Detener servicios"
    echo "  3. Batch tests"
    echo "  4. Menú interactivo"
    echo "  5. Logs"
    echo "  6. Volver"
    echo ""
    read -p "Selecciona opción: " compose_choice
    
    case $compose_choice in
        1) docker-compose up -d ;;
        2) docker-compose down ;;
        3) docker-compose up sara3-batch ;;
        4) docker-compose up sara3-interactive ;;
        5) docker-compose logs -f ;;
        6) return ;;
        *) echo -e "${RED}Opción inválida${NC}" ;;
    esac
}

# ============================================================
# PROGRAMA PRINCIPAL
# ============================================================

main() {
    while true; do
        show_menu
        
        case $choice in
            1) build_image ;;
            2) run_batch_tests ;;
            3) run_interactive ;;
            4) run_single_test ;;
            5) view_logs ;;
            6) cleanup ;;
            7) docker_info ;;
            8) docker_compose_menu ;;
            9) 
                echo -e "${GREEN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opción inválida${NC}"
                sleep 2
                ;;
        esac
        
        echo ""
        read -p "Presiona ENTER para continuar..."
    done
}

main
