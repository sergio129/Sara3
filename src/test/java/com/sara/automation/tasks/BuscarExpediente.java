package com.sara.automation.tasks;

import com.sara.automation.utils.ExpedienteContext;
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
 * Busca el expediente previamente guardado ({@link ExpedienteContext}) y abre su edición:
 *   1. Click en "Búsqueda avanzada" (id=btn_update_and_filter, en el shell).
 *   2. Dentro del iframe del formulario formio, escribe el expediente en el campo
 *      Expediente (name=data[external_code]).
 *   3. Click en "Filtrar" (id=customSubmit).
 *   4. Cuando el expediente aparece en la tabla de resultados, click en el botón
 *      "Editar" (button.btn-primary[title='Editar']) de esa fila.
 *   5. Espera a que la página de edición cargue.
 */
public class BuscarExpediente implements Task {

    private static final By BUSQUEDA_AVANZADA = By.id("btn_update_and_filter");
    private static final By CAMPO_EXPEDIENTE = By.cssSelector("input[name='data[external_code]']");
    private static final By BTN_FILTRAR = By.id("customSubmit");

    public static Performable now() {
        return instrumented(BuscarExpediente.class);
    }

    @Override
    @Step("Buscar el expediente guardado y abrir su edición")
    public <T extends Actor> void performAs(T actor) {
        WebDriver driver = BrowseTheWeb.as(actor).getDriver();
        JavascriptExecutor js = (JavascriptExecutor) driver;
        String expediente = ExpedienteContext.getExpediente();

        System.out.println("\n  [BuscarExpediente] ==================== BÚSQUEDA DE EXPEDIENTE '" + expediente + "' ====================");
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(30));

        // 1. Abrir búsqueda avanzada (en el shell, fuera del iframe).
        driver.switchTo().defaultContent();
        WebElement botonBusqueda = wait.until(ExpectedConditions.elementToBeClickable(BUSQUEDA_AVANZADA));
        clickResiliente(js, botonBusqueda);
        System.out.println("  [BuscarExpediente] ✓ Click en 'Búsqueda avanzada'");

        // 2. Ubicar el iframe del formulario de filtros y entrar a él.
        entrarAlFrameDelFormulario(driver, wait);

        // 3. Escribir el expediente en el campo Expediente.
        WebElement campo = wait.until(ExpectedConditions.visibilityOfElementLocated(CAMPO_EXPEDIENTE));
        escribirEnFormio(js, campo, expediente);
        System.out.println("  [BuscarExpediente] ✓ Expediente escrito en el campo 'Expediente'");

        // 4. Click en Filtrar.
        WebElement filtrar = wait.until(ExpectedConditions.elementToBeClickable(BTN_FILTRAR));
        clickResiliente(js, filtrar);
        System.out.println("  [BuscarExpediente] ✓ Click en 'Filtrar'");

        // 5. Esperar la fila del expediente en la tabla de resultados y abrir su edición.
        By botonEditarDeLaFila = By.xpath(
                "//table//tbody//tr[.//td[contains(normalize-space(.), '" + expediente + "')]]"
              + "//button[@title='Editar']");
        WebElement editar = wait.until(ExpectedConditions.elementToBeClickable(botonEditarDeLaFila));
        System.out.println("  [BuscarExpediente] ✓ Expediente encontrado en resultados");
        clickResiliente(js, editar);
        System.out.println("  [BuscarExpediente] ✓ Click en 'Editar'");

        // 6. Esperar a que cargue la página de edición.
        driver.switchTo().defaultContent();
        esperarCargaPagina(driver);
        System.out.println("  [BuscarExpediente] ==================== ✓ EDICIÓN DEL EXPEDIENTE ABIERTA ====================\n");
    }

    /**
     * Entra al iframe que contiene el formulario de filtros. Intenta primero el id conocido
     * 'form_onescript_iframe'; si el campo no está ahí, recorre todos los iframes de la página
     * hasta encontrar el campo Expediente (robusto ante un id de iframe distinto en esta vista).
     */
    private void entrarAlFrameDelFormulario(WebDriver driver, WebDriverWait wait) {
        boolean encontrado = wait.until(d -> {
            d.switchTo().defaultContent();

            // Caso 0: el formulario está directamente en el documento principal.
            if (!d.findElements(CAMPO_EXPEDIENTE).isEmpty()) {
                return true;
            }

            // Caso 1: iframe conocido del proyecto.
            List<WebElement> conocido = d.findElements(By.id("form_onescript_iframe"));
            if (!conocido.isEmpty()) {
                try {
                    d.switchTo().frame(conocido.get(0));
                    if (!d.findElements(CAMPO_EXPEDIENTE).isEmpty()) {
                        return true;
                    }
                } catch (Exception ignored) {
                }
                d.switchTo().defaultContent();
            }

            // Caso 2: cualquier otro iframe de la página.
            List<WebElement> frames = d.findElements(By.tagName("iframe"));
            for (WebElement frame : frames) {
                try {
                    d.switchTo().defaultContent();
                    d.switchTo().frame(frame);
                    if (!d.findElements(CAMPO_EXPEDIENTE).isEmpty()) {
                        return true;
                    }
                } catch (Exception ignored) {
                }
            }
            d.switchTo().defaultContent();
            return false;
        });

        if (!encontrado) {
            throw new AssertionError("No se encontró el campo 'Expediente' (data[external_code]) en la página ni en sus iframes.");
        }
        System.out.println("  [BuscarExpediente] ✓ Formulario de filtros localizado");
    }

    /**
     * Escribe en un input de Form.io: además de sendKeys, dispara los eventos input/change
     * para que Form.io registre el valor en su modelo interno.
     */
    private void escribirEnFormio(JavascriptExecutor js, WebElement input, String valor) {
        try {
            input.clear();
            input.sendKeys(valor);
        } catch (Exception ignored) {
        }
        String actual = input.getAttribute("value");
        if (actual == null || !actual.equals(valor)) {
            js.executeScript(
                    "arguments[0].value = arguments[1];"
                  + "arguments[0].dispatchEvent(new Event('input', {bubbles:true}));"
                  + "arguments[0].dispatchEvent(new Event('change', {bubbles:true}));",
                    input, valor);
        } else {
            js.executeScript(
                    "arguments[0].dispatchEvent(new Event('input', {bubbles:true}));"
                  + "arguments[0].dispatchEvent(new Event('change', {bubbles:true}));",
                    input);
        }
    }

    private void clickResiliente(JavascriptExecutor js, WebElement elemento) {
        try {
            js.executeScript("arguments[0].scrollIntoView({block:'center'});", elemento);
        } catch (Exception ignored) {
        }
        try {
            elemento.click();
        } catch (Exception e1) {
            try {
                js.executeScript("arguments[0].click();", elemento);
            } catch (Exception e2) {
                js.executeScript(
                        "var evt = new MouseEvent('click', { bubbles: true, cancelable: true, view: window });"
                      + "arguments[0].dispatchEvent(evt);",
                        elemento);
            }
        }
    }

    private void esperarCargaPagina(WebDriver driver) {
        try {
            new WebDriverWait(driver, Duration.ofSeconds(30)).until(
                    d -> "complete".equals(((JavascriptExecutor) d).executeScript("return document.readyState")));
        } catch (Exception e) {
            System.out.println("  [BuscarExpediente] ⚠ Timeout esperando readyState, continuando...");
        }
    }
}
