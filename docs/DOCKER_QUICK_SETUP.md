# 🐳 GUÍA RÁPIDA: Ejecutar Sara3 con Docker

Esta guía te permite ejecutar toda la automatización **Sara3** dentro de Docker en cualquier computadora que tenga Docker instalado. ¡Sin necesidad de instalar nada más!

---

## 📋 REQUISITOS PREVIOS

Tienes que tener instalado en tu PC:

1. **Docker Desktop** 
   - Descargar: https://www.docker.com/products/docker-desktop
   - Después de instalar, abre Docker Desktop y espera a que esté corriendo

2. **Git** (para clonar el repositorio)
   - Descargar: https://git-scm.com/download/win

3. **Terminal/PowerShell o Comando**
   - Windows: PowerShell o Cmd
   - Mac/Linux: Terminal

---

## 🚀 PASO 1: Descargar el Proyecto

Abre una terminal y ejecuta:

```bash
# Navega a donde quieras guardar el proyecto
cd C:\Mis_Proyectos

# Clona el repositorio
git clone https://github.com/sergio129/Sara3.git

# Entra en la carpeta
cd Sara3

# Cambia a la rama docker
git checkout docker
```

---

## 🏗️ PASO 2: Construir la Imagen Docker

Desde la terminal, **dentro de la carpeta Sara3**, ejecuta:

```bash
docker build -t sara3:latest .
```

**¿Qué hace este comando?**
- Construye una imagen Docker con nombre `sara3` y etiqueta `latest`
- Instala Java, Chrome, dependencias, todo automáticamente
- Toma **2-3 minutos** la primera vez

**¿Cómo sabes que terminó correctamente?**
- Debería ver al final: `Successfully tagged sara3:latest`

---

## ▶️ PASO 3: Ejecutar el Contenedor

Ejecuta este comando:

```bash
docker run --rm -it -v E:\Proyectos\Sara3:/app sara3:latest
```

**⚠️ IMPORTANTE: Cambia la ruta**
- Reemplaza `C:\Mis_Proyectos\Sara3` con la ruta REAL donde guardaste el proyecto
- Debe ser la ruta COMPLETA, no relativa

**¿Qué hace?**
- Inicia un contenedor con la imagen que acabas de crear
- La bandera `-v` monta tu carpeta local para ver reportes en tiempo real
- Entra en modo interactivo con menú

---

## 📊 PASO 4: Seleccionar Opción del Menú

Cuando ejecutes el comando anterior, verás esto:

```
╔════════════════════════════════════════════════════════════╗
║          MENÚ DE EJECUCIÓN - SARA3 AUTOMATION              ║
╚════════════════════════════════════════════════════════════╝

1) Ejecutar tests con cantidad PERSONALIZADA de runners (1-50)
2) Ejecutar tests con 2 runners (paralelo)
3) Ejecutar tests con 4 runners (paralelo)
4) Ejecutar tests con 8 runners (paralelo)
5) Ejecutar tests con 12 runners (paralelo)
6) Ejecutar tests con 50 runners (TODOS - máximo)
7) Ejecutar un runner INDIVIDUAL (1-50)
8) Ver ubicación de reportes
9) Ver configuración actual
10) Limpiar reportes anteriores
11) Salir

Selecciona una opción (1-11):
```

### **Opciones Disponibles:**

| Opción | Qué Hace | Tiempo | Cuándo Usar |
|--------|----------|--------|-----------|
| **1** | Tests con runners personalizados | Variable | Quiero 5, 10, 15 runners específicos |
| **2** | 2 runners en paralelo | ~10-15 min | Test rápido (reproducir problema) |
| **3** | 4 runners en paralelo | ~8-12 min | Test rápido pero más completo |
| **4** | 8 runners en paralelo | ~6-10 min | Test equilibrado |
| **5** | 12 runners en paralelo | ~5-8 min | Test rápido en paralelo |
| **6** | 50 runners (TODO) | ~3-5 min | Ejecución MÁXIMA completa |
| **7** | Un runner individual | ~3-5 min | Debuguear 1 solo test |
| **8** | Ver dónde están reportes | Inmediato | Saber dónde buscar resultados |
| **9** | Ver configuración actual | Inmediato | Verificar parámetros |
| **10** | Limpiar reportes viejos | ~1 min | Borrar resultados anteriores |
| **11** | Salir del contenedor | Inmediato | Terminar ejecución |

