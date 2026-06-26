# ============================================================
# SARA3 - DOCKER IMAGE PARA TESTS HEADLESS
# ------------------------------------------------------------
# SIN apt-get: el servidor no alcanza los repos de Ubuntu (puerto 80).
# Todo se obtiene de imágenes ya construidas (que sí se pueden bajar):
#   - selenium/standalone-chrome : Chrome + chromedriver + Xvfb + X11 + dbus
#   - eclipse-temurin            : JDK 11
#   - mcr.microsoft.com/powershell : pwsh (para el reporte CSV/Excel/HTML)
# ============================================================

# STAGE 1: JDK (solo para copiar el JDK al runtime, sin apt)
FROM eclipse-temurin:11-jdk-jammy AS jdk-source

# STAGE 2: Builder - compila y resuelve dependencias de Gradle (solo necesita JDK)
FROM eclipse-temurin:11-jdk-jammy AS builder
WORKDIR /app
COPY . .
# Normalizar a LF (por si llega algún CRLF) y precargar dependencias
RUN sed -i 's/\r$//' gradlew *.sh 2>/dev/null || true; \
    chmod +x gradlew *.sh && \
    ./gradlew --version && ./gradlew dependencies --write-locks 2>&1 || true

# STAGE 3: PowerShell (para generar el reporte CSV/Excel/HTML, sin apt)
FROM mcr.microsoft.com/powershell:latest AS pwsh-source

# ============================================================
# STAGE 4: Runtime - selenium ya trae Chrome + chromedriver + Xvfb + X11 + dbus
# ============================================================
FROM selenium/standalone-chrome:latest

USER root
WORKDIR /app

# --- JDK 11 (copiado, sin apt) ---
COPY --from=jdk-source /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# --- PowerShell (copiado, sin apt) ---
# Modo "globalization invariant" para no depender de libicu (no instalable por apt aquí).
COPY --from=pwsh-source /opt/microsoft/powershell /opt/microsoft/powershell
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
RUN PWSH_BIN="$(find /opt/microsoft/powershell -maxdepth 2 -name pwsh -type f | head -1)" && \
    ln -sf "$PWSH_BIN" /usr/bin/pwsh && \
    (pwsh --version || echo "AVISO: pwsh no inició; el reporte CSV/Excel quedaría degradado")

# --- App (desde el builder) ---
COPY --from=builder /app /app

# --- Scripts de entrada y menú ---
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-menu.sh /app/

# Normalizar a LF con sed (sin dos2unix) + permisos + carpetas de salida
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh /app/*.sh 2>/dev/null || true; \
    chmod +x /usr/local/bin/docker-entrypoint.sh /app/*.sh gradlew && \
    mkdir -p logs target/reports target/site

# Variables de entorno
ENV DISPLAY=:99 \
    QT_QPA_PLATFORM="offscreen" \
    JAVA_OPTS="-Xmx2048m -Xms512m" \
    CHROME_BIN="/usr/bin/google-chrome" \
    CHROME_DBUS_STUB_ONLY=1 \
    CHROME_HEADLESS=1 \
    DBUS_SYSTEM_BUS_ADDRESS="unix:path=/run/dbus/system_bus_socket"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
