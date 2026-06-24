package com.sara.automation.tasks;

import com.sara.automation.interactions.ClickEstadoProgramado;
import com.sara.automation.interactions.ClickEstadoAceptadoDesplazamiento;
import com.sara.automation.interactions.ClickEstadoConcluido;
import com.sara.automation.interactions.ClickEstadoFinalizado;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Performable;
import net.serenitybdd.screenplay.Task;
import net.thucydides.core.annotations.Step;
import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.TimeoutException;
import java.util.List;

import static net.serenitybdd.screenplay.Tasks.instrumented;

/**
 * Task para transicionar el caso a través de estados con lógica adaptativa:
 * 
 * RUTA 1 (Si existe "Aceptado y en desplazamiento"):
 * Programado -> Aceptado y Desplazamiento -> Concluido -> Finalizado
 * 
 * RUTA 2 (Si existe solo "Aceptado"):
 * Programado -> Aceptado -> Finalizado
 * 
 * La Task detecta qué opción está disponible después de cada estado
 * y ejecuta el flujo correspondiente.
 */
public class TransicionarEstadosCaso implements Task {

    /**
     * Si es true, la secuencia se DETIENE tras guardar 'Concluido' (no ejecuta
     * 'Finalizado'). Se usa en el flujo de captura de expediente + cierre de sesión.
     */
    private final boolean detenerEnConcluido;

    public TransicionarEstadosCaso() {
        this(false);
    }

    public TransicionarEstadosCaso(boolean detenerEnConcluido) {
        this.detenerEnConcluido = detenerEnConcluido;
    }

    public static Performable completarSecuencia() {
        return instrumented(TransicionarEstadosCaso.class);
    }

    /** Transiciona hasta 'Concluido' y se detiene (no ejecuta 'Finalizado'). */
    public static Performable hastaConcluido() {
        return instrumented(TransicionarEstadosCaso.class, true);
    }