---

## ✅ EJEMPLOS PASO A PASO

### **Ejemplo 1: Ejecutar Rápidamente (2 runners)**

```bash
# 1. Construir imagen (solo primera vez)
docker build -t sara3:latest .

# 2. Ejecutar contenedor
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest

# 3. En el menú, escribe: 2
# 4. Presiona Enter
# 5. Los tests se ejecutan automáticamente
# 6. Espera 10-15 minutos
# 7. Cuando terminen, verás el reporte disponible
# 8. Escribe: 11 para salir
```

### **Ejemplo 2: Ejecutar Todos los Tests (50 runners)**

```bash
# 1. Construir imagen (solo primera vez)
docker build -t sara3:latest .

# 2. Ejecutar contenedor
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest

# 3. En el menú, escribe: 6
# 4. Presiona Enter
# 5. Se ejecutan todos los 50 runners en paralelo
# 6. Espera 3-5 minutos
# 7. Cuando terminen, los reportes estarán listos
# 8. Escribe: 11 para salir
```

### **Ejemplo 3: Debuguear Un Test Individual**

```bash
# 1. Ejecutar contenedor
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest

# 2. En el menú, escribe: 7
# 3. Luego escribe el número del runner (ej: 1)
# 4. Se ejecuta solo ese runner
# 5. Espera 3-5 minutos
# 6. Revisa logs detallados para debuguear
# 7. Escribe: 11 para salir
```

---

## 📈 PASO 5: Ver los Reportes

### **Opción A: Desde el Menú del Contenedor**

```bash
# Selecciona opción: 8
# Te mostrará la ruta exacta donde están los reportes
```

### **Opción B: Directamente en tu PC**

Los reportes se guardan en:

```
C:\Mis_Proyectos\Sara3\target\site\serenity\
```

Abre con navegador:
```
C:\Mis_Proyectos\Sara3\target\site\serenity\index.html
```

### **¿Qué reportes hay?**

- `index.html` → Reporte visual de todos los tests
- `requirements.html` → Tests organizados por requisito
- `statistics.html` → Gráficas y estadísticas
- Carpetas con screenshots de cada paso

---

## 🔄 VOLVER A EJECUTAR TESTS

**Importante:** El contenedor se borra automaticamente después de salir (`--rm`).

Para ejecutar nuevamente:

```bash
# Mismo comando de siempre
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest
```

Si cambiaste el código, reconstruye la imagen primero:

```bash
docker build -t sara3:latest .
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest
```

---

## 🛠️ SOLUCIÓN DE PROBLEMAS

### **Problema: "docker: command not found"**
- **Causa:** Docker no está instalado o no está en el PATH
- **Solución:** Instala Docker Desktop nuevamente

### **Problema: "Cannot connect to the Docker daemon"**
- **Causa:** Docker no está corriendo
- **Solución:** Abre Docker Desktop

### **Problema: "Permission denied"**
- **Causa:** Permisos de la carpeta
- **Solución:** Ejecuta PowerShell/Cmd como Administrador

### **Problema: Los tests fallan en Docker pero funcionan en Windows**
- **Causa:** Diferencia en navegador/lenguaje/configuración
- **Solución:** Verifica que los localizadores soporten múltiples idiomas

### **Problema: El contenedor se sale sin ejecutar tests**
- **Causa:** Error en la construcción o en serenity.properties
- **Solución:** Revisa los logs de compilación

---

## 📝 COMANDOS RÁPIDOS (REFERENCIA)

### **Opción ULTRA SENCILLA - Script Batch**

En lugar de escribir comandos, simplemente:

```bash
# Doble clic en: run-docker.bat
# ¡Listo! El contenedor se inicia automáticamente
```

El archivo `run-docker.bat` ya está incluido en la raíz del proyecto.

### **Opción Sencilla - Docker Compose**

Desde la carpeta del proyecto:

```bash
docker-compose up
```

Eso es TODO. Ya está configurado en `docker-compose.yml`.

### **Comandos Avanzados**

Si prefieres línea de comandos:

