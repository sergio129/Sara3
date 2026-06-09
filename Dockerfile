# ============================================================
# SARA3 - DOCKER IMAGE COMPACTA PARA TESTS HEADLESS
# ============================================================

# STAGE 1: JDK source (solo para copiar el JDK)
FROM eclipse-temurin:11-jdk-jammy AS jdk-source

# STAGE 2: Builder (solo necesita JDK para Gradle, no Chrome)
FROM eclipse-temurin:11-jdk-jammy AS builder
WORKDIR /app
COPY . .
RUN chmod +x gradlew run-tests-linux.sh && \
    ./gradlew --version && ./gradlew dependencies --write-locks 2>&1 || true

# ============================================================
# STAGE 3: Runtime - selenium ya trae Chrome + Xvfb + X11 + dbus
FROM selenium/standalone-chrome:latest

USER root
WORKDIR /app

# Instalar PowerShell Core (pwsh) para generar reportes Excel/CSV/HTML (mismo .ps1 que Windows)
# Método tarball: independiente de la versión de Ubuntu base
ARG PWSH_VERSION=7.4.6
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates libicu-dev && \
    curl -fsSL -o /tmp/pwsh.tar.gz \
      "https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-linux-x64.tar.gz" && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/pwsh.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    rm -f /tmp/pwsh.tar.gz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copiar JDK 11 desde eclipse-temurin (sin apt-get)
COPY --from=jdk-source /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Copiar app desde builder
COPY --from=builder /app /app

# Copiar scripts de entrada y menú
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-menu.sh /app/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /app/docker-menu.sh && \
    chmod +x gradlew run-tests-linux.sh batch_test_8p.sh && \
    mkdir -p logs target/site/serenity

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