package com.sara.automation.tasks;

import com.sara.automation.interactions.SwitchToOneScriptIframe;
import com.sara.automation.interactions.OneScriptDynamicElements;
import com.sara.automation.ui.CasoCreatePage;

import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Performable;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.actions.Click;
import net.serenitybdd.screenplay.actions.Enter;
import net.serenitybdd.screenplay.actions.Scroll;
import net.serenitybdd.screenplay.targets.Target;
import net.serenitybdd.screenplay.waits.WaitUntil;
import net.thucydides.core.annotations.Step;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.Keys;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;
import java.util.List;

import static net.serenitybdd.screenplay.Tasks.instrumented;
import static net.serenitybdd.screenplay.matchers.WebElementStateMatchers.isVisible;

public class DiligenciarProveedorGestion implements Task {

    private static final String TIEMPO_MONITOREO_SITIO_DEFAULT = "60";
    private static final String TIEMPO_MONITOREO_DESTINO_DEFAULT = "120";
    private static final String CELULAR_TECNICO_DEFAULT = "3103904286";

    private final String nombreProveedor;
    private final String servicio;

    public DiligenciarProveedorGestion(String nombreProveedor, String servicio) {
        this.nombreProveedor = nombreProveedor;
        this.servicio = servicio;
    }

    public static Performable conDatos(String nombreProveedor, String servicio) {
        return instrumented(DiligenciarProveedorGestion.class, nombreProveedor, servicio);
    }

    @Override
    @Step("Gestionar proveedor: abrir tab, crear, seleccionar nombre/respuesta y guardar")
    public <T extends Actor> void performAs(T actor) {
        
        // Este paso ocurre dentro del formulario OneScript luego de crear el caso.
        actor.attemptsTo(SwitchToOneScriptIframe.required());

        // Esperar a que la página se recargue completamente después de guardar
        // La página hace reload y vuelve a mostrar los elementos del formulario
        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        try {
            new WebDriverWait(driver, Duration.ofSeconds(5)).until(
                ExpectedConditions.presenceOfElementLocated(By.id("form_onescript_iframe"))
            );
        } catch (Exception e) {
            System.out.println("  Timeout esperando iframe después de guardar: " + e.getMessage());
        }

        // Cerrar el timer overlay SOLO si está presente (chequeo INSTANTÁNEO, sin esperas).
        // El timer fue deshabilitado; antes este bloque esperaba hasta ~20s (4 selectores x 5s)
        // buscando un botón inexistente. Ahora findElements resuelve al instante (no bloquea).
        try {
            List<WebElement> timerBtns = driver.findElements(
                    By.xpath("//div[contains(@class,'kace-timer-overlay')]//button"));
            if (!timerBtns.isEmpty()) {
                timerBtns.get(0).click();
                System.out.println("  [DiligenciarProveedorGestion] Timer cerrado OK");
            } else {
                System.out.println("  [DiligenciarProveedorGestion] Timer no presente (deshabilitado), continuando sin esperar");
            }
        } catch (Exception e) {
            System.out.println("  [DiligenciarProveedorGestion] (timer no se pudo cerrar, continuando: " + e.getMessage() + ")");
        }

        // Activar el tab "Gestión de proveedores".
        // OPTIMIZACIÓN: clic directo en el anchor del tab (rápido y fiable), en lugar de
        // navegar con múltiples TAB de teclado. La espera se ancla al contenido REAL del tab
        // (la grilla de gestión de proveedores visible), no a un input genérico.
        // El teclado queda solo como fallback si el clic directo falla.
        System.out.println("  [DiligenciarProveedorGestion] Activando tab de Gestión de proveedores...");
        boolean tabEncontrado = false;
        JavascriptExecutor js = (JavascriptExecutor) driver;
        By providerTabLocator = By.xpath("//ul[@role='tablist']//a[contains(@href,'gestionDeProveedores')]");
        By tabContenidoActivo = By.cssSelector(".formio-component-gestion_proveedor_asistencia_movilidad");

        // VÍA RÁPIDA: clic directo en el anchor del tab.
        try {
            driver.switchTo().defaultContent();
            driver.switchTo().frame(driver.findElement(By.id("form_onescript_iframe")));
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(15));
            WebElement providerTab = wait.until(ExpectedConditions.presenceOfElementLocated(providerTabLocator));
            js.executeScript("arguments[0].scrollIntoView({block:'center'}); arguments[0].click();", providerTab);
            // Confirmar que el panel del tab quedó realmente visible.
            wait.until(ExpectedConditions.visibilityOfElementLocated(tabContenidoActivo));
            tabEncontrado = true;
            System.out.println("  [DiligenciarProveedorGestion] ✓ Tab activado con clic directo en el anchor");
        } catch (Exception e) {
            System.out.println("  [DiligenciarProveedorGestion] Clic directo en tab falló (" + e.getMessage() + "), usando fallback por teclado...");
        }

