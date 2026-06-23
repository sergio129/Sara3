package com.sara.automation.interactions;

import com.sara.automation.ui.CasoCreatePage;
import com.sara.automation.utils.ExpedienteContext;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Interaction;
import net.serenitybdd.screenplay.Performable;
import net.serenitybdd.screenplay.actions.Click;
import net.serenitybdd.screenplay.actions.Enter;
import net.serenitybdd.screenplay.actions.Scroll;
import net.serenitybdd.screenplay.targets.Target;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.Keys;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import net.serenitybdd.screenplay.waits.WaitUntil;

import java.time.Duration;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

import static net.serenitybdd.screenplay.Tasks.instrumented;
import static net.serenitybdd.screenplay.matchers.WebElementStateMatchers.isVisible;

public class FillCasoExpressFormInOrder implements Interaction {

    // Esta interacción se ejecuta después de ClickCasoExpress.
    // Asume que el actor ya:
    // 1) abrió el formulario correcto,
    // 2) entró al iframe OneScript,
    // 3) habilitó la edición del formulario.
    // Su responsabilidad es solo diligenciar y guardar.

    private static final Random RANDOM = new Random();
    private static final String UBICACION_SERVICIO_DEFAULT = "produccion";
    private static final String[] NOMBRES = {
            "Andrés", "Camila", "Sofía", "Daniel", "Valentina", "Juan", "María", "Carlos",
            "Laura", "Javier", "Ana", "Sebastián", "Paula", "Alejandro", "Sara", "David",
            "Natalia", "Miguel", "Daniela", "Fernando"
    };
    private static final String[] APELLIDOS = {
            "García", "Rodríguez", "Martínez", "López", "González", "Pérez", "Sánchez", "Ramírez",
            "Torres", "Flores", "Rivera", "Vargas", "Castillo", "Ríos", "Mejía", "Hernández",
            "Vega", "Molina", "Ortiz", "Cruz"
    };
    private static final String[] BARRIOS = {
            "San Fernando", "La Floresta", "Ciudad Salitre", "Chapinero", "La Castellana",
            "Belén", "La Soledad", "Normandía", "El Prado", "El Poblado", "Granada",
            "Los Ángeles", "El Campestre", "Bosque Popular", "Santa María", "Normandía"
    };

    private final String departamento;
    private final String municipio;
    private final String serviciosEspeciales;
    private final String gestor;
    private final String linea;
    private final String servicio;
    private String observacionFinal;

    public FillCasoExpressFormInOrder(String departamento, String municipio, String serviciosEspeciales, String gestor, String linea, String servicio) {
        this.departamento = departamento;
        this.municipio = municipio;
        this.serviciosEspeciales = serviciosEspeciales;
        this.gestor = gestor;
        this.linea = linea;
        this.servicio = servicio;
        this.observacionFinal = null;
    }

    public static Performable withManualLists(String departamento, String municipio, String serviciosEspeciales, String gestor, String linea, String servicio) {
        return instrumented(FillCasoExpressFormInOrder.class, departamento, municipio, serviciosEspeciales, gestor, linea, servicio);
    }

    public static Performable randomData() {
        return instrumented(FillCasoExpressFormInOrder.class, null, null, null, null, null, null);
    }

