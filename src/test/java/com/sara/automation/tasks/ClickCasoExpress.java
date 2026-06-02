package com.sara.automation.tasks;

import com.sara.automation.interactions.FillCasoExpressFormInOrder;
import com.sara.automation.interactions.SwitchToOneScriptIframe;
import com.sara.automation.ui.CasoCreatePage;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Performable;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.actions.Click;
import net.serenitybdd.screenplay.waits.WaitUntil;
import net.thucydides.core.annotations.Step;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;


import static net.serenitybdd.screenplay.Tasks.instrumented;
import static net.serenitybdd.screenplay.abilities.BrowseTheWeb.as;
import static net.serenitybdd.screenplay.matchers.WebElementStateMatchers.isVisible;

public class ClickCasoExpress implements Task {

    // Esta es la Task orquestadora del caso express.
    // Relación de ejecución:
    // StepDefinition -> ClickCasoExpress (Task) -> SwitchToOneScriptIframe (Interaction)
    // -> FillCasoExpressFormInOrder (Interaction que llena el formulario y guarda).

    private final String departamento;
    private final String municipio;
    private final String serviciosEspeciales;
    private final String gestor;
    private final String linea;
    private final String servicio;

    public ClickCasoExpress() {
        this.departamento = null;
        this.municipio = null;
        this.serviciosEspeciales = null;
        this.gestor = null;
        this.linea = null;
        this.servicio = null;
    }

    public ClickCasoExpress(String departamento, String municipio, String serviciosEspeciales, String gestor, String linea, String servicio) {
        this.departamento = departamento;
        this.municipio = municipio;
        this.serviciosEspeciales = serviciosEspeciales;
        this.gestor = gestor;
        this.linea = linea;
        this.servicio = servicio;
    }

    public static Performable now() {
        return instrumented(ClickCasoExpress.class);
    }

    public static Performable withManualLists(String departamento, String municipio, String serviciosEspeciales, String gestor, String linea, String servicio) {
        return instrumented(ClickCasoExpress.class, departamento, municipio, serviciosEspeciales, gestor, linea, servicio);
    }

    @Override
    @Step("Abrir Caso Express, seleccionar asistencia, entrar al iframe, habilitar y diligenciar en orden")
    public <T extends Actor> void performAs(T actor) {
                        
        // 1) Asegura que arrancamos fuera de cualquier iframe previo.
        salirDeIframe(actor);

        // 2) Abre el menú y selecciona el formulario correcto antes de entrar al iframe.
        abrirCasoExpress(actor);
                
        seleccionarFormularioAsistencia(actor);
        
        // 3) Desde aquí, el flujo se mantiene dentro del iframe OneScript.
        // Si el actor no entra al iframe, ninguno de los campos del formulario será visible para Screenplay.
        actor.attemptsTo(SwitchToOneScriptIframe.required());

        // 4) Habilita la edición del formulario ya estando dentro del iframe.
        habilitarFormulario(actor);
        
        // 5) Delega el diligenciamiento campo a campo a la interacción especializada.
        if (tieneListasManuales()) {
            actor.attemptsTo(FillCasoExpressFormInOrder.withManualLists(
                    departamento,
                    municipio,
                    serviciosEspeciales,
                    gestor,
                    linea,
                    servicio
            ));
        } else {
            actor.attemptsTo(FillCasoExpressFormInOrder.randomData());
        }
    }

    private boolean tieneListasManuales() {
        return departamento != null && municipio != null && serviciosEspeciales != null
                && gestor != null && linea != null && servicio != null;
    }

    private <T extends Actor> void salirDeIframe(T actor) {
        // Resetea el contexto del driver al documento principal.
        as(actor).getDriver().switchTo().defaultContent();
    }