```bash
# Construir imagen
docker build -t sara3:latest .

# Ejecutar con menú (interactivo) - Versión LARGA
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest

# Ejecutar tests con 2 runners directamente (sin menú)
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest bash -c "cd /app && ./gradlew clean test -Pmax=2"

# Ejecutar todos los tests con 50 runners (sin menú)
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest bash -c "cd /app && ./gradlew clean test -Pmax=50"

# Ver logs en tiempo real (ejecutar en otra terminal mientras corren tests)
docker ps
docker logs -f <CONTAINER_ID>
```

---

## 🎯 FLUJO COMPLETO: PASO A PASO VISUAL

```
┌─────────────────────────────────────────┐
│ 1. Abre Terminal/PowerShell             │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│ 2. git clone y cd Sara3                 │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│ 3. docker build -t sara3:latest .       │
│    (espera 2-3 minutos)                 │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│ 4. docker run ... sara3:latest          │
│    (inicia contenedor)                  │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│ 5. Ves el menú con 11 opciones          │
│    Selecciona opción (2, 6, 7, etc)     │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│ 6. Tests se ejecutan en paralelo        │
│    (3-15 minutos según runners)         │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│ 7. Reportes en: target/site/serenity/   │
│    Abre index.html en navegador         │
└────────────────┬────────────────────────┘
                 │
┌─────────────────────────────────────────┐
│ 8. Presiona 11 para salir del menú      │
│    Contenedor se detiene               │
└─────────────────────────────────────────┘
```

---

## 📚 ARCHIVOS IMPORTANTES DENTRO DEL CONTENEDOR

Cuando estés dentro del contenedor (en el menú), estos archivos controlan todo:

```
/app/
├── serenity.properties          ← Configuración de Chrome, timeouts
├── gradle.properties            ← Parámetros de Gradle (max de runners)
├── docker-menu.sh              ← Este menú que ves
├── docker-entrypoint.sh        ← Startup del contenedor
├── Dockerfile                  ← Configuración de la imagen
├── build.gradle                ← Definición de tests
└── src/test/java/              ← Código de tests
```

---

## ✨ CARACTERÍSTICAS DE ESTA CONFIGURACIÓN

✅ **Automatizado:** El contenedor hace todo (Chrome, Java, Gradle)
✅ **Reproducible:** Funciona igual en cualquier PC con Docker
✅ **Rápido:** 50 tests paralelos en 3-5 minutos
✅ **Confiable:** Sin efectos secundarios en tu sistema
✅ **Modular:** Elige cantidad de runners que quieras
✅ **Reportes:** Reportes HTML bonitos con screenshots

---

## 🎓 SIGUIENTE NIVEL (Avanzado)

Si ya dominas lo básico:

### **Ejecutar sin Menú (Script Directo)**
```bash
docker run --rm -it -v C:\Mis_Proyectos\Sara3:/app sara3:latest \
  bash -c "cd /app && ./gradlew clean test -Pmax=50"
```

### **Ejecutar en Background (Sin Terminal Interactiva)**
```bash
docker run -d -v C:\Mis_Proyectos\Sara3:/app sara3:latest \
  bash -c "cd /app && ./gradlew clean test -Pmax=50"
```

### **Ver Logs en Tiempo Real**
```bash
docker logs -f <CONTAINER_ID>
```

### **Usar con CI/CD (Jenkins, GitLab, etc)**
```yaml
docker build -t sara3:latest .
docker run --rm -v C:\Mis_Proyectos\Sara3:/app sara3:latest \
  bash -c "cd /app && ./gradlew clean test -Pmax=50"
```

---

## ✅ CHECKLIST: ¿ESTOY LISTO?

- [ ] Docker Desktop instalado y corriendo
- [ ] Git instalado
- [ ] Repositorio clonado
- [ ] Estoy en la rama `docker`
- [ ] Imagen construida con `docker build`
- [ ] Puedo ver el menú interactivo

**Si todo está ✅, ¡eres un PRO de Docker! 🚀**

---

## 📞 SOPORTE

Si algo no funciona:

1. Revisa los logs: `docker logs <CONTAINER_ID>`
2. Verifica que Docker esté corriendo
3. Intenta reconstruir la imagen: `docker build -t sara3:latest .`
4. Lee los reportes en `target/site/serenity/index.html`

---

**Creado:** 2026-05-20  
**Última actualización:** 2026-05-20  
**Para:** Sara3 Automation Framework

