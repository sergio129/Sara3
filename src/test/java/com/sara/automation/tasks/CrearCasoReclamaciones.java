package com.sara.automation.tasks;

import com.sara.automation.interactions.SwitchToOneScriptIframe;
import com.sara.automation.ui.CasoCreatePage;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Performable;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.abilities.BrowseTheWeb;
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
import java.util.Random;

import static net.serenitybdd.screenplay.Tasks.instrumented;
import static net.serenitybdd.screenplay.matchers.WebElementStateMatchers.isVisible;

/**
 * Crea un caso de RECLAMACIONES (escenario independiente del de ASISTENCIA).
 *
 * Flujo:
 *   1. Abre el menú "Caso Express" y selecciona "Formulario Creación de Casos (RECLAMACIONES)".
 *   2. Entra al iframe OneScript y diligencia: Nombre, Siniestro/Cédula, Placa, Teléfono,
 *      Medio de Contacto (datos aleatorios).
 *   3. "Agregar contexto" -> llena el textarea del contexto -> Guarda el contexto.
 *   4. Guardado general (data[kaceCustomSubmit]).
 *
 * El login y la navegación a /agent se reutilizan de los steps existentes.
 */
public class CrearCasoReclamaciones implements Task {

    private static final Random RANDOM = new Random();
    private static final String[] NOMBRES = {"Andrés", "Camila", "Sofía", "Daniel", "Valentina", "Juan", "María", "Carlos", "Laura", "Sara"};
    private static final String[] APELLIDOS = {"García", "Rodríguez", "Martínez", "López", "González", "Pérez", "Sánchez", "Ramírez", "Torres", "Vega"};
    private static final String[] MEDIOS_CONTACTO = {"TELEFONO", "CORREO", "PRESENCIAL", "CHAT"};

    private static final By CAMPO_NOMBRE = By.cssSelector("input[name='data[nombre]']");
    private static final By CAMPO_SINIESTRO = By.cssSelector("input[name='data[siniestro_cedula_c]']");
    private static final By CAMPO_PLACA = By.cssSelector("input[name='data[placa]']");
    private static final By CAMPO_TELEFONO = By.cssSelector("input[name='data[telefono]']");
    private static final By CAMPO_MEDIO = By.cssSelector("input[name='data[medio_de_contacto]']");
    // El contexto es un editGrid en la página; "Agregar contexto" abre un DIALOG modal de Form.io
    // (div.formio-dialog-content) con el textarea y su propio botón "Guardar" (btn-primary directo en el dialog).
    private static final String EDITGRID = "historico_contexto_de_la_solicitud";
    private static final By BTN_AGREGAR_CONTEXTO = By.cssSelector("[ref='editgrid-" + EDITGRID + "-addRow']");
    private static final By BTN_AGREGAR_CONTEXTO_FALLBACK = By.xpath("//button[contains(normalize-space(.),'Agregar contexto')]");
    private static final By TEXTAREA_CONTEXTO = By.cssSelector(".formio-dialog-content textarea[maxlength='1024']");
    // Guardar del DIALOG (no del editGrid): btn-primary dentro de .formio-dialog-content.
    private static final By BTN_GUARDAR_CONTEXTO = By.xpath("//div[contains(@class,'formio-dialog-content')]//button[contains(@class,'btn-primary') and normalize-space(.)='Guardar']");
    private static final By BTN_GUARDAR_CONTEXTO_FALLBACK = By.xpath("//div[contains(@class,'formio-dialog-content')]//button[contains(@class,'btn-primary')]");
    // Filas ya guardadas dentro del editGrid de la página (cada <li>, excluyendo el header).
    private static final By FILAS_CONTEXTO = By.cssSelector(".formio-component-" + EDITGRID + " ul.editgrid-listgroup li.list-group-item:not(.list-group-header)");
    private static final By BTN_GUARDAR_GENERAL = By.cssSelector("button[name='data[kaceCustomSubmit]']");

    public static Performable now() {
        return instrumented(CrearCasoReclamaciones.class);
    }