    private <T extends Actor> void abrirCasoExpress(T actor) {
        try {
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.Caso_Express, isVisible()).forNoMoreThan(8).seconds());
            actor.attemptsTo(Click.on(CasoCreatePage.Caso_Express));
        } catch (Throwable e) {
            try {
                actor.attemptsTo(Click.on(CasoCreatePage.Caso_Express_FALLBACK));
            } catch (Throwable ex) {
                throw new RuntimeException("No se pudo abrir el menu 'Caso Express'", ex);
            }
        }
    }

    private <T extends Actor> void seleccionarFormularioAsistencia(T actor) {
        try {
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.Formulario_Creacion_ASISTENCIA, isVisible()).forNoMoreThan(10).seconds());
            actor.attemptsTo(Click.on(CasoCreatePage.Formulario_Creacion_ASISTENCIA));
        } catch (Throwable e) {
            throw new RuntimeException("No se pudo seleccionar 'Formulario Creacion de Casos (ASISTENCIA)'", e);
        }
    }

    private <T extends Actor> void habilitarFormulario(T actor) {
        WebDriver driver = as(actor).getDriver();

        // CRITICAL: Screenplay puede resetear el contexto del iframe entre interacciones.
        // Por eso re-cambiamos explicitamente al iframe aqui con raw WebDriver.
        System.out.println("\n=== [habilitarFormulario] Re-switching to OneScript iframe ===");
        driver.switchTo().defaultContent();
        try {
            new WebDriverWait(driver, Duration.ofSeconds(20))
                    .until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));
            System.out.println("  Switched to iframe OK");
        } catch (Exception e) {
            throw new RuntimeException("[habilitarFormulario] No se pudo cambiar al iframe form_onescript_iframe", e);
        }

        // Intento 1: CSS selector - el atributo name contiene 'habilitar_edicion_del_caso'
        System.out.println("=== Buscando boton Habilitar Formulario (CSS) ===");
        try {
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(20));
            WebElement button = wait.until(
                    ExpectedConditions.elementToBeClickable(By.cssSelector("button[name*='habilitar_edicion_del_caso']"))
            );
            System.out.println("  Boton encontrado! Texto: '" + button.getText() + "'");
            ((JavascriptExecutor) driver).executeScript("arguments[0].scrollIntoView(true);", button);
            // No esperar después de scrollIntoView - dejar que WebDriverWait del siguiente intento verifique disponibilidad
            button.click();
            System.out.println("  Clic en boton Habilitar exitoso (CSS)");
            // Esperar a que el formulario esté listo (verificar que algún campo esté disponible)
            new WebDriverWait(driver, Duration.ofSeconds(10)).until(
                ExpectedConditions.presenceOfElementLocated(By.cssSelector("[data-type='textfield'], input[type='text'], textarea"))
            );
            return;
        } catch (Exception e1) {
            System.err.println("  CSS click FALLO: " + e1.getMessage());
        }

        // Intento 2: XPath por texto visible
        System.out.println("=== Buscando boton Habilitar Formulario (XPath texto) ===");
        try {
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
            WebElement button = wait.until(
                    ExpectedConditions.elementToBeClickable(
                            By.xpath("//button[contains(normalize-space(.), 'Habilitar Formulario')]"))
            );
            System.out.println("  Boton encontrado por texto! Texto: '" + button.getText() + "'");
            ((JavascriptExecutor) driver).executeScript("arguments[0].scrollIntoView(true);", button);
            button.click();
            System.out.println("  Clic en boton Habilitar exitoso (XPath texto)");
            // Esperar a que el formulario esté listo
            new WebDriverWait(driver, Duration.ofSeconds(10)).until(
                ExpectedConditions.presenceOfElementLocated(By.cssSelector("[data-type='textfield'], input[type='text'], textarea"))
            );
            return;
        } catch (Exception e2) {
            System.err.println("  XPath texto FALLO: " + e2.getMessage());
        }

        // Intento 3: XPath por clase formio-component y ref=button
        System.out.println("=== Buscando boton Habilitar Formulario (clase formio) ===");
        try {
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
            WebElement button = wait.until(
                    ExpectedConditions.elementToBeClickable(
                            By.xpath("//div[contains(@class,'formio-component-habilitar_edicion_del_caso')]//button[@ref='button']"))
            );
            System.out.println("  Boton encontrado por clase formio! Texto: '" + button.getText() + "'");
            ((JavascriptExecutor) driver).executeScript("arguments[0].scrollIntoView(true);", button);
            button.click();
            System.out.println("  Clic en boton Habilitar exitoso (clase formio)");
            // Esperar a que el formulario esté listo
            new WebDriverWait(driver, Duration.ofSeconds(10)).until(
                ExpectedConditions.presenceOfElementLocated(By.cssSelector("[data-type='textfield'], input[type='text'], textarea"))
            );
            return;
        } catch (Exception e3) {
            System.err.println("  Clase formio FALLO: " + e3.getMessage());
        }

        // Intento 4: JavaScript click directo dentro del iframe (driver ya esta en iframe)
        System.out.println("=== Buscando boton Habilitar Formulario (JavaScript) ===");
        try {
            Object result = ((JavascriptExecutor) driver).executeScript(
                "var buttons = document.querySelectorAll('button[name*=\'habilitar_edicion_del_caso\']'); " +
                "if (buttons.length > 0) { " +
                "  buttons[0].scrollIntoView(true); " +
                "  buttons[0].click(); " +
                "  return 'clicked:' + buttons[0].textContent; " +
                "} " +
                "var all = document.querySelectorAll('button'); " +
                "var hab = Array.from(all).find(b => b.textContent.includes('Habilitar')); " +
                "if (hab) { hab.scrollIntoView(true); hab.click(); return 'clicked-by-text:' + hab.textContent; } " +
                "return 'not-found:' + all.length;"
            );
            System.out.println("  JavaScript resultado: " + result);
            if (result != null && result.toString().startsWith("clicked")) {
                // Esperar a que el formulario esté listo después del click
                new WebDriverWait(driver, Duration.ofSeconds(10)).until(
                    ExpectedConditions.presenceOfElementLocated(By.cssSelector("[data-type='textfield'], input[type='text'], textarea"))
                );
                return;
            }
            throw new RuntimeException("JavaScript no encontro el boton: " + result);
        } catch (Exception e4) {
            throw new RuntimeException("Todos los intentos fallaron al hacer clic en 'Habilitar Formulario'", e4);
        }
    }
    
}
