package com.sara.automation.tasks;

import com.sara.automation.interactions.OneScriptDynamicElements;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Performable;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.abilities.BrowseTheWeb;
import net.thucydides.core.annotations.Step;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;
import java.util.List;

import static net.serenitybdd.screenplay.Tasks.instrumented;

/**
 * Gestiona la reclamación tras crear el caso (la página recarga a "Detalles del caso").
 *
 * Flujo:
 *   1. Entra al iframe del formulario y hace clic en "Gestionar"
 *      (botón ref='editgrid-gestion_reclamacion-addRow').
 *   2. En el modal (mismos widgets custom-select del formulario de proveedores):
 *        - Tipo de gestión   -> primera opción válida (requerido).
 *        - Persona de gestión -> primera opción válida (requerido).
 *        - Fecha y hora       -> autollenada y deshabilitada (se omite).
 *        - Observación        -> textarea (requerido) con texto de prueba.
 *        - Estado             -> "GESTIONADO".
 *   3. Guarda el modal y luego ejecuta el guardado general (data[kaceCustomSubmit]).
 *   4. Fin del flujo.
 */
public class GestionarReclamacion implements Task {

    private static final String EDITGRID = "gestion_reclamacion";
    private static final By BTN_GESTIONAR = By.cssSelector("[ref='editgrid-" + EDITGRID + "-addRow']");
    private static final By BTN_GESTIONAR_FALLBACK = By.xpath("//button[contains(normalize-space(.),'Gestionar')]");

    // Scope CSS del modal: acota la búsqueda de dropdowns al dialog (hay homónimos en la página).
    private static final String SCOPE_DIALOG = ".formio-dialog-content";

    // Dropdowns custom (mismo widget que el formulario de proveedores/creación).
    private static final String COMP_TIPO_GESTION = "formio-component-tipo_de_gestion";
    private static final String COMP_PERSONA_GESTION = "formio-component-persona_de_gestion";
    private static final String COMP_ESTADO = "formio-component-estado";
    private static final String ESTADO_OBJETIVO = "GESTIONADO";

    // El modal "Gestionar" es un DIALOG de Form.io (div.formio-dialog-content) con su propio
    // textarea (requerido, maxlength 1024) y botón "Guardar" (btn-primary directo en el dialog).
    private static final By TEXTAREA_OBS = By.cssSelector(".formio-dialog-content textarea.form-control[maxlength='1024']");
    private static final By BTN_GUARDAR_MODAL = By.xpath(
            "//div[contains(@class,'formio-dialog-content')]//button[contains(@class,'btn-primary') and normalize-space(.)='Guardar']");
    private static final By BTN_GUARDAR_MODAL_FALLBACK = By.xpath(
            "//div[contains(@class,'formio-dialog-content')]//button[contains(@class,'btn-primary')]");

    // Cambio de estado del caso (componente kace_states): botón "Gestionado" entre los estados disponibles.
    private static final By BTN_ESTADO_GESTIONADO = By.xpath(
            "//div[contains(@class,'formio-component-kace_states')]//button[normalize-space(.)='Gestionado']");
    // Guardado general: el botón usa id estable 'kaceCustomSubmit' (su name es 'data[kaceCustomSubmit1]').
    private static final By BTN_GUARDAR_GENERAL = By.id("kaceCustomSubmit");

    private static final String TEXTO_OBS = "Gestion de reclamacion automatizada";

    public static Performable now() {
        return instrumented(GestionarReclamacion.class);
    }

    @Override
    @Step("Gestionar la reclamación: seleccionar tipo/persona/estado, observación y guardar")
    public <T extends Actor> void performAs(T actor) {
        WebDriver driver = BrowseTheWeb.as(actor).getDriver();
        JavascriptExecutor js = (JavascriptExecutor) driver;
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(40));

        System.out.println("\n  [GestionarReclamacion] ==================== GESTIÓN DE RECLAMACIÓN ====================");

        // 1. Entrar al iframe (la página recargó a Detalles del caso) y abrir el modal "Gestionar".
        entrarAlFrameConBoton(driver, wait);
        WebElement btnGestionar = esperarClickable(driver, BTN_GESTIONAR, BTN_GESTIONAR_FALLBACK, 20);
        clickResiliente(js, btnGestionar);
        System.out.println("  [GestionarReclamacion] ✓ Click en 'Gestionar'");

        // 2. Esperar a que el modal abra (dropdown de tipo de gestión DENTRO del dialog visible).
        wait.until(d -> !d.findElements(By.cssSelector(SCOPE_DIALOG + " ." + COMP_TIPO_GESTION + " .custom-dropdown-control")).isEmpty());

        // 3. Tipo de gestión y Persona de gestión: primera opción válida.
        // Acotamos al dialog: existe otro 'tipo_de_gestion' en el resumen del editGrid de la página.
        String tipo = OneScriptDynamicElements.selectFirstCustomDropdownOption(driver, COMP_TIPO_GESTION, SCOPE_DIALOG);
        System.out.println("  [GestionarReclamacion] ✓ Tipo de gestión = " + tipo);
        String persona = OneScriptDynamicElements.selectFirstCustomDropdownOption(driver, COMP_PERSONA_GESTION, SCOPE_DIALOG);
        System.out.println("  [GestionarReclamacion] ✓ Persona de gestión = " + persona);

        // 4. Observación (requerida).
        WebElement textarea = wait.until(d -> {
            for (WebElement t : d.findElements(TEXTAREA_OBS)) {
                if (t.isDisplayed() && t.isEnabled()) {
                    return t;
                }
            }
            return null;
        });
        setReactTextareaValue(js, textarea, TEXTO_OBS);
        System.out.println("  [GestionarReclamacion] ✓ Observación escrita");

