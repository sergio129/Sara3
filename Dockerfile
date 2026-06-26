# ============================================================
# SARA3 - DOCKER IMAGE PARA TESTS HEADLESS
# ------------------------------------------------------------
# Red del servidor: alcanza Docker Hub + Maven Central, pero NO services.gradle.org
# (el gradlew falla al bajar el binario de Gradle) ni los repos apt de Ubuntu.
#
# Estrategia (todo de fuentes alcanzables, sin apt y sin services.gradle.org):
#   - selenium/standalone-chrome  : Chrome + chromedriver + Xvfb + X11 + dbus
#   - eclipse-temurin             : JDK 11
#   - gradle:8.10.2-jdk11         : binario de Gradle (desde Docker Hub, NO gradle.org)
#   - mcr.microsoft.com/powershell: pwsh (reporte CSV/Excel/HTML)
#   - dependencias del proyecto   : desde Maven Central (alcanzable)
# ============================================================

# STAGE 1: JDK 11 (para copiar al runtime)
FROM eclipse-temurin:11-jdk-jammy AS jdk-source

# STAGE 2: Distribución de Gradle (binario desde Docker Hub, sin services.gradle.org)
FROM gradle:8.10.2-jdk11 AS gradle-dist

# STAGE 3: Builder - usa el gradle del sistema (NO el wrapper) para no tocar
# services.gradle.org. Las dependencias se bajan de Maven Central (alcanzable).
FROM gradle:8.10.2-jdk11 AS builder
USER root
WORKDIR /app
ENV GRADLE_USER_HOME=/gradle-home
COPY . .
RUN sed -i 's/\r$//' gradlew *.sh 2>/dev/null || true; \
    chmod +x gradlew *.sh; \
    gradle --no-daemon compileTestJava

# STAGE 4: PowerShell (para el reporte CSV/Excel/HTML, sin apt)
FROM mcr.microsoft.com/powershell:latest AS pwsh-source

# ============================================================
# STAGE 5: Runtime - selenium trae Chrome + chromedriver + Xvfb + X11 + dbus
# ============================================================
FROM selenium/standalone-chrome:latest

USER root
WORKDIR /app

# --- JDK 11 (copiado, sin apt) ---
COPY --from=jdk-source /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk

# --- Gradle (binario copiado desde Docker Hub, sin services.gradle.org) ---
COPY --from=gradle-dist /opt/gradle-8.10.2 /opt/gradle-8.10.2
ENV PATH="/opt/gradle-8.10.2/bin:${JAVA_HOME}/bin:${PATH}"

# --- PowerShell (copiado, sin apt). Invariant para no depender de libicu ---
COPY --from=pwsh-source /opt/microsoft/powershell /opt/microsoft/powershell
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
RUN PWSH_BIN="$(find /opt/microsoft/powershell -maxdepth 2 -name pwsh -type f | head -1)" && \
    ln -sf "$PWSH_BIN" /usr/bin/pwsh && \
    (pwsh --version || echo "AVISO: pwsh no inició; el reporte CSV/Excel quedaría degradado")

# --- App + caché de Gradle (dependencias ya descargadas en build) ---
COPY --from=builder /app /app
COPY --from=builder /gradle-home /gradle-home
ENV GRADLE_USER_HOME=/gradle-home

# --- Shim: ./gradlew -> gradle del sistema (evita services.gradle.org en runtime) ---
RUN printf '#!/bin/bash\nexec gradle "$@"\n' > /app/gradlew && chmod +x /app/gradlew

# --- Scripts de entrada y menú ---
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-menu.sh /app/

# Normalizar a LF (sin dos2unix) + permisos + carpetas de salida
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh /app/*.sh 2>/dev/null || true; \
    chmod +x /usr/local/bin/docker-entrypoint.sh /app/*.sh && \
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
