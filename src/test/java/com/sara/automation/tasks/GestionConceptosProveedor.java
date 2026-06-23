package com.sara.automation.tasks;

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
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;
import java.util.HashSet;
import java.util.List;
import java.util.Random;
import java.util.Set;

import static net.serenitybdd.screenplay.Tasks.instrumented;

/**
 * Gestión de conceptos del proveedor sobre el expediente en edición:
 *   1. Espera y entra al iframe del formulario.
 *   2. Marca el check "no acepta conceptos" (data[no_acepta_conceptos_check]),
 *      que habilita los demás campos.
 *   3. Llena AUTOMÁTICAMENTE todos los controles habilitados del formulario,
 *      repitiendo pasadas hasta que no aparezcan nuevos (cascadas profundas):
 *        - input texto / textarea: número (2 dígitos) si es numérico, si no, texto de prueba.
 *        - select nativos: primera opción válida.
 *        - checkboxes: se marcan (excepto el de control).
 *        - multiselect formio (best-effort): abre y elige la primera opción.
 *   4. Reporta en log los campos requeridos que quedaron vacíos.
 *   5. Click en Guardar (data[kaceCustomSubmit]) y espera.
 *
 * Todos los selectores se acotan a name="data[...]" / contenedores del formulario para no
 * tocar controles ajenos (p. ej. el select de paginación de la tabla de resultados).
 */
public class GestionConceptosProveedor implements Task {

    private static final By CHECK_NO_ACEPTA = By.cssSelector("input[name='data[no_acepta_conceptos_check]']");
    private static final By CAMPOS_TEXTO = By.cssSelector(
            "input.form-control[type='text'][name^='data['], textarea[name^='data[']");
    private static final By SELECTS = By.cssSelector("select[name^='data[']");
    private static final By CHECKBOXES = By.cssSelector("input[type='checkbox'][name^='data[']");
    private static final By MULTISELECTS = By.cssSelector(".formio-component-custom-multiselect");
    // Dropdown custom del proyecto (no <select> nativo): se abre con .custom-dropdown-control
    // y las opciones aparecen en ul.custom-dropdown-list li (solo las del abierto quedan visibles).
    private static final By CUSTOM_DROPDOWN_CONTROL = By.cssSelector(".custom-dropdown-control");
    private static final By CUSTOM_DROPDOWN_OPCIONES = By.cssSelector("ul.custom-dropdown-list li");
    private static final By BTN_GUARDAR = By.cssSelector("button[name='data[kaceCustomSubmit]']");

    private static final String TEXTO_PRUEBA = "Prueba automatica";
    // Campos forzados a numéricos aunque no declaren inputmode/pattern (match por fragmento en name).
    private static final String[] NUMERICOS_POR_NOMBRE = {"convenio"};
    // Pasadas de llenado. En 1 = una sola pasada (más rápido, sin estabilización).
    // Subir a 3 si los campos en cascada no alcanzan a llenarse en una sola pasada.
    private static final int MAX_ITERACIONES = 2;

    private static final Random RANDOM = new Random();

    public static Performable now() {
        return instrumented(GestionConceptosProveedor.class);
    }

    @Override
    @Step("Gestionar los conceptos del proveedor (marcar check y llenar todos los campos habilitados)")
    public <T extends Actor> void performAs(T actor) {
        WebDriver driver = BrowseTheWeb.as(actor).getDriver();
        JavascriptExecutor js = (JavascriptExecutor) driver;
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(40));

        System.out.println("\n  [GestionConceptosProveedor] ==================== GESTIÓN DE CONCEPTOS ====================");

        // 1. Entrar al iframe que contiene el formulario.
        entrarAlFrameDelFormulario(driver, wait);

        // 2. Marcar el check "no acepta conceptos".
        // OJO: al clickearlo, Form.io re-renderiza y la referencia previa queda stale; por eso
        // re-localizamos el elemento fresco antes de disparar 'change' y reintentamos ante staleness.
        marcarCheckNoAcepta(driver, js, wait);
        System.out.println("  [GestionConceptosProveedor] ✓ Check 'no acepta conceptos' marcado");