        // 5. Estado = GESTIONADO (acotado al dialog).
        OneScriptDynamicElements.selectCustomDropdownByComponentClass(driver, COMP_ESTADO, ESTADO_OBJETIVO, SCOPE_DIALOG);
        System.out.println("  [GestionarReclamacion] ✓ Estado = " + ESTADO_OBJETIVO);

        // 6. Guardar el modal y esperar a que cierre.
        WebElement btnGuardarModal = esperarClickable(driver, BTN_GUARDAR_MODAL, BTN_GUARDAR_MODAL_FALLBACK, 15);
        clickResiliente(js, btnGuardarModal);
        new WebDriverWait(driver, Duration.ofSeconds(15)).until(d ->
                d.findElements(TEXTAREA_OBS).stream().noneMatch(WebElement::isDisplayed));
        System.out.println("  [GestionarReclamacion] ✓ Gestión guardada (modal cerrado)");

        // 7. Cambiar el estado del caso a "Gestionado" en el componente kace_states.
        WebElement btnEstado = new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.elementToBeClickable(BTN_ESTADO_GESTIONADO));
        clickResiliente(js, btnEstado);
        System.out.println("  [GestionarReclamacion] ✓ Estado del caso = Gestionado");

        // 8. Guardado general.
        WebElement btnGeneral = wait.until(ExpectedConditions.presenceOfElementLocated(BTN_GUARDAR_GENERAL));
        js.executeScript("arguments[0].scrollIntoView({block:'center'});", btnGeneral);
        clickResiliente(js, btnGeneral);
        System.out.println("  [GestionarReclamacion] ✓ Click en Guardar general");

        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        driver.switchTo().defaultContent();
        System.out.println("  [GestionarReclamacion] ==================== ✓ RECLAMACIÓN GESTIONADA - FIN DEL FLUJO ====================\n");
    }

    /** Tras la recarga, localiza el iframe que contiene el botón "Gestionar". */
    private void entrarAlFrameConBoton(WebDriver driver, WebDriverWait wait) {
        boolean encontrado = wait.until(d -> {
            d.switchTo().defaultContent();
            if (!d.findElements(BTN_GESTIONAR).isEmpty() || !d.findElements(BTN_GESTIONAR_FALLBACK).isEmpty()) {
                return true;
            }
            List<WebElement> conocido = d.findElements(By.id("form_onescript_iframe"));
            if (!conocido.isEmpty()) {
                try {
                    d.switchTo().frame(conocido.get(0));
                    if (!d.findElements(BTN_GESTIONAR).isEmpty() || !d.findElements(BTN_GESTIONAR_FALLBACK).isEmpty()) {
                        return true;
                    }
                } catch (Exception ignored) {
                }
                d.switchTo().defaultContent();
            }
            for (WebElement frame : d.findElements(By.tagName("iframe"))) {
                try {
                    d.switchTo().defaultContent();
                    d.switchTo().frame(frame);
                    if (!d.findElements(BTN_GESTIONAR).isEmpty() || !d.findElements(BTN_GESTIONAR_FALLBACK).isEmpty()) {
                        return true;
                    }
                } catch (Exception ignored) {
                }
            }
            d.switchTo().defaultContent();
            return false;
        });
        if (!encontrado) {
            throw new AssertionError("No se encontró el botón 'Gestionar' (editgrid-gestion_reclamacion-addRow) en la página ni en sus iframes.");
        }
        System.out.println("  [GestionarReclamacion] ✓ Botón 'Gestionar' localizado");
    }

    /**
     * Escribe en un textarea controlado por React/Form.io usando el SETTER NATIVO del prototipo,
     * para que React registre el valor en el modelo (sendKeys/.value no bastan: actualizan el DOM
     * pero no el estado del componente, dejando el campo requerido vacío en la validación).
     */
    private void setReactTextareaValue(JavascriptExecutor js, WebElement textarea, String valor) {
        js.executeScript(
                "var el = arguments[0]; var val = arguments[1];"
              + "var proto = window.HTMLTextAreaElement.prototype;"
              + "var setter = Object.getOwnPropertyDescriptor(proto, 'value').set;"
              + "el.focus();"
              + "setter.call(el, '');"
              + "el.dispatchEvent(new Event('input', {bubbles:true}));"
              + "setter.call(el, val);"
              + "el.dispatchEvent(new Event('input', {bubbles:true}));"
              + "el.dispatchEvent(new Event('change', {bubbles:true}));"
              + "el.dispatchEvent(new Event('blur', {bubbles:true}));",
                textarea, valor);
    }

    private WebElement esperarClickable(WebDriver driver, By principal, By fallback, int segundos) {
        try {
            return new WebDriverWait(driver, Duration.ofSeconds(segundos))
                    .until(ExpectedConditions.elementToBeClickable(principal));
        } catch (Exception e) {
            return new WebDriverWait(driver, Duration.ofSeconds(segundos))
                    .until(ExpectedConditions.elementToBeClickable(fallback));
        }
    }

    private void clickResiliente(JavascriptExecutor js, WebElement el) {
        try {
            js.executeScript("arguments[0].scrollIntoView({block:'center'});", el);
        } catch (Exception ignored) {
        }
        try {
            el.click();
        } catch (Exception e1) {
            try {
                js.executeScript("arguments[0].click();", el);
            } catch (Exception e2) {
                js.executeScript(
                        "var el=arguments[0];"
                      + "el.dispatchEvent(new MouseEvent('mousedown',{bubbles:true,cancelable:true,view:window}));"
                      + "el.dispatchEvent(new MouseEvent('mouseup',{bubbles:true,cancelable:true,view:window}));"
                      + "el.click();", el);
            }
        }
    }
}