    @Override
    @Step("Transicionar caso adaptativo: detecta ruta y ejecuta secuencia correcta")
    public <T extends Actor> void performAs(T actor) {
                        
        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        
        // 1. PROGRAMADO
        System.out.println("\n  [TransicionarEstadosCaso] ==================== INICIO DE TRANSICIONES ====================");
        System.out.println("  [TransicionarEstadosCaso] PASO 1: Transición a PROGRAMADO");
        actor.attemptsTo(ClickEstadoProgramado.clickEstadoProgramado());
                System.out.println("  [TransicionarEstadosCaso] ✓ Estado 'Programado' completado");
        esperarRecargaPaginaConValidacion(driver, "Aceptado", "Aceptado y en desplazamiento");
        
        // VALIDACIÓN POST-TRANSICIÓN 1: Confirmar que el siguiente estado está disponible
        System.out.println("  [TransicionarEstadosCaso] 🔍 VALIDACIÓN POST-TRANSICIÓN: Confirmando que Aceptado está disponible...");
        String proximoEstado = validarQueProximoEstadoEstaDisponible(driver, "Aceptado");
        System.out.println("  [TransicionarEstadosCaso] ✓ VALIDACIÓN OK: '" + proximoEstado + "' está disponible - Programado se guardó correctamente");
        
        // RUTA 1: Aceptado y en desplazamiento disponible
        if (proximoEstado.equalsIgnoreCase("Aceptado y en desplazamiento") || 
            proximoEstado.equalsIgnoreCase("Aceptado")) {
            
            System.out.println("  [TransicionarEstadosCaso] PASO 2: Transición a " + proximoEstado);
            actor.attemptsTo(ClickEstadoAceptadoDesplazamiento.clickEstadoAceptadoDesplazamiento());
                        System.out.println("  [TransicionarEstadosCaso] ✓ Estado '" + proximoEstado + "' completado");
            esperarRecargaPaginaConValidacion(driver, "Concluido", "Finalizado");
            
            // Después de Aceptado, decidir por el estado realmente disponible en UI.
            // Si existe Concluido, SIEMPRE se debe transicionar por Concluido antes de Finalizado.
            String siguienteDespuesDeAceptado = detectarSiguienteEstadoDespuesDeAceptado(driver);
            if ("Concluido".equals(siguienteDespuesDeAceptado)) {
                System.out.println("  [TransicionarEstadosCaso] ✓ Detectado siguiente estado real: Concluido");
                System.out.println("  [TransicionarEstadosCaso] PASO 3: Transición a CONCLUIDO");
                actor.attemptsTo(ClickEstadoConcluido.clickEstadoConcluido());
                                System.out.println("  [TransicionarEstadosCaso] ✓ Estado 'Concluido' completado");

                // CORTE EN CONCLUIDO: para el flujo de captura de expediente + logout,
                // la secuencia termina aquí (no se ejecuta 'Finalizado').
                if (detenerEnConcluido) {
                    System.out.println("  [TransicionarEstadosCaso] ⏹ Detención solicitada en CONCLUIDO. No se ejecuta 'Finalizado'.");
                    System.out.println("  [TransicionarEstadosCaso] ==================== ✓ TRANSICIONES HASTA CONCLUIDO COMPLETADAS ====================\n");
                    return;
                }

                esperarRecargaPaginaConValidacion(driver, "Finalizado");

                // Después de Concluido, Finalizado debe quedar disponible.
                System.out.println("  [TransicionarEstadosCaso] 🔍 VALIDACIÓN POST-CONCLUIDO: Confirmando que Finalizado está disponible...");
                validarQueProximoEstadoEstaDisponible(driver, "Finalizado");
                System.out.println("  [TransicionarEstadosCaso] ✓ VALIDACIÓN OK: 'Finalizado' está disponible - Concluido se guardó correctamente");
            } else {
                // Ruta corta: después de Aceptado quedó Finalizado directamente.
                if (detenerEnConcluido) {
                    throw new RuntimeException(
                        "Se solicitó detener en 'Concluido', pero tras 'Aceptado' el único estado disponible es 'Finalizado' "
                      + "(no hay 'Concluido' en esta ruta). Revisa el caso/servicio del escenario.");
                }
                System.out.println("  [TransicionarEstadosCaso] ✓ Detectado siguiente estado real: Finalizado");
                System.out.println("  [TransicionarEstadosCaso] 🔍 VALIDACIÓN POST-ACEPTADO: Confirmando que Finalizado está disponible...");
                validarQueProximoEstadoEstaDisponible(driver, "Finalizado");
                System.out.println("  [TransicionarEstadosCaso] ✓ VALIDACIÓN OK: 'Finalizado' está disponible - Aceptado se guardó correctamente");
            }
        }
        
        // VALIDACIÓN PRE-FINALIZADO: Confirmar que Finalizado está disponible antes de hacer click
        System.out.println("  [TransicionarEstadosCaso] 🔍 VALIDACIÓN PRE-FINALIZADO: Confirmando que Finalizado está disponible...");
        validarQueProximoEstadoEstaDisponible(driver, "Finalizado");
        System.out.println("  [TransicionarEstadosCaso] ✓ PRE-VALIDACIÓN OK: 'Finalizado' está disponible");
        
        // 4. FINALIZADO (en ambas rutas)
        System.out.println("  [TransicionarEstadosCaso] PASO FINAL: Transición a FINALIZADO");
        actor.attemptsTo(ClickEstadoFinalizado.clickEstadoFinalizado());
                System.out.println("  [TransicionarEstadosCaso] Estado 'Finalizado' completado");
        
        // ESPERA CRÍTICA FINAL: Después de Finalizado, la página se recarga completamente
        esperarRecargaPaginaFinal();
        System.out.println("  [TransicionarEstadosCaso] ✓ Flujo transaccional FINALIZADO - página completamente recargada");
        
        System.out.println("  [TransicionarEstadosCaso] ==================== ✓✓✓ TODAS LAS TRANSICIONES COMPLETADAS ====================\n");
    }
    