    @Override
    @Step("Crear caso de RECLAMACIONES: seleccionar formulario, diligenciar, agregar contexto y guardar")
    public <T extends Actor> void performAs(T actor) {
        WebDriver driver = BrowseTheWeb.as(actor).getDriver();
        JavascriptExecutor js = (JavascriptExecutor) driver;

        // 1. Abrir el menú "Caso Express".
        driver.switchTo().defaultContent();
        abrirCasoExpress(actor);

        // 2. Seleccionar el formulario de RECLAMACIONES.
        actor.attemptsTo(WaitUntil.the(CasoCreatePage.Formulario_Creacion_RECLAMACIONES, isVisible()).forNoMoreThan(15).seconds());
        actor.attemptsTo(Click.on(CasoCreatePage.Formulario_Creacion_RECLAMACIONES));
        System.out.println("  [CrearCasoReclamaciones] ✓ Formulario RECLAMACIONES seleccionado");

        // 3. Entrar al iframe del formulario.
        actor.attemptsTo(SwitchToOneScriptIframe.required());
        driver.switchTo().defaultContent();
        new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(CasoCreatePage.Form_OneScript_Iframe_By));
        new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.visibilityOfElementLocated(CAMPO_NOMBRE));
        System.out.println("  [CrearCasoReclamaciones] ✓ Iframe y formulario de reclamaciones listos");

        // 4. Diligenciar los campos básicos (datos aleatorios).
        String nombre = NOMBRES[RANDOM.nextInt(NOMBRES.length)] + " " + APELLIDOS[RANDOM.nextInt(APELLIDOS.length)] + " " + APELLIDOS[RANDOM.nextInt(APELLIDOS.length)];
        escribir(driver, CAMPO_NOMBRE, nombre);
        escribir(driver, CAMPO_SINIESTRO, randomDigitos(10));
        escribir(driver, CAMPO_PLACA, randomLetras(3) + randomDigitos(3));
        escribir(driver, CAMPO_TELEFONO, "3" + randomDigitos(9));
        escribir(driver, CAMPO_MEDIO, MEDIOS_CONTACTO[RANDOM.nextInt(MEDIOS_CONTACTO.length)]);
        System.out.println("  [CrearCasoReclamaciones] ✓ Campos básicos diligenciados (Nombre: " + nombre + ")");

        // 5. Agregar contexto: abre el editor, llena el textarea y guarda el contexto.
        int filasAntes = driver.findElements(FILAS_CONTEXTO).size();
        WebElement btnAgregar = esperarClickable(driver, BTN_AGREGAR_CONTEXTO, BTN_AGREGAR_CONTEXTO_FALLBACK, 15);
        clickResiliente(js, btnAgregar);
        System.out.println("  [CrearCasoReclamaciones] ✓ Click en 'Agregar contexto'");

        WebElement textarea = new WebDriverWait(driver, Duration.ofSeconds(15))
                .until(d -> {
                    for (WebElement t : d.findElements(TEXTAREA_CONTEXTO)) {
                        if (t.isDisplayed() && t.isEnabled()) {
                            return t;
                        }
                    }
                    return null;
                });
        String contexto = "Reclamacion";
        setReactTextareaValue(js, textarea, contexto);
        System.out.println("  [CrearCasoReclamaciones] ✓ Contexto escrito");

        WebElement btnGuardarCtx = esperarClickable(driver, BTN_GUARDAR_CONTEXTO, BTN_GUARDAR_CONTEXTO_FALLBACK, 15);
        clickResiliente(js, btnGuardarCtx);

        // Esperar a que el editor inline cierre Y la fila quede committeada en el editGrid
        // antes de disparar el guardado general (si no, la validación required falla aunque la fila se vea).
        final int objetivo = filasAntes + 1;
        new WebDriverWait(driver, Duration.ofSeconds(15)).until(d ->
                d.findElements(TEXTAREA_CONTEXTO).stream().noneMatch(WebElement::isDisplayed)
                && d.findElements(FILAS_CONTEXTO).size() >= objetivo);
        System.out.println("  [CrearCasoReclamaciones] ✓ Contexto guardado (filas=" + driver.findElements(FILAS_CONTEXTO).size() + ")");

        // 6. Guardado general del caso.
        WebElement btnGeneral = new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.presenceOfElementLocated(BTN_GUARDAR_GENERAL));
        js.executeScript("arguments[0].scrollIntoView({block:'center'});", btnGeneral);
        clickResiliente(js, btnGeneral);
        System.out.println("  [CrearCasoReclamaciones] ✓ Click en Guardar general");

        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        driver.switchTo().defaultContent();
        System.out.println("  [CrearCasoReclamaciones] ==================== ✓ CASO DE RECLAMACIONES CREADO ====================\n");
    }

    private <T extends Actor> void abrirCasoExpress(T actor) {
        try {
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.Caso_Express, isVisible()).forNoMoreThan(15).seconds());
            actor.attemptsTo(Click.on(CasoCreatePage.Caso_Express));
        } catch (Throwable e) {
            try {
                actor.attemptsTo(Click.on(CasoCreatePage.Caso_Express_FALLBACK));
            } catch (Throwable ex) {
                throw new RuntimeException("No se pudo abrir el menú 'Caso Express'", ex);
            }
        }
    }

    /** Espera el botón por su locator principal (ref del editGrid) y si no aparece usa el fallback por texto. */
    private WebElement esperarClickable(WebDriver driver, By principal, By fallback, int segundos) {
        try {
            return new WebDriverWait(driver, Duration.ofSeconds(segundos))
                    .until(ExpectedConditions.elementToBeClickable(principal));
        } catch (Exception e) {
            return new WebDriverWait(driver, Duration.ofSeconds(segundos))
                    .until(ExpectedConditions.elementToBeClickable(fallback));
        }
    }

    /**
     * Escribe en un textarea controlado por React/Form.io usando el SETTER NATIVO del prototipo.
     * Hacerlo con sendKeys o asignando .value directamente actualiza el DOM (y el contador visual),
     * pero React ignora el cambio porque no pasa por su setter, dejando el valor del modelo vacío
     * → la fila del editGrid queda inválida y "Contexto de la solicitud" falla la validación required.
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

    private void escribir(WebDriver driver, By campo, String valor) {
        WebElement el = new WebDriverWait(driver, Duration.ofSeconds(15))
                .until(ExpectedConditions.visibilityOfElementLocated(campo));
        el.clear();
        el.sendKeys(valor);
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

    private String randomDigitos(int n) {
        StringBuilder sb = new StringBuilder(n);
        for (int i = 0; i < n; i++) {
            sb.append(RANDOM.nextInt(10));
        }
        return sb.toString();
    }

    private String randomLetras(int n) {
        StringBuilder sb = new StringBuilder(n);
        for (int i = 0; i < n; i++) {
            sb.append((char) ('A' + RANDOM.nextInt(26)));
        }
        return sb.toString();
    }
}
