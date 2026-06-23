package com.sara.automation.tasks;

import com.sara.automation.ui.AgentPage;
import com.sara.automation.ui.CasoCreatePage;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Performable;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.actions.Open;
import net.serenitybdd.screenplay.waits.WaitUntil;
import net.thucydides.core.annotations.Step;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.ui.WebDriverWait;
import net.serenitybdd.screenplay.abilities.BrowseTheWeb;
import java.time.Duration;
import java.io.PrintWriter;
import java.io.FileWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import static net.serenitybdd.screenplay.Tasks.instrumented;
import static net.serenitybdd.screenplay.matchers.WebElementStateMatchers.isVisible;

public class GoToAgentPage implements Task {

    /**
     * Si es true, además de navegar y esperar la carga, espera a que el botón
     * "Caso Express" sea visible (necesario para el flujo de creación de casos).
     * Para el re-login como proveedor debe ser false: ese módulo NO tiene "Caso Express".
     */
    private final boolean esperarCasoExpress;

    public GoToAgentPage() {
        this(true);
    }

    public GoToAgentPage(boolean esperarCasoExpress) {
        this.esperarCasoExpress = esperarCasoExpress;
    }

    public static Performable now() {
        return instrumented(GoToAgentPage.class);
    }

    /** Navega a /agent y espera la carga, SIN exigir el botón "Caso Express". */
    public static Performable sinEsperarCasoExpress() {
        return instrumented(GoToAgentPage.class, false);
    }

    @Override
    @Step("Navega a la pagina de agent")
    public <T extends Actor> void performAs(T actor) {
        actor.attemptsTo(Open.url(AgentPage.URL));
        
        // Obtener el WebDriver desde la habilidad BrowseTheWeb
        WebDriver driver = BrowseTheWeb.as(actor).getDriver();
        JavascriptExecutor jsExecutor = (JavascriptExecutor) driver;
        
        // Primero: Esperar por Document.readyState === 'complete' (página cargada)
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(60));
        try {
            wait.until(webDriver -> 
                "complete".equals(jsExecutor.executeScript("return document.readyState"))
            );
            System.out.println("✓ Document.readyState === complete");
        } catch (Exception e) {
            System.out.println("⚠ Timeout esperando readyState, continuando...");
        }
        
        // Segundo: Esperar por que document.body tenga contenido (HTML renderizado)
        try {
            wait.until(webDriver -> {
                Object bodyLength = jsExecutor.executeScript("return document.body.innerHTML.length");
                return bodyLength != null && !bodyLength.equals(0) && !bodyLength.equals("0");
            });
            System.out.println("✓ Document.body tiene contenido");
        } catch (Exception e) {
            System.out.println("⚠ Timeout esperando body content, continuando...");
        }
        
        // Tercero: Esperar por que el menú específico esté presente (div con role menuitem o similar)
        try {
            wait.until(webDriver -> {
                Object menuPresent = jsExecutor.executeScript(
                    "return document.body.innerHTML.includes('Caso Express') || " +
                    "document.body.innerHTML.includes('caso-express') || " +
                    "!!document.querySelector('[role=\"menuitem\"]') || " +
                    "!!document.querySelector('.menu-item') || " +
                    "!!document.querySelector('[id*=\"menu\"]')"
                );
                return Boolean.TRUE.equals(menuPresent);
            });
            System.out.println("✓ Menú encontrado en HTML");
        } catch (Exception e) {
            System.out.println("⚠ Timeout esperando menú");
        }
        
        // Espera adicional de 3s para realmente asegurar que todo está listo
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // Para módulos sin "Caso Express" (p. ej. el módulo de proveedor tras re-login),
        // terminamos aquí: solo se requería navegar y esperar la carga.
        if (!esperarCasoExpress) {
            System.out.println("✓ Navegación a /agent completada (sin esperar 'Caso Express')");
            return;
        }

        // DEBUG: Capturar screenshot y HTML antes de buscar
        try {
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss_SSS"));
            String filename = "/app/target/agent_page_debug_" + timestamp + ".txt";
            
            // Capturar HTML para debug
            String bodyHtml = (String) jsExecutor.executeScript("return document.body.innerHTML");
            String pageTitle = (String) jsExecutor.executeScript("return document.title");
            String pageUrl = (String) jsExecutor.executeScript("return window.location.href");
            
            // Capturar errores de consola si los hay
            Object consoleErrors = jsExecutor.executeScript(
                "return window.__consoleLogs ? window.__consoleLogs.join('\\n') : 'No errors captured'"
            );
            
            try (PrintWriter writer = new PrintWriter(new FileWriter(filename))) {
                writer.println("=== DEBUG AGENT PAGE ===");
                writer.println("Timestamp: " + timestamp);
                writer.println("Title: " + pageTitle);
                writer.println("URL: " + pageUrl);
                writer.println("Body HTML Length: " + (bodyHtml != null ? bodyHtml.length() : 0));
                writer.println("\n=== CONSOLE ERRORS ===");
                writer.println(consoleErrors);
                writer.println("\n=== BUSCANDO ELEMENTO ===");
                writer.println("XPath: //button[contains(normalize-space(.), 'Caso Express')] | //a[contains(normalize-space(.), 'Caso Express')]");
                writer.println("Flexible: //button[contains(., 'Caso Express')] | //a[contains(., 'Caso Express')]");
                writer.println("\n=== BODY HTML (primeros 5000 caracteres) ===");
                writer.println(bodyHtml != null ? bodyHtml.substring(0, Math.min(5000, bodyHtml.length())) : "EMPTY");
            }
            System.out.println("DEBUG: HTML capturado en " + filename);
        } catch (Exception e) {
            System.out.println("ERROR capturando debug: " + e.getMessage());
        }
        
        // Intentar buscar el elemento con timeout más largo
        try {
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.Caso_Express, isVisible()).forNoMoreThan(30).seconds());
        } catch (AssertionError e) {
            // Si falla, intentar con fallback
            System.out.println("FALLBACK: Intentando con localizadores alternativos...");
            try {
                actor.attemptsTo(WaitUntil.the(CasoCreatePage.Caso_Express_FALLBACK, isVisible()).forNoMoreThan(20).seconds());
            } catch (AssertionError e2) {
                try {
                    actor.attemptsTo(WaitUntil.the(CasoCreatePage.Caso_Express_FALLBACK2, isVisible()).forNoMoreThan(20).seconds());
                } catch (AssertionError e3) {
                    // Si todo falla, lanzar el error original con más contexto
                    throw new AssertionError("No se encontró 'Caso Express' después de múltiples intentos. Revisar target/agent_page_debug_*.txt en el volumen montado", e);
                }
            }
        }
    }
}