        // FALLBACK: navegación por teclado (16 TAB + Enter) solo si el clic directo no funcionó.
        if (!tabEncontrado) {
            try {
                driver.switchTo().defaultContent();
                driver.switchTo().frame(driver.findElement(By.id("form_onescript_iframe")));
                WebElement body = driver.findElement(By.tagName("body"));
                for (int i = 0; i < 16; i++) {
                    body.sendKeys(Keys.TAB);
                }
                body.sendKeys(Keys.ENTER);
                new WebDriverWait(driver, Duration.ofSeconds(8))
                        .until(ExpectedConditions.visibilityOfElementLocated(tabContenidoActivo));
                tabEncontrado = true;
                System.out.println("  [DiligenciarProveedorGestion] ✓ Tab activado con navegación por teclado (fallback)");
            } catch (Exception e) {
                System.out.println("  [DiligenciarProveedorGestion] Fallback por teclado falló: " + e.getMessage());
            }
        }

        if (!tabEncontrado) {
            System.out.println("  [ERROR DiligenciarProveedorGestion] No se pudo acceder al tab de Gestión de Proveedores");
            throw new RuntimeException("No se pudo acceder al tab de Gestión de Proveedores");
        }

        // Re-asegurar contexto iframe antes de buscar elementos dinámicos de proveedor.
        driver.switchTo().defaultContent();
        WebElement iframeElement = driver.findElement(By.id("form_onescript_iframe"));
        driver.switchTo().frame(iframeElement);

        System.out.println("  [DiligenciarProveedorGestion] Clic en Crear para abrir modal de proveedor...");
        try {
            OneScriptDynamicElements.clickVisibleButtonByText(driver, "Crear");
        } catch (Exception e) {
            System.out.println("  [DiligenciarProveedorGestion] Fallback a locator de Crear Proveedor");
            actor.attemptsTo(Click.on(CasoCreatePage.Boton_Crear_Proveedor));
        }

        OneScriptDynamicElements.waitForProveedorSection(driver, Duration.ofSeconds(20));

        OneScriptDynamicElements.selectCustomDropdownByComponentClass(driver, "formio-component-nombre", nombreProveedor);
        OneScriptDynamicElements.selectCustomDropdownByComponentClass(driver, "formio-component-respuesta_de_proveedor", servicio);

        // Estos campos se habilitan después de elegir la respuesta del proveedor (ej. TOMA SERVICIO).
        llenarCampo(actor, CasoCreatePage.Tiempo_Monitoreo_Sitio_Minutos, TIEMPO_MONITOREO_SITIO_DEFAULT);
        
        // Escribir campos dinámicos por ID directo (SOLUCIÓN VALIDADA)
        llenarCamposConNavegacionTab(actor);

        // Re-asegurar que estamos dentro del iframe antes de buscar/clickear el botón Guardar Proveedor.
        driver.switchTo().defaultContent();
        WebElement iframeAfterFill = driver.findElement(By.id("form_onescript_iframe"));
        driver.switchTo().frame(iframeAfterFill);

        actor.attemptsTo(WaitUntil.the(CasoCreatePage.Guardar_Proveedor, isVisible()).forNoMoreThan(20).seconds());
        actor.attemptsTo(Click.on(CasoCreatePage.Guardar_Proveedor));

        // Esperar a que el diálogo de proveedor se cierre y volver al contexto principal.
        waitForProveedorDialogToClose(driver, Duration.ofSeconds(5));
        driver.switchTo().defaultContent();
        sleep(500);