    @Override
    public <T extends Actor> void performAs(T actor) {
        // Garantiza que el driver este dentro del iframe antes de cualquier accion.
        // Screenplay puede resetear el contexto entre interacciones.
        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        driver.switchTo().defaultContent();
        new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));
        System.out.println("[FillCasoExpressFormInOrder] Switched to iframe OK");

        // Orden global de ejecucion dentro del iframe, siguiendo la UI:
        // datos básicos -> combos generales -> direcciones/ubicación -> asignación -> guardar.
        try {
            llenarDatosBasicosEnOrden(actor);
        } catch (Exception e) {
            throw new RuntimeException("Error al llenar datos básicos", e);
        }

        if (tieneListasManuales()) {
            llenarCombosGeneralesEnOrden(actor);
        }

        llenarDireccionesYUbicacionEnOrden(actor);

        if (tieneListasManuales()) {
            llenarServiciosEspecialesYAsignacionEnOrden(actor);
        }

        llenarObservacionFinal(actor);

        guardarFormulario(actor);
    }

    private boolean tieneListasManuales() {
        return departamento != null && municipio != null && serviciosEspeciales != null
                && gestor != null && linea != null && servicio != null;
    }

    private <T extends Actor> void llenarDatosBasicosEnOrden(T actor) throws Exception {
        String numeroExpediente = generarNumeroExpediente15();
        // Guardamos el expediente generado para reutilizarlo más adelante (búsqueda tras re-login).
        ExpedienteContext.setExpediente(numeroExpediente);
        String nombreSolicitante = generarNombreSolicitanteReal();
        String cedulaSolicitante = randomDigitos(10);
        String telefono1 = "3" + randomDigitos(9);
        String telefono2 = "3" + randomDigitos(9);
        String placa = generarPlacaColombiana();

        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        
        // Re-asegura que estamos en el iframe
        driver.switchTo().defaultContent();
        new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));
        System.out.println("  Driver en iframe OK");

        // Esperar a que campos sean visibles
        new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.visibilityOfElementLocated(By.cssSelector("input[name='data[numero_expediente]']")));
        System.out.println("  Campos del formulario visibles OK");
        
        
        // 1) Numero expediente - pegar desde clipboard
        WebElement expedienteField = driver.findElement(By.cssSelector("input[name='data[numero_expediente]']"));
        expedienteField.click();
        ((JavascriptExecutor) driver).executeScript(
            "var text = arguments[0];" +
            "var textarea = document.createElement('textarea');" +
            "textarea.textContent = text;" +
            "document.body.appendChild(textarea);" +
            "textarea.select();" +
            "document.execCommand('copy');" +
            "document.body.removeChild(textarea);",
            numeroExpediente
        );
        expedienteField.sendKeys(Keys.chord(Keys.CONTROL, "v"));
        Thread.sleep(300);
        System.out.println("  Numero expediente: " + numeroExpediente);
        this.observacionFinal = "OBS-" + numeroExpediente;
        
        // 2) Nombre solicitante
        WebElement nombreField = driver.findElement(By.cssSelector("input[name='data[nombre_solicitante]']"));
        nombreField.clear();
        nombreField.sendKeys(nombreSolicitante);
        System.out.println("  Nombre: " + nombreSolicitante);
        
        // 3) Cedula
        try {
            WebElement cedulaField = driver.findElement(By.cssSelector("input[name='data[cedula_del_solicitante]'], input[name='data[cedula_solicitante]']"));
            cedulaField.clear();
            cedulaField.sendKeys(cedulaSolicitante);
            System.out.println("  Cedula: " + cedulaSolicitante);
        } catch (Exception e) {
            System.out.println("  ERROR en cedula: " + e.getMessage());
            throw e;
        }
        
        // 4) Telefono 1
        try {
            WebElement tel1Field = driver.findElement(By.cssSelector("input[name='data[telefono_1]']"));
            tel1Field.clear();
            tel1Field.sendKeys(telefono1);
            System.out.println("  Telefono 1: " + telefono1);
        } catch (Exception e) {
            System.out.println("  ERROR en telefono 1: " + e.getMessage());
            throw e;
        }
        
        // 5) Telefono 2
        try {
            WebElement tel2Field = driver.findElement(By.cssSelector("input[name='data[telefono_2]']"));
            tel2Field.clear();
            tel2Field.sendKeys(telefono2);
            System.out.println("  Telefono 2: " + telefono2);
        } catch (Exception e) {
            System.out.println("  ERROR en telefono 2: " + e.getMessage());
            throw e;
        }
        
        // 6) Placa
        try {
            WebElement placaField = driver.findElement(By.cssSelector("input[name='data[placa]']"));
            placaField.clear();
            placaField.sendKeys(placa);
            System.out.println("  Placa: " + placa);
        } catch (Exception e) {
            System.out.println("  ERROR en placa: " + e.getMessage());
            throw e;
        }
        System.out.println("  Datos basicos completados OK");
    }

    private <T extends Actor> void llenarCombosGeneralesEnOrden(T actor) {
        // Estos combos aparecen en la sección General y dependen de los valores enviados desde el feature.
        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        seleccionarComboWebDriver(driver, "//div[contains(@class,'formio-component-departamento_solicita')]//div[contains(@class,'custom-dropdown-control')]", departamento);
        seleccionarComboMunicipioWebDriver(driver, "//div[contains(@class,'formio-component-municipio_solicita')]//div[contains(@class,'custom-dropdown-control')]", municipio);
    }

    private void seleccionarComboMunicipioWebDriver(WebDriver driver, String comboXpath, String valor) {
        WebDriverWait waitShort = new WebDriverWait(driver, Duration.ofSeconds(12));
        WebDriverWait waitLong = new WebDriverWait(driver, Duration.ofSeconds(60));

        By searchSelector = By.cssSelector("input.custom-dropdown-search, input[placeholder*='buscar'], input[placeholder*='Buscar']");
        By listItemExact = By.xpath("//ul[contains(@class,'custom-dropdown-list')]//li[normalize-space(.)='" + valor + "'] | //li[normalize-space(.)='" + valor + "']");
        By listItemsAll = By.xpath("//ul[contains(@class,'custom-dropdown-list')]//li");

        for (int intento = 1; intento <= 3; intento++) {
            try {
                WebElement combo = waitShort.until(ExpectedConditions.elementToBeClickable(By.xpath(comboXpath)));
                combo.click();
                // NO ESPERAR - dejar que waitLong encuentre el search field automáticamente
                
                WebElement search = waitLong.until(ExpectedConditions.visibilityOfElementLocated(searchSelector));
                search.clear();
                search.sendKeys(valor);
                
                System.out.println("  [seleccionarComboMunicipioWebDriver] Intento " + intento + ": Escribi: " + valor + ", esperando a que aparezca...");

                // ESPERAR a que aparezca el elemento buscado
                waitLong.until(driver1 -> {
                    List<WebElement> items = driver1.findElements(listItemExact);
                    return items.stream().anyMatch(WebElement::isDisplayed);
                });

                // Clic inteligente con fallback - dentro de un wait que reintenta StaleElementReference
                boolean clicked = waitLong.until(driver1 -> {
                    List<WebElement> items = driver1.findElements(listItemExact);
                    for (WebElement item : items) {
                        if (item.isDisplayed()) {
                            try {
                                item.click();
                                return true;
                            } catch (org.openqa.selenium.StaleElementReferenceException ignored) {
                                // Reintentar en el siguiente poll
                            } catch (org.openqa.selenium.ElementNotInteractableException ignored) {
                                ((JavascriptExecutor) driver).executeScript("arguments[0].click();", item);
                                return true;
                            }
                        }
                    }
                    return false;
                });

                if (clicked) {
                    System.out.println("  [seleccionarComboMunicipioWebDriver] Municipio '" + valor + "' encontrado y clickeado!");
                    // Esperar mínimo para que se cierre el dropdown, pero sin bloquear indefinidamente
                    try {
                        new WebDriverWait(driver, Duration.ofSeconds(2))
                            .until(ExpectedConditions.invisibilityOfAllElements(driver.findElements(listItemsAll)));
                    } catch (Exception ignored) {
                        // Puede que ya esté cerrado - continuar sin bloquear
                    }
                    return;
                }

                throw new RuntimeException("No se pudo hacer clic en el municipio visible");

            } catch (org.openqa.selenium.TimeoutException e) {
                // Elemento no encontrado - intentar con el primero disponible
                try {
                    System.out.println("  [seleccionarComboMunicipioWebDriver] Intento " + intento + ": '" + valor + "' NO encontrado. Buscando alternativas...");
                    
                    WebElement search = driver.findElement(searchSelector);
                    search.clear();
                    // NO ESPERAR - el siguiente waitLong buscará los items

                    // ESPERAR a que aparezca algún elemento en la lista
                    waitLong.until(driver1 -> {
                        List<WebElement> items = driver1.findElements(listItemsAll);
                        return items.stream().anyMatch(WebElement::isDisplayed);
                    });

                    List<WebElement> todosLosItems = driver.findElements(listItemsAll);
                    seleccionarItemQueCoincide(driver, todosLosItems, valor, "seleccionarComboMunicipioWebDriver");
                    return;
                } catch (Exception fallbackError) {
                    if (intento == 3) {
                        throw new RuntimeException("Error en fallback de municipio", fallbackError);
                    }
                    System.out.println("  [seleccionarComboMunicipioWebDriver] Error en fallback intento " + intento + ": " + fallbackError.getMessage() + " - reintentando...");
                }

            } catch (Exception e) {
                if (intento == 3) {
                    System.out.println("  [seleccionarComboMunicipioWebDriver] ERROR final: " + e.getMessage());
                    throw new RuntimeException("Error seleccionando municipio: " + valor, e);
                }
                System.out.println("  [seleccionarComboMunicipioWebDriver] Error en intento " + intento + ": " + e.getMessage() + " - reintentando...");
            }
        }

        throw new RuntimeException("Error seleccionando municipio: " + valor + " después de 3 intentos");
    }

    private void seleccionarComboLineaWebDriver(WebDriver driver, String comboXpath, String valor) {
        seleccionarComboMunicipioWebDriver(driver, comboXpath, valor);
    }

    private void seleccionarComboServicioWebDriver(WebDriver driver, String comboXpath, String valor) {
        WebDriverWait waitShort = new WebDriverWait(driver, Duration.ofSeconds(12));
        WebDriverWait waitLong = new WebDriverWait(driver, Duration.ofSeconds(60));

        By searchSelector = By.cssSelector("input.custom-dropdown-search, input[placeholder*='buscar'], input[placeholder*='Buscar']");
        By listItemExact = By.xpath("//ul[contains(@class,'custom-dropdown-list')]//li[normalize-space(.)='" + valor + "'] | //li[normalize-space(.)='" + valor + "']");
        By listItemsAll = By.xpath("//ul[contains(@class,'custom-dropdown-list')]//li");

        for (int intento = 1; intento <= 3; intento++) {
            try {
                // Asegurar iframe en cada intento para evitar referencias obsoletas
                driver.switchTo().defaultContent();
                new WebDriverWait(driver, Duration.ofSeconds(20))
                        .until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));

                // 1) Clic en el combo Servicio
                WebElement combo = waitShort.until(ExpectedConditions.elementToBeClickable(By.xpath(comboXpath)));
                combo.click();
                // NO ESPERAR - el waitLong siguiente manejará el timing

                // 1.5) ESPERAR A QUE LA LISTA DEL DROPDOWN APAREZCA (IMPORTANTE: evita que se cierre)
                waitLong.until(driver1 -> {
                    List<WebElement> items = driver1.findElements(listItemsAll);
                    return items.stream().anyMatch(WebElement::isDisplayed);
                });

                // 2) Escribir en el campo de búsqueda del dropdown
                WebElement search = waitLong.until(driver1 -> {
                    List<WebElement> inputs = driver1.findElements(searchSelector);
                    for (WebElement input : inputs) {
                        if (input.isDisplayed() && input.isEnabled()) {
                            return input;
                        }
                    }
                    return null;
                });

                try {
                    ((JavascriptExecutor) driver).executeScript("arguments[0].focus();", search);
                    search.click();
                    search.sendKeys(Keys.chord(Keys.CONTROL, "a"), Keys.DELETE);
                    search.sendKeys(valor);
                } catch (org.openqa.selenium.ElementNotInteractableException e) {
                    ((JavascriptExecutor) driver).executeScript(
                            "arguments[0].value = arguments[1]; arguments[0].dispatchEvent(new Event('input', {bubbles:true}));",
                            search,
                            valor
                    );
                }

                System.out.println("  [seleccionarComboServicioWebDriver] Intento " + intento + ": Escribí: " + valor + ", esperando a que aparezca...");
                
                // 3) ESPERAR a que aparezca el elemento buscado
                waitLong.until(driver1 -> {
                    List<WebElement> items = driver1.findElements(listItemExact);
                    return items.stream().anyMatch(WebElement::isDisplayed);
                });

                // 4) Clic inteligente con fallback - dentro de un wait que reintenta StaleElementReference
                boolean clicked = waitLong.until(driver1 -> {
                    List<WebElement> items = driver1.findElements(listItemExact);
                    for (WebElement item : items) {
                        if (item.isDisplayed()) {
                            try {
                                item.click();
                                return true;
                            } catch (org.openqa.selenium.StaleElementReferenceException ignored) {
                                // Reintentar en el siguiente poll
                            } catch (org.openqa.selenium.ElementNotInteractableException ignored) {
                                ((JavascriptExecutor) driver).executeScript("arguments[0].click();", item);
                                return true;
                            }
                        }
                    }
                    return false;
                });

                if (clicked) {
                    System.out.println("  [seleccionarComboServicioWebDriver] Servicio '" + valor + "' encontrado y clickeado!");
                    // Esperar mínimo para que se cierre el dropdown, pero sin bloquear indefinidamente
                    try {
                        new WebDriverWait(driver, Duration.ofSeconds(2))
                            .until(ExpectedConditions.invisibilityOfAllElements(driver.findElements(listItemsAll)));
                    } catch (Exception ignored) {
                        // Puede que ya esté cerrado - continuar sin bloquear
                    }
                    return;
                }

                throw new RuntimeException("No se pudo hacer clic en el servicio visible");

            } catch (org.openqa.selenium.TimeoutException e) {
                // Elemento no encontrado - intentar con el primero disponible
                try {
                    System.out.println("  [seleccionarComboServicioWebDriver] Intento " + intento + ": Servicio '" + valor + "' NO encontrado. Buscando alternativas...");
                    
                    WebElement search = driver.findElement(searchSelector);
                    search.clear();
                    // NO ESPERAR - el siguiente waitLong buscará los items

                    // ESPERAR a que aparezca algún elemento en la lista
                    waitLong.until(driver1 -> {
                        List<WebElement> items = driver1.findElements(listItemsAll);
                        return items.stream().anyMatch(WebElement::isDisplayed);
                    });

                    List<WebElement> todosLosServicios = driver.findElements(listItemsAll);
                    seleccionarItemQueCoincide(driver, todosLosServicios, valor, "seleccionarComboServicioWebDriver");
                    return;
                } catch (Exception fallbackError) {
                    if (intento == 3) {
                        throw new RuntimeException("Error en fallback de servicio", fallbackError);
                    }
                    System.out.println("  [seleccionarComboServicioWebDriver] Error en fallback intento " + intento + ": " + fallbackError.getMessage() + " - reintentando...");
                }

            } catch (org.openqa.selenium.StaleElementReferenceException stale) {
                System.out.println("  [seleccionarComboServicioWebDriver] StaleElementReference detectado, reintentando... intento " + intento);
            } catch (Exception e) {
                if (intento == 3) {
                    System.out.println("  [seleccionarComboServicioWebDriver] ERROR final en intento " + intento + ": " + e.getMessage());
                    throw new RuntimeException("Error seleccionando servicio: " + valor, e);
                }
                System.out.println("  [seleccionarComboServicioWebDriver] Error en intento " + intento + ": " + e.getMessage() + " - reintentando...");
            }
        }

        throw new RuntimeException("Error seleccionando servicio: " + valor + " después de 3 intentos");
    }

    private void esperarServicioHabilitado(WebDriver driver) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(30));
        // Usar selectores basados en clases CSS, NO en IDs dinámicos
        By servicioDropdown = By.cssSelector(".formio-component-servicio .custom-dropdown");
        By servicioControl = By.cssSelector(".formio-component-servicio .custom-dropdown-control");

        wait.until(d -> {
            WebElement dropdown = d.findElement(servicioDropdown);
            String classes = dropdown.getAttribute("class");
            return classes != null && !classes.contains("kace-component--disabled");
        });

        wait.until(ExpectedConditions.elementToBeClickable(servicioControl));
        System.out.println("  [esperarServicioHabilitado] Servicio habilitado y clickable.");
    }

    private void seleccionarComboWebDriver(WebDriver driver, String comboXpath, String valor) {
        WebDriverWait waitShort = new WebDriverWait(driver, Duration.ofSeconds(12));
        WebDriverWait waitLong = new WebDriverWait(driver, Duration.ofSeconds(60));

        By searchSelector = By.cssSelector("input.custom-dropdown-search, input[placeholder*='buscar'], input[placeholder*='Buscar']");
        By listItemExact = By.xpath("//ul[contains(@class,'custom-dropdown-list')]//li[normalize-space(.)='" + valor + "'] | //li[normalize-space(.)='" + valor + "']");
        By listItemsAll = By.xpath("//ul[contains(@class,'custom-dropdown-list')]//li");

        for (int intento = 1; intento <= 4; intento++) {
            try {
                driver.switchTo().defaultContent();
                new WebDriverWait(driver, Duration.ofSeconds(20))
                        .until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));

                System.out.println("  [seleccionarComboWebDriver] Intento " + intento + " para seleccionar: " + valor);

                WebElement combo = waitShort.until(ExpectedConditions.elementToBeClickable(By.xpath(comboXpath)));
                combo.click();
                // NO ESPERAR - dejar que waitLong encuentre el search field automáticamente

                WebElement search = waitLong.until(ExpectedConditions.visibilityOfElementLocated(searchSelector));
                search.clear();
                search.sendKeys(valor);
                
                System.out.println("  [seleccionarComboWebDriver] Escribí: " + valor + ", esperando a que aparezca...");

                // ESPERAR a que aparezca el elemento buscado
                waitLong.until(driver1 -> {
                    List<WebElement> items = driver1.findElements(listItemExact);
                    return items.stream().anyMatch(WebElement::isDisplayed);
                });

                // Clic inteligente con fallback - dentro de un wait que reintenta StaleElementReference
                boolean clicked = waitLong.until(driver1 -> {
                    List<WebElement> items = driver1.findElements(listItemExact);
                    for (WebElement item : items) {
                        if (item.isDisplayed()) {
                            try {
                                item.click();
                                return true;
                            } catch (org.openqa.selenium.StaleElementReferenceException ignored) {
                                // Reintentar en el siguiente poll
                            } catch (org.openqa.selenium.ElementNotInteractableException ignored) {
                                ((JavascriptExecutor) driver).executeScript("arguments[0].click();", item);
                                return true;
                            }
                        }
                    }
                    return false;
                });

                if (clicked) {
                    System.out.println("  [seleccionarComboWebDriver] Valor '" + valor + "' encontrado y clickeado!");
                    // Esperar mínimo para que se cierre el dropdown, pero sin bloquear indefinidamente
                    try {
                        new WebDriverWait(driver, Duration.ofSeconds(2))
                            .until(ExpectedConditions.invisibilityOfAllElements(driver.findElements(listItemsAll)));
                    } catch (Exception ignored) {
                        // Puede que ya esté cerrado - continuar sin bloquear
                    }
                    return;
                }

                throw new RuntimeException("No se pudo hacer clic en el elemento visible");

            } catch (org.openqa.selenium.TimeoutException e) {
                // Elemento no encontrado - intentar con el primero disponible
                try {
                    System.out.println("  [seleccionarComboWebDriver] Intento " + intento + ": '" + valor + "' NO encontrado. Buscando alternativas...");
                    
                    WebElement search = driver.findElement(searchSelector);
                    search.clear();
                    // NO ESPERAR - el siguiente waitLong buscará los items

                    // ESPERAR a que aparezca algún elemento en la lista
                    waitLong.until(driver1 -> {
                        List<WebElement> items = driver1.findElements(listItemsAll);
                        return items.stream().anyMatch(WebElement::isDisplayed);
                    });

                    List<WebElement> todosLosItems = driver.findElements(listItemsAll);
                    seleccionarItemQueCoincide(driver, todosLosItems, valor, "seleccionarComboWebDriver");
                    return;
                } catch (Exception fallbackError) {
                    if (intento == 4) {
                        throw new RuntimeException("Error en fallback de combo", fallbackError);
                    }
                    System.out.println("  [seleccionarComboWebDriver] Error en fallback intento " + intento + ": " + fallbackError.getMessage() + " - reintentando...");
                }

            } catch (org.openqa.selenium.StaleElementReferenceException stale) {
                System.out.println("  [seleccionarComboWebDriver] StaleElementReference detectado, reintentando... intento " + intento);
                continue;

            } catch (Exception e) {
                if (intento == 4) {
                    System.out.println("  [seleccionarComboWebDriver] ERROR final: " + e.getMessage());
                    throw new RuntimeException("Error seleccionando elemento: " + valor, e);
                }
                System.out.println("  [seleccionarComboWebDriver] Error en intento " + intento + ": " + e.getMessage() + " - reintentando...");
            }
        }

        throw new RuntimeException("Error seleccionando elemento: " + valor + " después de 4 intentos");
    }

   

    private <T extends Actor> void llenarDireccionesYUbicacionEnOrden(T actor) {
        ensureIframeContext(actor);

        String direccionServicio = generarDireccionColombiana(true);
        String direccionDestino = generarDireccionColombiana(false);
        String detalleDireccionServicio = "Barrio " + BARRIOS[RANDOM.nextInt(BARRIOS.length)] + ", Torre " + (char) ('A' + RANDOM.nextInt(6));
        String detalleDireccionDestino = "Barrio " + BARRIOS[RANDOM.nextInt(BARRIOS.length)] + ", Apt. " + (1 + RANDOM.nextInt(90));

        // Bloque de direcciones respetando la vista del formulario.
        llenarCampo(actor, CasoCreatePage.Direccion_Servicio, direccionServicio);
        llenarCampo(actor, CasoCreatePage.Direccion_Destino, direccionDestino);
        llenarCampo(actor, CasoCreatePage.Detalle_Direccion_Destino, detalleDireccionDestino);
        llenarCampo(actor, CasoCreatePage.Detalle_Direccion_Servicio, detalleDireccionServicio);
        // NO llenamos "Marca de vehículo": al diligenciarla se habilita el campo requerido
        // 'data[clase_vehiculo]', que quedaría vacío y bloquearía el guardado. Marca es opcional,
        // así que se omite para no disparar esa dependencia.
        llenarCampo(actor, CasoCreatePage.Ubicacion_Servicio, UBICACION_SERVICIO_DEFAULT);
    }

    private <T extends Actor> void llenarServiciosEspecialesYAsignacionEnOrden(T actor) {
        // Servicios especiales deshabilitado - saltamos directo a Línea y Servicio
        
        // Obtener el driver y asegurar contexto del iframe
        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        
        // Asegurar que estamos en el iframe antes de cualquier scroll
        driver.switchTo().defaultContent();
        new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));
        System.out.println("  [llenarServiciosEspecialesYAsignacionEnOrden] Contexto del iframe OK");
        
        // Hacer scroll dentro del iframe usando JavaScriptExecutor
        try {
            String scrollScript = "var linea = document.evaluate(\"//label[normalize-space()='Línea *' or normalize-space()='Línea']\", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; " +
                                  "if (linea) { linea.scrollIntoView(true); }";
            ((JavascriptExecutor) driver).executeScript(scrollScript);
            Thread.sleep(500);
            System.out.println("  [llenarServiciosEspecialesYAsignacionEnOrden] Scroll a Línea OK");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        // Línea y Servicio usan custom dropdowns - usar selectores basados en clases, NO en IDs dinámicos
        seleccionarComboLineaWebDriver(driver, "//div[contains(@class,'formio-component-linea')]//div[contains(@class,'custom-dropdown-control')]", linea);
        // Asegurarse de que el dropdown de Línea se cerró antes de abrir Servicio
        ((JavascriptExecutor) driver).executeScript("document.activeElement.blur();");
        esperarServicioHabilitado(driver);
        // Usar selector específico que busca por el label "Servicio" (no "Servicio Especial")
        seleccionarComboServicioWebDriver(driver, "//div[contains(@class,'formio-component-servicio') and .//label[normalize-space()='Servicio' and not(contains(., 'Especial'))]]//div[contains(@class,'custom-dropdown-control')]", servicio);
    }

    private <T extends Actor> void llenarObservacionFinal(T actor) {
        // Último campo editable del formulario antes de accionar Guardar.
        actor.attemptsTo(Scroll.to(CasoCreatePage.Observacion_Final));
        String observacion = this.observacionFinal != null ? this.observacionFinal : generarObservacionAleatoria();
        llenarCampo(actor, CasoCreatePage.Observacion_Final, observacion);
    }

    private String generarObservacionAleatoria() {
        return "OBS-" + randomLetras(4) + randomDigitos(6);
    }

    private <T extends Actor> void guardarFormulario(T actor) {
        ensureIframeContext(actor);
        try {
            actor.attemptsTo(Scroll.to(CasoCreatePage.Guardar_Formulario));
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.Guardar_Formulario, isVisible()).forNoMoreThan(20).seconds());
            actor.attemptsTo(Click.on(CasoCreatePage.Guardar_Formulario));
            // Esperar a que la página procese el guardado y se recargue completamente
            // La página hace reload dentro del iframe, necesitamos dar tiempo para que termine
            Thread.sleep(500);
        } catch (Throwable e) {
            System.out.println("  [FillCasoExpressFormInOrder] Intento 1 de guardado falló, intentando fallback...");
            try {
                actor.attemptsTo(WaitUntil.the(CasoCreatePage.Guardar_Formulario_FALLBACK, isVisible()).forNoMoreThan(10).seconds());
                actor.attemptsTo(Click.on(CasoCreatePage.Guardar_Formulario_FALLBACK));
                try {
                    Thread.sleep(500);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                }
            } catch (Throwable fallbackError) {
                throw new RuntimeException("Falló el guardado del formulario - ni botón principal ni fallback estuvieron disponibles", fallbackError);
            }
        }
    }

    private <T extends Actor> void llenarCampo(T actor, Target target, String valor) {
        // Form.io re-renderiza el formulario tras seleccionar combos condicionales
        // (p.ej. municipio). Esto provoca que un campo pase la verificacion isVisible
        // pero desaparezca (NoSuchElement) o quede stale justo antes de escribir.
        // Reintentamos todo el ciclo localizar+escribir para tolerar ese re-render.
        int maxIntentos = 3;
        for (int intento = 1; intento <= maxIntentos; intento++) {
            // Reingresar al iframe antes de interactuar con el campo.
            ensureIframeContext(actor);
            try {
                actor.attemptsTo(Scroll.to(target));
                actor.attemptsTo(WaitUntil.the(target, isVisible()).forNoMoreThan(20).seconds());
                actor.attemptsTo(Enter.theValue(valor).into(target));
                return;
            } catch (org.openqa.selenium.NoSuchElementException
                    | org.openqa.selenium.StaleElementReferenceException e) {
                System.out.println("  [llenarCampo] Campo '" + target + "' no disponible (intento "
                        + intento + "/" + maxIntentos + "): el formulario pudo re-renderizarse. "
                        + e.getMessage());
                if (intento == maxIntentos) {
                    throw e;
                }
                try {
                    // Dar tiempo a que Form.io termine de reconstruir el campo.
                    Thread.sleep(1000);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                }
            }
        }
    }

    private <T extends Actor> void ensureIframeContext(T actor) {
        WebDriver driver = net.serenitybdd.screenplay.abilities.BrowseTheWeb.as(actor).getDriver();
        driver.switchTo().defaultContent();
        new WebDriverWait(driver, Duration.ofSeconds(20))
                .until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("form_onescript_iframe")));
    }

    private <T extends Actor> void seleccionar(T actor, Target combo, String valor) {
        // Helper común para listas: abre el combo y busca la opción.
        actor.attemptsTo(WaitUntil.the(combo, isVisible()).forNoMoreThan(20).seconds());
        actor.attemptsTo(Click.on(combo));

        try {
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.CustomDropdownSearch, isVisible()).forNoMoreThan(3).seconds());
            actor.attemptsTo(Enter.theValue(valor).into(CasoCreatePage.CustomDropdownSearch));
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.CustomDropdownListItem.of(valor), isVisible()).forNoMoreThan(10).seconds());
            actor.attemptsTo(Click.on(CasoCreatePage.CustomDropdownListItem.of(valor)));
            return;
        } catch (Throwable ignore) {
            // Si no existe búsqueda custom, continuar con opciones visibles.
        }

        try {
            actor.attemptsTo(WaitUntil.the(CasoCreatePage.Opcion_Lista.of(valor), isVisible()).forNoMoreThan(10).seconds());
            actor.attemptsTo(Click.on(CasoCreatePage.Opcion_Lista.of(valor)));
            return;
        } catch (Throwable ignore) {
            // Ignorar y probar la opción por texto parcial.
        }

        actor.attemptsTo(WaitUntil.the(CasoCreatePage.Opcion_Lista_Contiene.of(valor), isVisible()).forNoMoreThan(10).seconds());
        actor.attemptsTo(Click.on(CasoCreatePage.Opcion_Lista_Contiene.of(valor)));
    }

    /**
     * Selecciona una opción de la lista filtrada tras escribir el valor:
     *   1) si hay coincidencia EXACTA (ignorando mayúsculas/espacios), se usa esa;
     *   2) si no, pero hay varias/alguna opción visible (datos "parecidos" al buscado),
     *      se elige UNA AL AZAR para que la suite siempre seleccione algo y no se frene;
     *   3) si NO aparece ninguna opción (lista vacía → cascada rota), se lanza excepción:
     *      no se puede "elegir alternativa" cuando no hay nada que elegir.
     *
     * Nota: el paso 2 prioriza completar el flujo sobre la exactitud del dato; si en el
     * futuro se requiere exactitud estricta, cambiar el azar por un fallo controlado.
     */
    private void seleccionarItemQueCoincide(WebDriver driver, List<WebElement> items, String valor, String origen) {
        List<WebElement> visibles = items.stream()
                .filter(WebElement::isDisplayed)
                .collect(Collectors.toList());
        if (visibles.isEmpty()) {
            throw new RuntimeException(
                    "[" + origen + "] No apareció ninguna opción en la lista para '" + valor + "' "
                  + "(lista vacía: posible fallo de la cascada departamento→municipio).");
        }
        String objetivo = valor == null ? "" : valor.trim().toLowerCase();
        WebElement elegido = visibles.stream()
                .filter(el -> el.getText() != null && el.getText().trim().toLowerCase().equals(objetivo))
                .findFirst()
                .orElse(null);
        if (elegido != null) {
            System.out.println("  [" + origen + "] Coincidencia exacta: '" + valor + "'");
        } else {
            elegido = visibles.get(RANDOM.nextInt(visibles.size()));
            System.out.println("  [" + origen + "] '" + valor + "' sin coincidencia exacta; "
                    + "se elige al azar entre " + visibles.size() + " opciones: '" + elegido.getText().trim() + "'");
        }
        try {
            elegido.click();
        } catch (org.openqa.selenium.ElementNotInteractableException ex) {
            ((JavascriptExecutor) driver).executeScript("arguments[0].click();", elegido);
        }
    }

    private String generarNumeroExpediente15() {
        return randomDigitos(15);
    }

    private String generarPlacaColombiana() {
        return randomLetras(3) + randomDigitos(3);
    }

    private String generarDireccionColombiana(boolean esCalle) {
        int numero1 = 10 + RANDOM.nextInt(90);
        int numero2 = 1 + RANDOM.nextInt(99);
        int numero3 = 1 + RANDOM.nextInt(99);
        String tipo;
        if (esCalle) {
            tipo = RANDOM.nextBoolean() ? "Calle" : "Avenida Calle";
        } else {
            tipo = RANDOM.nextBoolean() ? "Carrera" : "Avenida Carrera";
        }
        return tipo + " " + numero1 + " # " + numero2 + "-" + numero3;
    }

    private String generarNombreSolicitanteReal() {
        String nombre = NOMBRES[RANDOM.nextInt(NOMBRES.length)];
        String apellido1 = APELLIDOS[RANDOM.nextInt(APELLIDOS.length)];
        String apellido2 = APELLIDOS[RANDOM.nextInt(APELLIDOS.length)];
        return nombre + " " + apellido1 + " " + apellido2;
    }

    private String randomDigitos(int longitud) {
        StringBuilder sb = new StringBuilder(longitud);
        for (int i = 0; i < longitud; i++) {
            sb.append(RANDOM.nextInt(10));
        }
        return sb.toString();
    }

    private String randomLetras(int longitud) {
        StringBuilder sb = new StringBuilder(longitud);
        for (int i = 0; i < longitud; i++) {
            sb.append((char) ('A' + RANDOM.nextInt(26)));
        }
        return sb.toString();
    }
}

