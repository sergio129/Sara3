package com.sara.automation.interactions;

import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.StaleElementReferenceException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

public final class OneScriptDynamicElements {

    private OneScriptDynamicElements() {
    }

    public static void waitForProveedorSection(WebDriver driver, Duration timeout) {
        new WebDriverWait(driver, timeout).until(d -> {
            Object found = ((JavascriptExecutor) d).executeScript(
                    "const normalize = text => text.replace(/\\s+/g, ' ').trim().toLowerCase();"
                            + "const nombre = document.querySelector('#custom-select-e75nu5o .custom-dropdown-control, div.formio-component-custom-select.formio-component-nombre .custom-dropdown-control');"
                            + "const respuesta = document.querySelector('div.formio-component-custom-select.formio-component-respuesta_de_proveedor .custom-dropdown-control');"
                            + "const saveBtn = Array.from(document.querySelectorAll('button')).find(b => b.offsetParent !== null && normalize(b.textContent).includes('guardar'));"
                            + "return (nombre && respuesta) || (nombre && saveBtn) || null;"
            );
            return found != null;
        });
    }

    public static void clickVisibleButtonByText(WebDriver driver, String text) {
        Object clicked = ((JavascriptExecutor) driver).executeScript(
                "const wanted = arguments[0].toLowerCase();"
                        + "const buttons = Array.from(document.querySelectorAll('button'));"
                        + "const visible = buttons.filter(b => b.offsetParent !== null);"
                        + "const prioritized = visible.find(b => (b.getAttribute('ref') || '').toLowerCase().includes('gestion_proveedor') && b.textContent.trim().toLowerCase().includes(wanted));"
                        + "const candidate = prioritized || visible.find(b => b.textContent.trim().toLowerCase().includes(wanted));"
                        + "if (!candidate) return false;"
                        + "candidate.scrollIntoView({block:'center', inline:'nearest'});"
                        + "candidate.dispatchEvent(new MouseEvent('mousedown', {bubbles:true}));"
                        + "candidate.dispatchEvent(new MouseEvent('mouseup', {bubbles:true}));"
                        + "candidate.click();"
                        + "return true;",
                text
        );

        if (!(clicked instanceof Boolean) || !((Boolean) clicked)) {
            throw new NoSuchElementException("No se encontró botón visible con texto: " + text);
        }
    }

    public static void selectCustomDropdownByComponentClass(WebDriver driver, String componentClass, String value) {
        selectCustomDropdownByComponentClass(driver, componentClass, value, null);
    }

    /**
     * Igual que {@link #selectCustomDropdownByComponentClass(WebDriver, String, String)} pero
     * acota la búsqueda del control a un contenedor (CSS scope, p. ej. ".formio-dialog-content"),
     * para no confundir el dropdown de un modal con otro homónimo del resto de la página
     * (p. ej. el resumen del editGrid).
     */
    public static void selectCustomDropdownByComponentClass(WebDriver driver, String componentClass, String value, String scope) {
        // Espera ACTIVA del control: Form.io puede renderizar/re-renderizar el dropdown un instante
        // después de que la sección esté "lista", lo que causaba NoSuchElement intermitente.
        WebElement control = waitForDropdownControl(driver, componentClass, scope, Duration.ofSeconds(15));
        if (control == null) {
            throw new NoSuchElementException("No se encontró el dropdown control para componente: " + componentClass);
        }

        abrirDropdown(driver, componentClass, scope, control);

        // Espera ACTIVA del campo de búsqueda (en vez de un sleep fijo): retorna apenas aparece
        // (rápido si el dropdown abre rápido) y tolera hasta 5s si bajo carga abre lento,
        // garantizando que el filtrado se aplique.
        WebElement search = waitForSearchInput(driver, componentClass, scope, Duration.ofSeconds(5));
        if (search != null) {
            setInputValue(driver, search, value);
            // Sin sleep fijo: findOptionByText espera activamente a que aparezca la opción filtrada.
        }

        WebElement option = findOptionByText(driver, value);
        if (option == null) {
            throw new NoSuchElementException("No se encontró la opción del dropdown: " + value);
        }

        clickWithJs(driver, option);
        sleep(150); // breve, para que la selección asiente antes de continuar
    }

