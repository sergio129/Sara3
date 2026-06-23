package com.sara.automation.stepdefinitions;

import com.sara.automation.tasks.BuscarExpediente;
import com.sara.automation.tasks.ClickCasoExpress;
import com.sara.automation.tasks.DiligenciarProveedorGestion;
import com.sara.automation.tasks.GestionConceptosProveedor;
import com.sara.automation.tasks.GoToAgentPage;
import com.sara.automation.tasks.LoginWithCognito;
import com.sara.automation.tasks.LogoutFromUserMenu;
import com.sara.automation.tasks.OpenCasesPage;
import com.sara.automation.tasks.TransicionarEstadosCaso;
import com.sara.automation.tasks.ValidarEstadoCaso;
import com.sara.automation.utils.CredentialsReader;
import com.sara.automation.utils.ExpedienteContext;
import com.sara.automation.utils.ProveedorContext;
import com.sara.automation.utils.ProveedorPoolManager;
import io.github.bonigarcia.wdm.WebDriverManager;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.Before;
import io.cucumber.java.After;
import io.cucumber.java.Scenario;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import net.serenitybdd.core.Serenity;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.abilities.BrowseTheWeb;
import net.serenitybdd.screenplay.actors.OnStage;
import net.serenitybdd.screenplay.actors.OnlineCast;
import net.thucydides.core.annotations.Managed;
import org.assertj.core.api.Assertions;
import org.openqa.selenium.WebDriver;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
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
    private String nombreEscenario;

    @Before
    public void prepararEscenario(Scenario scenario) {
        OnStage.setTheStage(new OnlineCast());
        actor = OnStage.theActorCalled("Sara");
        nombreEscenario = scenario.getName();
    }

    @After
    public void finalizarEscenario() {
        // Registrar en un archivo resumen qué proveedor quedó asignado a este escenario
        // (útil para revisar toda la corrida de carga de un vistazo).
        ProveedorPoolManager.Proveedor proveedor = ProveedorContext.getOrNull();
        if (proveedor != null) {
            registrarProveedorAsignado(nombreEscenario, proveedor);
        }

        // Liberar contextos ThreadLocal para que el siguiente escenario reciba
        // un proveedor/expediente nuevos.
        ProveedorContext.clear();
        ExpedienteContext.clear();
    }

    /** Anexa "escenario -> proveedor" a target/proveedores_asignados.txt (thread-safe). */
    private void registrarProveedorAsignado(String escenario, ProveedorPoolManager.Proveedor proveedor) {
        String linea = escenario + " -> " + proveedor.getUsuario() + " (" + proveedor.getNombreFormulario() + ")"
                + System.lineSeparator();
        synchronized (CasesStepDefinitions.class) {
            try {
                Path archivo = Paths.get("target", "proveedores_asignados.txt");
                Files.createDirectories(archivo.getParent());
                Files.write(archivo, linea.getBytes(StandardCharsets.UTF_8),
                        StandardOpenOption.CREATE, StandardOpenOption.APPEND);
            } catch (IOException e) {
                System.out.println("[CasesStepDefinitions] ⚠ No se pudo escribir el resumen de proveedor: " + e.getMessage());
            }
        }
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

        // TABLA MANDA: el NOMBRE del proveedor lo decide el feature (p.ej. 'PRUEBAS40 PRUEBAS40').
        // Derivamos su login + contraseña del pool y lo guardamos en el contexto para reloguear
        // con el MISMO proveedor (un proveedor solo gestiona sus propios expedientes).
        String nombreProveedor = requiredAnyKey(row, "Nombre del proveedor", "nombre del proveedor", "proveedor", "Nombre");
        String servicio = requiredAnyKey(row, "Servicio", "servicio", "Respuesta", "respuesta de proveedor");

        ProveedorPoolManager.Proveedor proveedor = ProveedorPoolManager.getByNombreFormulario(nombreProveedor);
        ProveedorContext.set(proveedor);
        // Dejar trazado el proveedor asignado en el reporte Serenity de ESTE escenario.
        Serenity.recordReportData()
                .withTitle("Proveedor asignado")
                .andContents(proveedor.getUsuario() + " (" + nombreProveedor + ")");

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

    @When("transicionamos los estados del caso hasta concluido")
    public void transicionamosLosEstadosDelCasoHastaConcluido() {
        // Transiciona hasta 'Concluido' y se detiene (no ejecuta 'Finalizado').
        actor.attemptsTo(TransicionarEstadosCaso.hastaConcluido());
    }

    @When("cerramos sesion del usuario")
    public void cerramosSesionDelUsuario() {
        actor.attemptsTo(LogoutFromUserMenu.now());
    }

    @When("reingresamos como el proveedor asignado")
    @When("reingresamos como proveedor PRUEBAS50")
    public void reingresamosComoProveedor() {
        // Vuelve a la URL de login (Cognito) e ingresa con el MISMO proveedor que se asignó
        // al diligenciar (ProveedorContext), luego navega a agent dejando la sesión lista.
        ProveedorPoolManager.Proveedor proveedor = ProveedorContext.get();
        actor.attemptsTo(LoginWithCognito.with(proveedor.getUsuario(), proveedor.getContrasena()));
        // Módulo de proveedor: NO tiene botón "Caso Express", así que no lo esperamos.
        actor.attemptsTo(GoToAgentPage.sinEsperarCasoExpress());
    }

    @When("buscamos el expediente guardado y abrimos su edicion")
    public void buscamosElExpedienteGuardadoYAbrimosSuEdicion() {
        // Búsqueda avanzada -> filtra por el expediente guardado -> abre su edición.
        actor.attemptsTo(BuscarExpediente.now());
    }

    @When("gestionamos los conceptos del proveedor")
    public void gestionamosLosConceptosDelProveedor() {
        // Marca 'no acepta conceptos', llena los campos numéricos habilitados y guarda.
        actor.attemptsTo(GestionConceptosProveedor.now());
    }

    @Then("Se valida que quede en estado {string}")
    public void seValidaQueQuedeEnEstado(String estado) {
        // Valida que el caso haya finalizado en el estado esperado
        actor.attemptsTo(ValidarEstadoCaso.conEstado(estado));
    }
}