        // 3. Llenar todos los controles, repitiendo hasta estabilizar.
        int total = llenarFormularioHastaEstabilizar(driver, js, wait);
        System.out.println("  [GestionConceptosProveedor] ✓ Total de controles gestionados: " + total);

        // 4. Reportar requeridos vacíos (no falla, solo avisa).
        reportarRequeridosVacios(driver);

        // 5. Guardar.
        // Usamos presencia + click JS en vez de elementToBeClickable: tras los últimos 'change',
        // Form.io recalcula y deja el botón "no clickable" por varios segundos, lo que hacía que
        // Selenium hiciera polling (~20s). El click JS no requiere ese estado.
        WebElement guardar = wait.until(ExpectedConditions.presenceOfElementLocated(BTN_GUARDAR));
        js.executeScript("arguments[0].scrollIntoView({block:'center'});", guardar);
        clickResiliente(js, guardar);
        System.out.println("  [GestionConceptosProveedor] ✓ Click en 'Guardar'");

        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        System.out.println("  [GestionConceptosProveedor] ==================== ✓ CONCEPTOS GUARDADOS - FIN DEL FLUJO ====================\n");
    }

    /**
     * Marca el check de control re-localizándolo fresco tras el click (Form.io re-renderiza y
     * deja stale la referencia) y reintentando ante StaleElementReferenceException.
     */
    private void marcarCheckNoAcepta(WebDriver driver, JavascriptExecutor js, WebDriverWait wait) {
        for (int intento = 1; intento <= 3; intento++) {
            try {
                WebElement check = wait.until(ExpectedConditions.presenceOfElementLocated(CHECK_NO_ACEPTA));
                js.executeScript("arguments[0].scrollIntoView({block:'center'});", check);
                if (!check.isSelected()) {
                    clickResiliente(js, check);
                }
                // Re-localizar fresco para evitar stale tras el re-render del click.
                WebElement fresco = driver.findElement(CHECK_NO_ACEPTA);
                js.executeScript("arguments[0].dispatchEvent(new Event('change', {bubbles:true}));", fresco);
                return;
            } catch (org.openqa.selenium.StaleElementReferenceException e) {
                System.out.println("  [GestionConceptosProveedor]   (check stale, reintento " + intento + ")");
                esperar(500);
            }
        }
        throw new AssertionError("No fue posible marcar el check 'no acepta conceptos' (stale tras varios intentos).");
    }

    /**
     * Repite pasadas de llenado (texto, selects, checkboxes, multiselects) hasta que una
     * pasada completa no gestione ningún control nuevo, o hasta MAX_ITERACIONES.
     * Cada control se gestiona una sola vez (dedupe por clave estable name/id).
     * @return total de controles gestionados.
     */
    private int llenarFormularioHastaEstabilizar(WebDriver driver, JavascriptExecutor js, WebDriverWait wait) {
        // Esperar a que haya al menos un control habilitado tras marcar el check.
        try {
            wait.until(d -> d.findElements(CAMPOS_TEXTO).stream().anyMatch(WebElement::isDisplayed)
                    || d.findElements(SELECTS).stream().anyMatch(WebElement::isDisplayed));
        } catch (Exception e) {
            System.out.println("  [GestionConceptosProveedor] ⚠ No se detectaron controles habilitados tras el check.");
        }

        Set<String> gestionados = new HashSet<>();
        for (int iteracion = 1; iteracion <= MAX_ITERACIONES; iteracion++) {
            int antes = gestionados.size();
            llenarTextos(driver, js, gestionados);
            llenarSelects(driver, gestionados);
            llenarCustomDropdowns(driver, js, gestionados);
            marcarCheckboxes(driver, js, gestionados);
            llenarMultiselects(driver, js, gestionados);

            if (gestionados.size() == antes) {
                System.out.println("  [GestionConceptosProveedor] ✓ Formulario estable tras " + iteracion + " iteración(es)");
                break;
            }
            esperar(300);
        }
        return gestionados.size();
    }

    private void llenarTextos(WebDriver driver, JavascriptExecutor js, Set<String> gestionados) {
        for (WebElement campo : driver.findElements(CAMPOS_TEXTO)) {
            try {
                String clave = clave(campo, "text");
                if (clave == null || gestionados.contains(clave)) {
                    continue; // ya gestionado: salto barato, sin más round-trips
                }
                if (!editable(campo)) {
                    continue; // aún no editable: se reintenta en la próxima iteración
                }
                gestionados.add(clave);
                String valor = esNumerico(campo) ? numero2Digitos() : TEXTO_PRUEBA;
                escribirEnFormio(js, campo, valor);
                System.out.println("  [GestionConceptosProveedor]   [texto] " + clave + " = " + valor);
            } catch (org.openqa.selenium.StaleElementReferenceException ignored) {
            }
        }
    }

    private void llenarSelects(WebDriver driver, Set<String> gestionados) {
        for (WebElement sel : driver.findElements(SELECTS)) {
            try {
                String clave = clave(sel, "select");
                if (clave == null || gestionados.contains(clave)) {
                    continue;
                }
                if (!editable(sel)) {
                    continue;
                }
                gestionados.add(clave);
                Select select = new Select(sel);
                // Recolectar las opciones con value no vacío (descarta placeholders tipo "Elige una opción").
                List<WebElement> validas = new java.util.ArrayList<>();
                for (WebElement opt : select.getOptions()) {
                    String val = opt.getAttribute("value");
                    if (val != null && !val.trim().isEmpty()) {
                        validas.add(opt);
                    }
                }
                if (!validas.isEmpty()) {
                    // Elegir una al azar entre las opciones válidas.
                    WebElement elegida = validas.get(RANDOM.nextInt(validas.size()));
                    select.selectByValue(elegida.getAttribute("value"));
                    System.out.println("  [GestionConceptosProveedor]   [select] " + clave + " = " + elegida.getText().trim()
                            + " (al azar entre " + validas.size() + ")");
                } else {
                    System.out.println("  [GestionConceptosProveedor]   [select] " + clave + " sin opciones válidas");
                }
            } catch (org.openqa.selenium.StaleElementReferenceException ignored) {
            } catch (Exception e) {
                System.out.println("  [GestionConceptosProveedor]   ⚠ select no manejado: " + e.getMessage());
            }
        }
    }

    /**
     * Maneja los dropdowns custom del proyecto (.custom-dropdown-control). Abre cada uno y
     * elige una opción AL AZAR entre las visibles (las del dropdown abierto). Mismo widget
     * que usa el formulario de creación/búsqueda.
     */
    private void llenarCustomDropdowns(WebDriver driver, JavascriptExecutor js, Set<String> gestionados) {
        for (WebElement control : driver.findElements(CUSTOM_DROPDOWN_CONTROL)) {
            try {
                if (!control.isDisplayed()) {
                    continue;
                }
                String clave = claveCustomDropdown(js, control);
                if (clave == null || gestionados.contains(clave)) {
                    continue;
                }
                gestionados.add(clave);

                // Abrir el dropdown.
                js.executeScript("arguments[0].scrollIntoView({block:'center'});", control);
                clickResiliente(js, control);
                esperar(400);

                // Opciones visibles = las del dropdown recién abierto.
                List<WebElement> opciones = new java.util.ArrayList<>();
                for (WebElement li : driver.findElements(CUSTOM_DROPDOWN_OPCIONES)) {
                    try {
                        if (li.isDisplayed() && !li.getText().trim().isEmpty()) {
                            opciones.add(li);
                        }
                    } catch (Exception ignored) {
                    }
                }

                if (!opciones.isEmpty()) {
                    WebElement elegida = opciones.get(RANDOM.nextInt(opciones.size()));
                    String texto = elegida.getText().trim();
                    clickResiliente(js, elegida);
                    System.out.println("  [GestionConceptosProveedor]   [dropdown] " + clave + " = " + texto
                            + " (al azar entre " + opciones.size() + ")");
                } else {
                    System.out.println("  [GestionConceptosProveedor]   [dropdown] " + clave + " sin opciones visibles");
                    // Cerrar el dropdown para no dejarlo abierto sobre otros controles.
                    clickResiliente(js, control);
                }
                esperar(200);
            } catch (org.openqa.selenium.StaleElementReferenceException ignored) {
            } catch (Exception e) {
                System.out.println("  [GestionConceptosProveedor]   ⚠ dropdown no manejado: " + e.getMessage());
            }
        }
    }

    /** Clave estable para un custom-dropdown: id (o className) del .formio-component contenedor. */
    private String claveCustomDropdown(JavascriptExecutor js, WebElement control) {
        try {
            Object key = js.executeScript(
                    "var c = arguments[0].closest('.formio-component');"
                  + "if (!c) return null;"
                  + "return (c.id && c.id.length) ? c.id : c.className;",
                    control);
            return key == null ? null : "dropdown:" + key;
        } catch (Exception e) {
            return null;
        }
    }

    private void marcarCheckboxes(WebDriver driver, JavascriptExecutor js, Set<String> gestionados) {
        for (WebElement chk : driver.findElements(CHECKBOXES)) {
            try {
                String clave = clave(chk, "check");
                if (clave == null || gestionados.contains(clave)) {
                    continue;
                }
                // No tocar el check de control (re-togglearlo desactivaría los campos).
                if (clave.contains("no_acepta_conceptos_check")) {
                    continue;
                }
                if (!editable(chk)) {
                    continue;
                }
                gestionados.add(clave);
                if (!chk.isSelected()) {
                    clickResiliente(js, chk);
                    js.executeScript("arguments[0].dispatchEvent(new Event('change', {bubbles:true}));", chk);
                }
                System.out.println("  [GestionConceptosProveedor]   [check] " + clave + " marcado");
            } catch (org.openqa.selenium.StaleElementReferenceException ignored) {
            } catch (Exception e) {
                System.out.println("  [GestionConceptosProveedor]   ⚠ checkbox no manejado: " + e.getMessage());
            }
        }
    }

    /**
     * Best-effort para multiselects formio (.formio-component-custom-multiselect):
     * abre el control y elige la primera opción de la lista. Si no logra interactuar,
     * lo registra y continúa (no rompe el flujo).
     */
    private void llenarMultiselects(WebDriver driver, JavascriptExecutor js, Set<String> gestionados) {
        for (WebElement ms : driver.findElements(MULTISELECTS)) {
            try {
                String clave = clave(ms, "multiselect");
                if (clave == null || gestionados.contains(clave)) {
                    continue;
                }
                if (!ms.isDisplayed()) {
                    continue;
                }
                gestionados.add(clave);
                List<WebElement> input = ms.findElements(By.cssSelector(".multi-select-input, .multi-select-container"));
                if (input.isEmpty()) {
                    System.out.println("  [GestionConceptosProveedor]   [multiselect] " + clave + " sin control de apertura");
                    continue;
                }
                clickResiliente(js, input.get(0));
                esperar(400);
                // Buscar opciones de la lista desplegada (varias variantes posibles del widget).
                List<WebElement> opciones = ms.findElements(By.cssSelector(
                        ".multi-select-options li, .multi-select-dropdown li, ul li, [role='option']"));
                WebElement primera = opciones.stream().filter(WebElement::isDisplayed).findFirst().orElse(null);
                if (primera != null) {
                    clickResiliente(js, primera);
                    System.out.println("  [GestionConceptosProveedor]   [multiselect] " + clave + " = " + primera.getText().trim());
                } else {
                    System.out.println("  [GestionConceptosProveedor]   [multiselect] " + clave + " sin opciones visibles (revisar manualmente)");
                }
            } catch (org.openqa.selenium.StaleElementReferenceException ignored) {
            } catch (Exception e) {
                System.out.println("  [GestionConceptosProveedor]   ⚠ multiselect no manejado: " + e.getMessage());
            }
        }
    }

    /** Avisa en log de controles requeridos (aria-required='true') que quedaron vacíos. */
    private void reportarRequeridosVacios(WebDriver driver) {
        try {
            List<WebElement> requeridos = driver.findElements(By.cssSelector("[aria-required='true'][name^='data[']"));
            int vacios = 0;
            for (WebElement campo : requeridos) {
                try {
                    if (!campo.isDisplayed()) {
                        continue;
                    }
                    String val = campo.getAttribute("value");
                    boolean vacio = (val == null || val.trim().isEmpty());
                    if ("checkbox".equals(campo.getAttribute("type"))) {
                        vacio = !campo.isSelected();
                    }
                    if (vacio) {
                        System.out.println("  [GestionConceptosProveedor]   ⚠ REQUERIDO VACÍO: " + campo.getAttribute("name"));
                        vacios++;
                    }
                } catch (Exception ignored) {
                }
            }
            if (vacios == 0) {
                System.out.println("  [GestionConceptosProveedor] ✓ No quedaron campos requeridos vacíos (detectables).");
            }
        } catch (Exception e) {
            System.out.println("  [GestionConceptosProveedor]   ⚠ No fue posible verificar requeridos: " + e.getMessage());
        }
    }

    private void entrarAlFrameDelFormulario(WebDriver driver, WebDriverWait wait) {
        boolean encontrado = wait.until(d -> {
            d.switchTo().defaultContent();
            if (!d.findElements(CHECK_NO_ACEPTA).isEmpty()) {
                return true;
            }
            List<WebElement> conocido = d.findElements(By.id("form_onescript_iframe"));
            if (!conocido.isEmpty()) {
                try {
                    d.switchTo().frame(conocido.get(0));
                    if (!d.findElements(CHECK_NO_ACEPTA).isEmpty()) {
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
                    if (!d.findElements(CHECK_NO_ACEPTA).isEmpty()) {
                        return true;
                    }
                } catch (Exception ignored) {
                }
            }
            d.switchTo().defaultContent();
            return false;
        });
        if (!encontrado) {
            throw new AssertionError("No se encontró el check 'no acepta conceptos' (data[no_acepta_conceptos_check]) en la página ni en sus iframes.");
        }
        System.out.println("  [GestionConceptosProveedor] ✓ Formulario de conceptos localizado");
    }

    /** Clave estable para dedupe: prefijo de tipo + name (o id si no hay name). */
    private String clave(WebElement el, String tipo) {
        String name = el.getAttribute("name");
        if (name != null && !name.trim().isEmpty()) {
            return tipo + ":" + name;
        }
        String id = el.getAttribute("id");
        if (id != null && !id.trim().isEmpty()) {
            return tipo + "#" + id;
        }
        return null;
    }

    /** Visible, habilitado y no readonly. */
    private boolean editable(WebElement el) {
        if (!el.isDisplayed() || !el.isEnabled()) {
            return false;
        }
        String readonly = el.getAttribute("readonly");
        return readonly == null || readonly.equals("false");
    }

    /** Un campo es numérico si declara inputmode='decimal', pattern numérico, o su name está forzado. */
    private boolean esNumerico(WebElement campo) {
        String inputmode = campo.getAttribute("inputmode");
        String pattern = campo.getAttribute("pattern");
        if ("decimal".equalsIgnoreCase(inputmode) || (pattern != null && pattern.contains("0-9"))) {
            return true;
        }
        String name = campo.getAttribute("name");
        if (name != null) {
            String nameLower = name.toLowerCase();
            for (String token : NUMERICOS_POR_NOMBRE) {
                if (nameLower.contains(token)) {
                    return true;
                }
            }
        }
        return false;
    }

    private String numero2Digitos() {
        return String.valueOf(RANDOM.nextInt(99) + 1); // 1..99
    }

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

    private void esperar(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