    /**
     * VALIDACIÓN POST-TRANSICIÓN CRÍTICA:
     * Verifica que el estado esperado esté DISPONIBLE después de un cambio de estado.
     * Si no está disponible, la transición anterior FALLÓ.
     * 
     * @param driver WebDriver
     * @param estadoEsperado Nombre del estado que debe estar disponible (ej: "Aceptado", "Finalizado")
     * @return El nombre exacto del estado encontrado
     * @throws RuntimeException si el estado no está disponible después de 20 segundos
     */
    private String validarQueProximoEstadoEstaDisponible(WebDriver driver, String estadoEsperado) {
        System.out.println("  [TransicionarEstadosCaso] 🔍 Validando disponibilidad de estado: '" + estadoEsperado + "'...");
        try {
            driver.switchTo().defaultContent();
            org.openqa.selenium.support.ui.WebDriverWait wait = 
                new org.openqa.selenium.support.ui.WebDriverWait(driver, java.time.Duration.ofSeconds(20));

            // Intentar 1: Buscar exactamente el estado esperado
            if (estadoEsperado.equalsIgnoreCase("Aceptado")) {
                // Buscar "Aceptado y en desplazamiento" O "Aceptado" simple
                try {
                    wait.until(org.openqa.selenium.support.ui.ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));

                    try {
                        wait.until(org.openqa.selenium.support.ui.ExpectedConditions.presenceOfElementLocated(
                            By.xpath("//button[contains(normalize-space(.), 'Aceptado') and contains(normalize-space(.), 'desplazamiento')]") ));
                        
                        java.util.List<WebElement> botonesAceptadoDesplazamiento = driver.findElements(
                            By.xpath("//button[contains(normalize-space(.), 'Aceptado') and contains(normalize-space(.), 'desplazamiento')]") );
                        
                        for (WebElement boton : botonesAceptadoDesplazamiento) {
                            if (boton.isDisplayed()) {
                                String textoEncontrado = boton.getText().trim();
                                System.out.println("  [TransicionarEstadosCaso]   ✓ VALIDACIÓN OK: '" + textoEncontrado + "' está disponible");
                                driver.switchTo().defaultContent();
                                return textoEncontrado;
                            }
                        }
                    } catch (Exception ignore) {
                        // No se encontró 'Aceptado y en desplazamiento', continuamos con el botón simple.
                    }
                    try {
                        wait.until(org.openqa.selenium.support.ui.ExpectedConditions.presenceOfElementLocated(
                            By.xpath("//button[normalize-space(text())='Aceptado']")));
                        
                        java.util.List<WebElement> botonesAceptado = driver.findElements(
                            By.xpath("//button[normalize-space(text())='Aceptado']"));
                        
                        for (WebElement boton : botonesAceptado) {
                            if (boton.isDisplayed()) {
                                String textoEncontrado = boton.getText().trim();
                                System.out.println("  [TransicionarEstadosCaso]   ✓ VALIDACIÓN OK: '" + textoEncontrado + "' está disponible");
                                driver.switchTo().defaultContent();
                                return textoEncontrado;
                            }
                        }
                        throw new RuntimeException("Botones 'Aceptado' encontrados pero ninguno visible");
                    } catch (TimeoutException e1) {
                        throw new RuntimeException("VALIDACIÓN FALLÓ: Después de 'Programado', el estado '" + estadoEsperado + "' NO está disponible. La transición NO se guardó correctamente.", e1);
                    }
                } catch (Exception e) {
                    throw new RuntimeException("VALIDACIÓN FALLÓ: No se pudo acceder al iframe para validar '" + estadoEsperado + "'", e);
                }
            } else {
                // Buscar otros estados (Concluido, Finalizado, etc)
                try {
                    wait.until(org.openqa.selenium.support.ui.ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));

                    try {
                        wait.until(org.openqa.selenium.support.ui.ExpectedConditions.presenceOfElementLocated(
                            By.xpath("//button[contains(normalize-space(.), '" + estadoEsperado + "')]")));
                        
                        java.util.List<WebElement> botones = driver.findElements(
                            By.xpath("//button[contains(normalize-space(.), '" + estadoEsperado + "')]"));
                        
                        for (WebElement boton : botones) {
                            if (boton.isDisplayed()) {
                                String textoEncontrado = boton.getText().trim();
                                System.out.println("  [TransicionarEstadosCaso]   ✓ VALIDACIÓN OK: '" + textoEncontrado + "' está disponible");
                                driver.switchTo().defaultContent();
                                return textoEncontrado;
                            }
                        }
                        throw new RuntimeException("Botones '" + estadoEsperado + "' encontrados pero ninguno visible");
                    } catch (TimeoutException e1) {
                        throw new RuntimeException("VALIDACIÓN FALLÓ: El estado '" + estadoEsperado + "' NO está disponible. La transición anterior NO se guardó correctamente.", e1);
                    }
                } catch (Exception e) {
                    if (e.getMessage() != null && e.getMessage().contains("VALIDACIÓN FALLÓ")) throw e;
                    throw new RuntimeException("VALIDACIÓN FALLÓ: No se pudo acceder al iframe para validar '" + estadoEsperado + "'", e);
                }
            }
            
        } catch (TimeoutException e) {
            throw new RuntimeException("VALIDACIÓN FALLÓ: Timeout esperando disponibilidad de '" + estadoEsperado + "'. Transición anterior NO se guardó.", e);
        }
    }
    
    /**
     * DETECTA próximo estado disponible (método original - ahora usado solo para información)
     */
    private String detectarProximoEstado(WebDriver driver) {
        System.out.println("  [TransicionarEstadosCaso] Detectando próximo estado disponible...");
        try {
            driver.switchTo().defaultContent();
            org.openqa.selenium.support.ui.WebDriverWait wait = 
                new org.openqa.selenium.support.ui.WebDriverWait(driver, java.time.Duration.ofSeconds(20));

            System.out.println("  [TransicionarEstadosCaso]   Esperando a que iframe OneScript esté disponible...");
            wait.until(org.openqa.selenium.support.ui.ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));
            System.out.println("  [TransicionarEstadosCaso]   ✓ Iframe OneScript listo");
            
            // INTENTO 1: Esperar ACTIVAMENTE por botón "Aceptado y en desplazamiento"
            System.out.println("  [TransicionarEstadosCaso]   Esperando activamente por 'Aceptado y en desplazamiento'...");
            try {
                wait.until(org.openqa.selenium.support.ui.ExpectedConditions.presenceOfElementLocated(
                    By.xpath("//button[contains(text(), 'Aceptado') and contains(text(), 'desplazamiento')]")));
                
                List<WebElement> botonesCompletos = driver.findElements(
                    By.xpath("//button[contains(text(), 'Aceptado') and contains(text(), 'desplazamiento')]"));
                
                if (botonesCompletos.size() > 0) {
                    for (WebElement boton : botonesCompletos) {
                        String texto = boton.getText().trim();
                        if (boton.isDisplayed()) {
                            System.out.println("  [TransicionarEstadosCaso]   ✓ DETECTADO: '" + texto + "' - listo para click");
                            driver.switchTo().defaultContent();
                            return "Aceptado y en desplazamiento";
                        }
                    }
                }
            } catch (org.openqa.selenium.TimeoutException e1) {
                System.out.println("  [TransicionarEstadosCaso]   No detectado 'Aceptado y en desplazamiento', probando 'Aceptado' simple...");
            }
            
            // INTENTO 2: Esperar ACTIVAMENTE por botón simple "Aceptado"
            try {
                wait.until(org.openqa.selenium.support.ui.ExpectedConditions.presenceOfElementLocated(
                    By.xpath("//button[text()='Aceptado' or normalize-space(text())='Aceptado']")));
                
                List<WebElement> botonesSimples = driver.findElements(
                    By.xpath("//button[text()='Aceptado' or normalize-space(text())='Aceptado']"));
                
                if (botonesSimples.size() > 0) {
                    for (WebElement boton : botonesSimples) {
                        if (boton.isDisplayed()) {
                            String texto = boton.getText().trim();
                            System.out.println("  [TransicionarEstadosCaso]   ✓ DETECTADO: '" + texto + "' - listo para click");
                            driver.switchTo().defaultContent();
                            return "Aceptado";
                        }
                    }
                }
            } catch (org.openqa.selenium.TimeoutException e2) {
                System.out.println("  [TransicionarEstadosCaso]   No detectado botón 'Aceptado' en 8 segundos");
            }
            
            System.out.println("  [TransicionarEstadosCaso]   ✗ No se encontró ningún botón de estado disponible");
            driver.switchTo().defaultContent();
            return null;
            
        } catch (TimeoutException | NoSuchElementException e) {
            System.out.println("  [TransicionarEstadosCaso]   ✗ Error detectando estado: " + e.getMessage());
            try {
                driver.switchTo().defaultContent();
            } catch (Exception ignored) {}
            return null;
        }
    }

    /**
     * Detecta el estado disponible inmediatamente después de guardar Aceptado.
     * Prioriza Concluido (si existe), y si no, usa Finalizado.
     */
    private String detectarSiguienteEstadoDespuesDeAceptado(WebDriver driver) {
        System.out.println("  [TransicionarEstadosCaso] 🔍 Detectando siguiente estado después de Aceptado...");
        try {
            driver.switchTo().defaultContent();
            org.openqa.selenium.support.ui.WebDriverWait wait =
                new org.openqa.selenium.support.ui.WebDriverWait(driver, java.time.Duration.ofSeconds(20));
            wait.until(org.openqa.selenium.support.ui.ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));

            List<WebElement> botones = driver.findElements(By.xpath("//button"));
            boolean hayConcluido = false;
            boolean hayFinalizado = false;

            for (WebElement boton : botones) {
                try {
                    if (!boton.isDisplayed()) {
                        continue;
                    }
                    String texto = boton.getText().trim().toLowerCase();
                    if (texto.contains("concluido")) {
                        hayConcluido = true;
                    }
                    if (texto.contains("finalizado")) {
                        hayFinalizado = true;
                    }
                } catch (Exception ignored) {
                }
            }

            driver.switchTo().defaultContent();

            if (hayConcluido) {
                return "Concluido";
            }
            if (hayFinalizado) {
                return "Finalizado";
            }

            throw new RuntimeException("No se detectó 'Concluido' ni 'Finalizado' después de 'Aceptado'");
        } catch (Exception e) {
            try {
                driver.switchTo().defaultContent();
            } catch (Exception ignored) {
            }
            throw new RuntimeException("No fue posible detectar el estado siguiente luego de 'Aceptado'", e);
        }
    }
    
    /**
     * Espera dinamica usando until hasta que el iframe este disponible y aparezca
     * al menos uno de los estados esperados. Evita esperas fijas largas.
     */
    private void esperarRecargaPaginaConValidacion(WebDriver driver, String... estadosEsperados) {
        System.out.println("  [TransicionarEstadosCaso]   Esperando recarga de pagina con until...");
        long inicio = System.currentTimeMillis();
        try {
            driver.switchTo().defaultContent();
            org.openqa.selenium.support.ui.WebDriverWait wait =
                new org.openqa.selenium.support.ui.WebDriverWait(driver, java.time.Duration.ofSeconds(120));
            wait.pollingEvery(java.time.Duration.ofMillis(750));
            wait.ignoring(org.openqa.selenium.NoSuchElementException.class);
            wait.ignoring(org.openqa.selenium.StaleElementReferenceException.class);
            wait.ignoring(org.openqa.selenium.NoSuchFrameException.class);

            wait.until(d -> {
                d.switchTo().defaultContent();
                d.switchTo().frame(d.findElement(By.id("form_onescript_iframe")));

                List<WebElement> botones = d.findElements(By.xpath("//button"));
                if (botones.isEmpty()) {
                    return false;
                }

                if (estadosEsperados == null || estadosEsperados.length == 0) {
                    return true;
                }

                for (WebElement boton : botones) {
                    if (!boton.isDisplayed()) {
                        continue;
                    }
                    String texto = boton.getText();
                    if (texto == null) {
                        continue;
                    }
                    String normalizado = texto.trim().toLowerCase();
                    for (String esperado : estadosEsperados) {
                        if (esperado != null && normalizado.contains(esperado.toLowerCase())) {
                            return true;
                        }
                    }
                }
                return false;
            });

            driver.switchTo().defaultContent();
            long duracion = System.currentTimeMillis() - inicio;
            System.out.println("  [TransicionarEstadosCaso]   Pagina recargada y estado disponible en " + duracion + "ms");
        } catch (Exception e) {
            try {
                driver.switchTo().defaultContent();
            } catch (Exception ignored) {
            }
            throw new RuntimeException("No fue posible esperar el siguiente estado con until", e);
        }
    }
    
    private void esperarRecargaPaginaFinal() {
        System.out.println("  [TransicionarEstadosCaso]   ⏳ ESPERA FINAL (15s) - Validando estado Finalizado...");
        try {
            Thread.sleep(15000);
            System.out.println("  [TransicionarEstadosCaso]   ✓ Caso FINALIZADO - página completamente recargada");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