        if (!clickGeneralSaveIfPresent(driver, actor)) {
            throw new RuntimeException("Falló el guardado general del proveedor - el formulario no se guardó correctamente");
        }
        
        // ESPERA CRÍTICA: La página se recarga completamente después de guardar
        // Los estados pueden no estar disponibles inmediatamente
        System.out.println("  [DiligenciarProveedorGestion] Esperando 15 segundos para que la página se recargue completamente...");
        try {
            Thread.sleep(15000); // 15 segundos
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        System.out.println("  [DiligenciarProveedorGestion] Page recargada, interfaz lista para transicion de estados");
    }

    private <T extends Actor> boolean clickGeneralSaveIfPresent(WebDriver driver, T actor) {
        // Primer intento: JavaScript directo en iframe (más confiable)
        try {
            System.out.println("  [DiligenciarProveedorGestion] Intento 1: Guardar con JavaScript en iframe...");
            actor.attemptsTo(ClickGuardarEnIframe.clickGuardarEnIframe());
            System.out.println("  [DiligenciarProveedorGestion] ✓ Guardar clickeado con JavaScript en iframe OK");
            return true;
        } catch (Exception e) {
            System.out.println("  [DiligenciarProveedorGestion] Intento 1 falló: " + e.getMessage());
        }

        // Segundo intento: Screenplay con locator estándar
        try {
            System.out.println("  [DiligenciarProveedorGestion] Intento 2: Guardar con Screenplay (Guardar_General_Flotante)...");
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.Guardar_General_Flotante, isVisible()).forNoMoreThan(5).seconds());
            actor.attemptsTo(Click.on(CasoCreatePage.Guardar_General_Flotante));
            System.out.println("  [DiligenciarProveedorGestion] ✓ Guardado general clickeado OK");
            return true;
        } catch (Exception e) {
            System.out.println("  [DiligenciarProveedorGestion] Intento 2 falló: " + e.getMessage());
        }

        // Tercer intento: Fallback XPath genérico
        try {
            System.out.println("  [DiligenciarProveedorGestion] Intento 3: Guardar con XPath fallback...");
            By fallbackSave = By.xpath("//button[contains(normalize-space(.), 'Guardar') and not(contains(@class,'btn-primary'))]");
            WebElement button = new WebDriverWait(driver, Duration.ofSeconds(5))
                    .until(ExpectedConditions.elementToBeClickable(fallbackSave));
            clickWithJs(driver, button);
            System.out.println("  [DiligenciarProveedorGestion] ✓ Guardar general fallback clickeado OK");
            return true;
        } catch (Exception e) {
            System.out.println("  [DiligenciarProveedorGestion] Intento 3 falló: " + e.getMessage());
            return false;
        }
    }

    private void waitForProveedorDialogToClose(WebDriver driver, Duration timeout) {
        try {
            new WebDriverWait(driver, timeout)
                    .until(ExpectedConditions.invisibilityOfElementLocated(By.xpath("//div[contains(@class,'formio-dialog')]")));
            System.out.println("  [DiligenciarProveedorGestion] Proveedor dialog cerrado OK");
        } catch (Exception e) {
            throw new RuntimeException("El diálogo de proveedor no se cerró después del guardado - transacción incompleta", e);
        }
    }    
    
    private <T extends Actor> void llenarCampo(T actor, Target campo, String valor) {
        actor.attemptsTo(Scroll.to(campo));
        actor.attemptsTo(WaitUntil.the(campo, isVisible()).forNoMoreThan(20).seconds());
        actor.attemptsTo(Enter.theValue(valor).into(campo));
    }

    /**
     * Escribir directamente en campos por ID (evitando TABs complejos)
     * IDs identificados: tiempo_monitoreo_destino_minutos, celular_tecnico
     */
    private <T extends Actor> boolean llenarCamposConNavegacionTab(T actor) {
        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        try {
            // Switchear al iframe
            WebElement iframe = driver.findElement(By.id("form_onescript_iframe"));
            driver.switchTo().frame(iframe);
            System.out.println("  [CAMPOS POR ID] ✓ Switched to iframe");
            sleep(100);
            
            // Buscar y escribir en tiempo_monitoreo_destino_minutos primero
            System.out.println("  [CAMPOS POR ID] Buscando tiempo_monitoreo_destino_minutos...");
            List<WebElement> tiempoInputs = driver.findElements(By.xpath("//input[contains(@id, 'tiempo_monitoreo_destino')]") );
            if (!tiempoInputs.isEmpty()) {
                WebElement tiempoInput = tiempoInputs.get(0);
                String tiempoId = tiempoInput.getAttribute("id");
                System.out.println("  [CAMPOS POR ID] ✓ Tiempo encontrado con id=" + tiempoId + ", escribiendo: " + TIEMPO_MONITOREO_DESTINO_DEFAULT);
                setInputValueAndDispatchEvents(driver, tiempoInput, TIEMPO_MONITOREO_DESTINO_DEFAULT);
                sleep(150);
            } else {
                System.out.println("  [CAMPOS POR ID] ✗ Tiempo NO encontrado");
            }
            
            // Buscar y escribir en celular_tecnico por ID después
            System.out.println("  [CAMPOS POR ID] Buscando celular_tecnico...");
            List<WebElement> celularInputs = driver.findElements(By.id("celular_tecnico"));
            if (!celularInputs.isEmpty()) {
                WebElement celularInput = celularInputs.get(0);
                System.out.println("  [CAMPOS POR ID] ✓ Celular encontrado por ID, escribiendo: " + CELULAR_TECNICO_DEFAULT);
                setInputValueAndDispatchEvents(driver, celularInput, CELULAR_TECNICO_DEFAULT);
                sleep(150);
            } else {
                System.out.println("  [CAMPOS POR ID] ✗ Celular NO encontrado por ID");
            }
            
            // Salir del iframe
            driver.switchTo().defaultContent();
            sleep(250);
            
            // Verificar resultados
            driver.switchTo().frame(iframe);
            Object validacion = ((JavascriptExecutor) driver).executeScript(
                "const cel = document.getElementById('celular_tecnico');" +
                "const des = document.querySelector(\"input[id*='tiempo_monitoreo_destino']\");" +
                "const celVal = cel ? cel.value : 'NOT_FOUND';" +
                "const desVal = des ? des.value : 'NOT_FOUND';" +
                "return 'cel=' + celVal + '|des=' + desVal;"
            );
            driver.switchTo().defaultContent();
            
            String validacionStr = validacion != null ? validacion.toString() : "NULL";
            System.out.println("  [VALIDACION POR ID] " + validacionStr);
            
            return validacionStr.contains(CELULAR_TECNICO_DEFAULT) && validacionStr.contains(TIEMPO_MONITOREO_DESTINO_DEFAULT);
        } catch (Exception e) {
            System.out.println("  [CAMPOS POR ID] ERROR: " + e.getMessage());
            e.printStackTrace();
            try {
                driver.switchTo().defaultContent();
            } catch (Exception ignored) {}
            return false;
        }
    }

    /**
     * Establece valor en un input y dispara eventos necesarios para Form.io
     */
    private void setInputValueAndDispatchEvents(WebDriver driver, WebElement input, String value) {
        ((JavascriptExecutor) driver).executeScript(
                "arguments[0].focus();" +
                "arguments[0].value = '';" +
                "arguments[0].value = arguments[1];" +
                "arguments[0].dispatchEvent(new Event('input', {bubbles:true}));" +
                "arguments[0].dispatchEvent(new Event('change', {bubbles:true}));" +
                "arguments[0].dispatchEvent(new Event('blur', {bubbles:true}));",
                input,
                value
        );
    }

    private <T extends Actor> void llenarCampoJsInteligente(T actor, String selectorCss, String labelHint, String valor) {
        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        long deadline = System.currentTimeMillis() + Duration.ofSeconds(20).toMillis();
        boolean filled = false;

        while (System.currentTimeMillis() < deadline && !filled) {
            Object result = ((JavascriptExecutor) driver).executeScript(
                    "const normalize = txt => (txt || '')"
                            + ".toLowerCase()"
                            + ".normalize('NFD').replace(/[\\u0300-\\u036f]/g, '')"
                            + ".replace(/\\s+/g, ' ').trim();"
                            + "let input = document.querySelector(arguments[0]);"
                            + "if (!input) {"
                            + "  const wanted = normalize(arguments[1]);"
                            + "  const labels = Array.from(document.querySelectorAll('label'));"
                            + "  const label = labels.find(l => normalize(l.textContent).includes(wanted));"
                            + "  if (label) {"
                            + "    const container = label.closest('.formio-component') || label.closest('.form-group') || label.parentElement;"
                            + "    input = container ? container.querySelector('input:not([type=hidden]), textarea') : null;"
                            + "  }"
                            + "}"
                            + "if (!input) return false;"
                            + "input.scrollIntoView({block:'center', inline:'nearest'});"
                            + "input.focus();"
                            + "input.value = '';"
                            + "input.value = arguments[2];"
                            + "input.dispatchEvent(new Event('input', {bubbles:true}));"
                            + "input.dispatchEvent(new Event('change', {bubbles:true}));"
                            + "input.dispatchEvent(new Event('blur', {bubbles:true}));"
                            + "return input.value === arguments[2];",
                    selectorCss, labelHint, valor
            );

            filled = result instanceof Boolean && (Boolean) result;
            if (!filled) {
                sleep(350);
            }
        }

        if (!filled) {
            System.out.println("  [DiligenciarProveedorGestion] WARN: no se pudo diligenciar campo con selector/hint: " + selectorCss + " | " + labelHint);
        }
    }

    private <T extends Actor> void seleccionarDesdeDropdownCustom(T actor, Target control, Target searchInput, String valor) {
        actor.attemptsTo(WaitUntil.the(control, isVisible()).forNoMoreThan(20).seconds());
        actor.attemptsTo(Click.on(control));

        actor.attemptsTo(WaitUntil.the(searchInput, isVisible()).forNoMoreThan(10).seconds());
        actor.attemptsTo(Enter.theValue(valor).into(searchInput));

        actor.attemptsTo(WaitUntil.the(CasoCreatePage.CustomDropdownListItem.of(valor), isVisible()).forNoMoreThan(10).seconds());
        actor.attemptsTo(Click.on(CasoCreatePage.CustomDropdownListItem.of(valor)));
    }

    

    private void seleccionarDesdeCustomDropdownJS(WebDriver driver, String labelTexto, String valor) {
        WebElement control = getDropdownControl(driver, labelTexto);
        if (control == null) {
            throw new NoSuchElementException("No se encontró el dropdown control para label: " + labelTexto);
        }

        clickWithJs(driver, control);
        sleep(500);

        WebElement searchInput = getDropdownSearchInput(driver, labelTexto);
        if (searchInput != null) {
            setInputValue(driver, searchInput, valor);
            sleep(500);
        }

        WebElement option = findDropdownOption(driver, valor);
        if (option == null) {
            throw new NoSuchElementException("No se encontró la opción de dropdown para: " + valor);
        }

        clickWithJs(driver, option);
        sleep(500);
    }

        private WebElement getDropdownControl(WebDriver driver, String labelTexto) {
        Object element = ((JavascriptExecutor) driver).executeScript(
            "const wanted = arguments[0].toLowerCase();"
                    + "if (wanted.includes('respuesta')) {"
                    + "  const byClassRespuesta = document.querySelector('div.formio-component-custom-select.formio-component-respuesta_de_proveedor .custom-dropdown-control');"
                    + "  if (byClassRespuesta) return byClassRespuesta;"
                    + "}"
                    + "if (wanted.includes('nombre')) {"
                    + "  const byClassNombre = document.querySelector('div.formio-component-custom-select.formio-component-nombre .custom-dropdown-control');"
                    + "  if (byClassNombre) return byClassNombre;"
                    + "}"
                + "if (wanted.includes('nombre')) {"
                + "  const byId = document.querySelector('#custom-select-e75nu5o .custom-dropdown-control');"
                + "  if (byId) return byId;"
                + "}"
                + "const label = Array.from(document.querySelectorAll('label')).find(l => l.textContent.trim().toLowerCase().includes(wanted));"
                + "if (!label) return null;"
                + "const container = label.closest('.formio-component') || label.closest('.formio-component-custom-select') || label.parentElement;"
                + "if (container) { const control = container.querySelector('.custom-dropdown-control'); if (control) return control; }"
                + "return document.querySelector('.custom-dropdown-control');",
            labelTexto);

        return element instanceof WebElement ? (WebElement) element : null;
        }

        private WebElement getDropdownSearchInput(WebDriver driver, String labelTexto) {
        Object element = ((JavascriptExecutor) driver).executeScript(
            "const wanted = arguments[0].toLowerCase();"
                    + "if (wanted.includes('respuesta')) {"
                    + "  const byClassInputRespuesta = document.querySelector('div.formio-component-custom-select.formio-component-respuesta_de_proveedor input.custom-dropdown-search, div.formio-component-custom-select.formio-component-respuesta_de_proveedor input[placeholder*=\\\"buscar\\\"], div.formio-component-custom-select.formio-component-respuesta_de_proveedor input[placeholder*=\\\"Buscar\\\"]');"
                    + "  if (byClassInputRespuesta) return byClassInputRespuesta;"
                    + "}"
                    + "if (wanted.includes('nombre')) {"
                    + "  const byClassInputNombre = document.querySelector('div.formio-component-custom-select.formio-component-nombre input.custom-dropdown-search, div.formio-component-custom-select.formio-component-nombre input[placeholder*=\\\"buscar\\\"], div.formio-component-custom-select.formio-component-nombre input[placeholder*=\\\"Buscar\\\"]');"
                    + "  if (byClassInputNombre) return byClassInputNombre;"
                    + "}"
                + "if (wanted.includes('nombre')) {"
                + "  const byIdInput = document.querySelector('#custom-select-e75nu5o input.custom-dropdown-search, #custom-select-e75nu5o input[placeholder*=\\\"buscar\\\"], #custom-select-e75nu5o input[placeholder*=\\\"Buscar\\\"]');"
                + "  if (byIdInput) return byIdInput;"
                + "}"
                + "const label = Array.from(document.querySelectorAll('label')).find(l => l.textContent.trim().toLowerCase().includes(wanted));"
                + "if (!label) return null;"
                + "const container = label.closest('.formio-component') || label.closest('.formio-component-custom-select') || label.parentElement;"
                + "if (container) {"
                + "  const inside = container.querySelector('input.custom-dropdown-search, input[placeholder*=\\\"buscar\\\"], input[placeholder*=\\\"Buscar\\\"]');"
                + "  if (inside) return inside;"
                + "}"
                + "const active = document.activeElement;"
                + "if (active && active.tagName === 'INPUT') return active;"
                + "return document.querySelector('input.custom-dropdown-search, input[placeholder*=\\\"buscar\\\"], input[placeholder*=\\\"Buscar\\\"]');",
            labelTexto);

        return element instanceof WebElement ? (WebElement) element : null;
        }

    private WebElement findDropdownOption(WebDriver driver, String valor) {
        Object element = ((JavascriptExecutor) driver).executeScript(
                "const items = Array.from(document.querySelectorAll('ul.custom-dropdown-list li, div.custom-dropdown-item, div[role=\\\"option\\\"]'));"
                        + "const exact = items.find(el => el.textContent.trim().toLowerCase() === arguments[0].toLowerCase());"
                        + "if (exact) { return exact; }"
                        + "const partial = items.find(el => el.textContent.trim().toLowerCase().includes(arguments[0].toLowerCase()));"
                        + "return partial || null;",
                valor);

        return element instanceof WebElement ? (WebElement) element : null;
    }

    private void clickWithJs(WebDriver driver, WebElement element) {
        ((JavascriptExecutor) driver).executeScript(
                "arguments[0].scrollIntoView({block: 'center', inline: 'nearest'});"
                        + "arguments[0].dispatchEvent(new MouseEvent('mousedown', {bubbles:true}));"
                        + "arguments[0].dispatchEvent(new MouseEvent('mouseup', {bubbles:true}));"
                        + "arguments[0].click();",
                element);
    }

    private void setInputValue(WebDriver driver, WebElement input, String valor) {
        ((JavascriptExecutor) driver).executeScript(
                "arguments[0].focus(); arguments[0].value = arguments[1]; arguments[0].dispatchEvent(new Event('input', {bubbles: true}));",
                input,
                valor);
    }

    private void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}

