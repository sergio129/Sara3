#!/bin/bash
set -e

# Configuración de X11 Virtual Display
export DISPLAY=:99
export XAUTHORITY=/tmp/.Xauthority
export QT_QPA_PLATFORM=offscreen
export TERM=xterm

echo "╔════════════════════════════════════════════════════════╗"
echo "║  🖥️  INICIANDO XVFB PARA DOCKER CONTAINER            ║"
echo "╚════════════════════════════════════════════════════════╝"

# Verificar que Xvfb existe
if ! command -v Xvfb &> /dev/null; then
    echo "❌ ERROR: Xvfb no encontrado. Instalando..."
    apt-get update > /dev/null 2>&1
    apt-get install -y xvfb > /dev/null 2>&1
fi

# Limpiar pantalla virtual anterior si existe
pkill -f "Xvfb :99" 2>/dev/null || true
sleep 1

# Iniciar Xvfb en background
echo "📺 Iniciando Xvfb en :99..."
Xvfb :99 -screen 0 1920x1080x24 -ac -nolisten tcp &
XVFB_PID=$!
echo "✅ Xvfb iniciado con PID: $XVFB_PID"

# Esperar a que Xvfb esté completamente listo
echo "⏳ Esperando que Xvfb esté disponible..."
for i in {1..30}; do
    if DISPLAY=:99 xset q &>/dev/null 2>&1; then
        echo "✅ Xvfb está listo!"
        break
    fi
    echo "  ⏳ Intento $i/30..."
    sleep 1
done

# Verificar que Xvfb sigue corriendo
if ! ps -p $XVFB_PID > /dev/null 2>&1; then
    echo "❌ ERROR: Xvfb falló al iniciarse o se detuvo"
    exit 1
fi

echo "🎬 DISPLAY configurado: $DISPLAY"

# ============================================================
# SELECCIÓN DE MODO DE EJECUCIÓN (auto-detección)
#   1. Comando explícito como argumento  -> se ejecuta tal cual
#   2. Variable RUNNERS definida          -> modo desatendido (RunTest.sh)
#   3. Terminal interactiva (TTY)         -> menú interactivo
#   4. Sin TTY y sin RUNNERS              -> desatendido con default (8)
# ============================================================
if [ $# -gt 0 ]; then
    echo "▶️  Modo comando directo: $@"
    bash -c "$@"
    EXIT_CODE=$?
elif [ -n "$RUNNERS" ]; then
    echo "🤖 Modo desatendido: RUNNERS=$RUNNERS"
    RUNNERS="$RUNNERS" bash /app/RunTest.sh
    EXIT_CODE=$?
elif [ -t 0 ] && [ -t 1 ]; then
    echo "🖥️  Modo interactivo: menú de selección"
    bash /app/docker-menu.sh
    EXIT_CODE=$?
else
    echo "🤖 Sin terminal interactiva y sin RUNNERS → usando default RUNNERS=8"
    RUNNERS=8 bash /app/RunTest.sh
    EXIT_CODE=$?
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
if [ $EXIT_CODE -eq 0 ]; then
    echo "║  ✅ COMPLETADO EXITOSAMENTE                          ║"
else
    echo "║  ⚠️  FINALIZADO CON CÓDIGO: $EXIT_CODE              ║"
fi
echo "╚════════════════════════════════════════════════════════╝"

# Limpiar
echo "🧹 Limpiando Xvfb..."
kill $XVFB_PID 2>/dev/null || true
pkill -f "Xvfb :99" 2>/dev/null || true

exit $EXIT_CODE