    /**
     * Abre el dropdown custom del componente indicado y selecciona la PRIMERA opción válida
     * (sin importar el texto). Útil para campos requeridos donde cualquier opción sirve
     * (p. ej. "Tipo de gestión", "Persona de gestión").
     *
     * @return el texto de la opción seleccionada.
     */
    public static String selectFirstCustomDropdownOption(WebDriver driver, String componentClass) {
        return selectFirstCustomDropdownOption(driver, componentClass, null);
    }

    /**
     * Variante con scope (CSS) para acotar el control a un contenedor (p. ej. un modal).
     * Espera ACTIVAMENTE a que la lista cargue opciones VÁLIDAS (descarta placeholders/"cargando")
     * antes de elegir la primera, ya que las opciones pueden venir de forma asíncrona del backend.
     */
    public static String selectFirstCustomDropdownOption(WebDriver driver, String componentClass, String scope) {
        WebElement control = waitForDropdownControl(driver, componentClass, scope, Duration.ofSeconds(15));
        if (control == null) {
            throw new NoSuchElementException("No se encontró el dropdown control para componente: " + componentClass);
        }
        abrirDropdown(driver, componentClass, scope, control);

        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(15));
        WebElement primera = wait.until(d -> {
            Object found = ((JavascriptExecutor) d).executeScript(
                    "const malos = ['cargando','loading','no hay','sin resultados','no results','no se encontr','elige una','seleccion'];"
                            + "const items = Array.from(document.querySelectorAll('ul.custom-dropdown-list li, div.custom-dropdown-item, div[role=\\\"option\\\"]'));"
                            + "const visible = items.filter(el => el.offsetParent !== null && el.textContent.trim().length > 0"
                            + "    && !malos.some(m => el.textContent.trim().toLowerCase().includes(m)));"
                            + "return visible.length ? visible[0] : null;");
            return found instanceof WebElement ? (WebElement) found : null;
        });
        String texto = primera.getText().trim();
        clickWithJs(driver, primera);
        sleep(150);
        return texto;
    }

    /**
     * Espera ACTIVAMENTE a que el control del dropdown exista y sea visible, reintentando ante
     * ausencia o staleness (Form.io re-renderiza). Devuelve null si no apareció en el timeout.
     */
    private static WebElement waitForDropdownControl(WebDriver driver, String componentClass, String scope, Duration timeout) {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        WebElement control = null;
        while (System.currentTimeMillis() < deadline) {
            try {
                control = getDropdownControl(driver, componentClass, scope);
                if (control != null && control.isDisplayed()) {
                    return control;
                }
            } catch (StaleElementReferenceException ignored) {
                // Re-render en curso: se reintenta.
            }
            try {
                Thread.sleep(200);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
        return control;
    }

    /**
     * Abre el dropdown clickeando su control, re-localizándolo si quedó stale tras un re-render.
     */
    private static void abrirDropdown(WebDriver driver, String componentClass, String scope, WebElement control) {
        try {
            clickWithJs(driver, control);
        } catch (StaleElementReferenceException e) {
            WebElement fresco = waitForDropdownControl(driver, componentClass, scope, Duration.ofSeconds(5));
            if (fresco == null) {
                throw new NoSuchElementException("El dropdown control quedó stale y no reapareció: " + componentClass);
            }
            clickWithJs(driver, fresco);
        }
    }

    private static WebElement getDropdownControl(WebDriver driver, String componentClass, String scope) {
        Object element = ((JavascriptExecutor) driver).executeScript(
                "const scope = arguments[1] ? (arguments[1] + ' ') : '';"
                        + "const selector = scope + 'div.formio-component-custom-select.' + arguments[0] + ' .custom-dropdown-control';"
                        + "const found = document.querySelector(selector);"
                        + "if (found) return found;"
                        + "const root = arguments[1] ? (document.querySelector(arguments[1]) || document) : document;"
                        + "const normalize = text => text.replace(/\\s+/g, ' ').trim().toLowerCase();"
                        + "const wanted = arguments[0].replace('formio-component-', '').replace(/_/g, ' ');"
                        + "const label = Array.from(root.querySelectorAll('label')).find(l => normalize(l.textContent).includes(wanted));"
                        + "if (!label) return null;"
                        + "const container = label.closest('.formio-component') || label.closest('.formio-component-custom-select') || label.parentElement;"
                        + "return container ? container.querySelector('.custom-dropdown-control') : null;",
                componentClass, scope
        );
        return element instanceof WebElement ? (WebElement) element : null;
    }

    /**
     * Espera activa del campo de búsqueda del dropdown: reintenta {@link #getSearchInput} hasta
     * que aparezca o se agote el timeout. Devuelve null si no apareció (el llamador continúa:
     * findOptionByText buscará entre las opciones visibles sin filtrar).
     */
    private static WebElement waitForSearchInput(WebDriver driver, String componentClass, String scope, Duration timeout) {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        WebElement search = getSearchInput(driver, componentClass, scope);
        while (search == null && System.currentTimeMillis() < deadline) {
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
            search = getSearchInput(driver, componentClass, scope);
        }
        return search;
    }

    private static WebElement getSearchInput(WebDriver driver, String componentClass, String scope) {
        Object element = ((JavascriptExecutor) driver).executeScript(
                "const scope = arguments[1] ? (arguments[1] + ' ') : '';"
                        + "const base = document.querySelector(scope + 'div.formio-component-custom-select.' + arguments[0]);"
                        + "if (base) {"
                        + "  const inside = base.querySelector('input.custom-dropdown-search, input[placeholder*=\\\"buscar\\\"], input[placeholder*=\\\"Buscar\\\"]');"
                        + "  if (inside) return inside;"
                        + "}"
                        + "const root = arguments[1] ? (document.querySelector(arguments[1]) || document) : document;"
                        + "const normalize = text => text.replace(/\\s+/g, ' ').trim().toLowerCase();"
                        + "const wanted = arguments[0].replace('formio-component-', '').replace(/_/g, ' ');"
                        + "const label = Array.from(root.querySelectorAll('label')).find(l => normalize(l.textContent).includes(wanted));"
                        + "if (label) { const container = label.closest('.formio-component') || label.closest('.formio-component-custom-select') || label.parentElement; if (container) { const inside = container.querySelector('input.custom-dropdown-search, input[placeholder*=\\\"buscar\\\"], input[placeholder*=\\\"Buscar\\\"]'); if (inside) return inside; } }"
                        + "const active = document.activeElement;"
                        + "if (active && active.tagName === 'INPUT') return active;"
                        + "return document.querySelector('input.custom-dropdown-search, input[placeholder*=\\\"buscar\\\"], input[placeholder*=\\\"Buscar\\\"]');",
                componentClass, scope
        );
        return element instanceof WebElement ? (WebElement) element : null;
    }

    private static WebElement findOptionByText(WebDriver driver, String value) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
        return wait.until(d -> {
            Object found = ((JavascriptExecutor) d).executeScript(
                    "const wanted = arguments[0].toLowerCase();"
                            + "const items = Array.from(document.querySelectorAll('ul.custom-dropdown-list li, div.custom-dropdown-item, div[role=\\\"option\\\"]'));"
                            + "const visible = items.filter(el => el.offsetParent !== null);"
                            + "const exact = visible.find(el => el.textContent.trim().toLowerCase() === wanted);"
                            + "if (exact) return exact;"
                            + "return visible.find(el => el.textContent.trim().toLowerCase().includes(wanted)) || null;",
                    value
            );
            return found instanceof WebElement ? (WebElement) found : null;
        });
    }

    private static void clickWithJs(WebDriver driver, WebElement element) {
        ((JavascriptExecutor) driver).executeScript(
                "arguments[0].scrollIntoView({block:'center', inline:'nearest'});"
                        + "arguments[0].dispatchEvent(new MouseEvent('mousedown', {bubbles:true}));"
                        + "arguments[0].dispatchEvent(new MouseEvent('mouseup', {bubbles:true}));"
                        + "arguments[0].click();",
                element
        );
    }

    private static void setInputValue(WebDriver driver, WebElement input, String value) {
        ((JavascriptExecutor) driver).executeScript(
                "arguments[0].focus();"
                        + "arguments[0].value = '';"
                        + "arguments[0].value = arguments[1];"
                        + "arguments[0].dispatchEvent(new Event('input', {bubbles:true}));"
                        + "arguments[0].dispatchEvent(new Event('change', {bubbles:true}));",
                input,
                value
        );
    }

    private static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
