package com.sara.automation.stepdefinitions;

import com.sara.automation.tasks.ClickCasoExpress;
import com.sara.automation.tasks.DiligenciarProveedorGestion;
import com.sara.automation.tasks.GoToAgentPage;
import com.sara.automation.tasks.LoginWithCognito;
import com.sara.automation.tasks.OpenCasesPage;
import com.sara.automation.tasks.TransicionarEstadosCaso;
import com.sara.automation.tasks.ValidarEstadoCaso;
import com.sara.automation.utils.CredentialsReader;
import io.github.bonigarcia.wdm.WebDriverManager;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.Before;
import io.cucumber.java.After;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.abilities.BrowseTheWeb;
import net.serenitybdd.screenplay.actors.OnStage;
import net.serenitybdd.screenplay.actors.OnlineCast;
import net.thucydides.core.annotations.Managed;
import org.assertj.core.api.Assertions;
import org.openqa.selenium.WebDriver;

import java.util.List;
import java.util.Map;

public class CasesStepDefinitions {

    // Resuelve el chromedriver una vez por JVM (cada fork paralelo es una JVM
    // independiente), antes de que Serenity instancie el driver @Managed.
    // - En Docker (selenium/standalone-chrome) el chromedriver ya viene
    //   preinstalado: lo usamos directamente, sin descargar por red ni arriesgar
    //   desajustes de versión con el Chrome de la imagen.
    // - En local (Windows) no hay driver: WebDriverManager lo descarga,
    //   evitando depender de Selenium Manager, que fallaba al ejecutar
    //   selenium-manager.exe.
    static {
        String[] preinstalados = {"/usr/bin/chromedriver", "/usr/local/bin/chromedriver"};
        String driverPreinstalado = null;
        for (String ruta : preinstalados) {
            if (new java.io.File(ruta).canExecute()) {
                driverPreinstalado = ruta;
                break;
            }
        }
        if (driverPreinstalado != null) {
            System.setProperty("webdriver.chrome.driver", driverPreinstalado);
        } else {
            WebDriverManager.chromedriver().setup();
        }
    }

    @Managed(driver = "chrome")
    WebDriver browser;

    private Actor actor;

    @Before
    public void prepararEscenario() {
        OnStage.setTheStage(new OnlineCast());
        actor = OnStage.theActorCalled("Sara");
    }

    @After
    public void finalizarEscenario() {
        // Limpieza de escenario
    }

    @Given("el actor tiene un navegador disponible")
    public void elActorTieneUnNavegadorDisponible() {
        actor.can(BrowseTheWeb.with(browser));
    }

    @When("abre la pagina de casos")
    public void abreLaPaginaDeCasos() {
        actor.attemptsTo(OpenCasesPage.now());
    }

    @When("realiza login con credenciales")
    public void realizaLoginConCredenciales() {
        String user = CredentialsReader.getUsuario();
        String pass = CredentialsReader.getContrasena();
        actor.attemptsTo(LoginWithCognito.with(user, pass));
    }

    @When("navega a agent")
    public void navegaAAgent() {
        actor.attemptsTo(GoToAgentPage.now());
    }

    @Then("deberia estar en la ruta cases")
    public void deberiaEstarEnLaRutaCases() {
        String currentUrl = BrowseTheWeb.as(actor).getDriver().getCurrentUrl();
        Assertions.assertThat(currentUrl).contains("konecta");
    }

    @Then("deberia ver la ruta agent")
    public void deberiaVerLaRutaAgent() {
        String currentUrl = BrowseTheWeb.as(actor).getDriver().getCurrentUrl();
        boolean isAgent = currentUrl.contains("/agent");
        boolean isSSO = currentUrl.contains("id.konecta.cloud") || currentUrl.contains("konecta-cloud");
        Assertions.assertThat(isAgent || isSSO).isTrue();
    }

    @When("diligencia caso express con datos aleatorios")
    public void diligenciaCasoExpressConDatosAleatorios() {
        // El StepDefinition no llena campos directamente.
        // Solo dispara la Task principal, que a su vez orquesta interacciones y navegación al iframe.
        actor.attemptsTo(ClickCasoExpress.now());
    }

    @When("completa listas manuales desde feature")
    public void completaListasManualesDesdeFeature(DataTable dataTable) {
        // La DataTable del feature alimenta la Task principal.
        // Esta Task abre el formulario, entra al iframe OneScript y delega el diligenciamiento
        // a la interacción FillCasoExpressFormInOrder.
        List<Map<String, String>> rows = dataTable.asMaps(String.class, String.class);
        Map<String, String> row = rows.get(0);

        actor.attemptsTo(ClickCasoExpress.withManualLists(
                required(row, "departamento_solicita"),
                required(row, "municipio_solicita"),
                row.getOrDefault("servicios_especiales", ""),
                required(row, "gestor_coordinacion"),
                required(row, "linea"),
                required(row, "servicio")
        ));
    }

    @When("diligencia caso express completo desde feature")
    public void diligenciaCasoExpressCompletoDesdeFeature(DataTable dataTable) {
        // Este step funciona como alias legible del feature.
        // Reutiliza el mismo flujo para no duplicar lógica de negocio en los steps.
        completaListasManualesDesdeFeature(dataTable);
    }

    @When("diligenciamos el proveedor")
    @When("digilenciamos el poriveedor")
    public void diligenciamosElProveedor(DataTable dataTable) {
        List<Map<String, String>> rows = dataTable.asMaps(String.class, String.class);
        Map<String, String> row = rows.get(0);

        String nombreProveedor = requiredAnyKey(row, "Nombre del proveedor", "nombre del proveedor", "proveedor", "Nombre");
        String servicio = requiredAnyKey(row, "Servicio", "servicio", "Respuesta", "respuesta de proveedor");

        actor.attemptsTo(DiligenciarProveedorGestion.conDatos(nombreProveedor, servicio));
    }

    private String required(Map<String, String> row, String key) {
        String value = row.get(key);
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Falta valor requerido en feature para: " + key);
        }
        return value.trim();
    }

    private String requiredAnyKey(Map<String, String> row, String... keys) {
        for (String key : keys) {
            for (Map.Entry<String, String> entry : row.entrySet()) {
                if (entry.getKey() != null && entry.getKey().trim().equalsIgnoreCase(key.trim())) {
                    String value = entry.getValue();
                    if (value != null && !value.trim().isEmpty()) {
                        return value.trim();
                    }
                }
            }
        }
        throw new IllegalArgumentException("Falta valor requerido en feature. Llaves esperadas: " + String.join(", ", keys));
    }

    @When("transicionamos los estados del caso")
    public void transicionamosLosEstadosDelCaso() {
        // Transiciona el caso a través de: Programado -> Aceptado y en desplazamiento -> Concluido -> Finalizado
        actor.attemptsTo(TransicionarEstadosCaso.completarSecuencia());
    }

    @Then("Se valida que quede en estado {string}")
    public void seValidaQueQuedeEnEstado(String estado) {
        // Valida que el caso haya finalizado en el estado esperado
        actor.attemptsTo(ValidarEstadoCaso.conEstado(estado));
    }
}
