package com.sara.automation.tasks;

import com.sara.automation.ui.LoginPage;
import net.serenitybdd.screenplay.Actor;
import net.serenitybdd.screenplay.Performable;
import net.serenitybdd.screenplay.Task;
import net.serenitybdd.screenplay.abilities.BrowseTheWeb;
import net.serenitybdd.screenplay.actions.Click;
import net.serenitybdd.screenplay.actions.Enter;
import net.serenitybdd.screenplay.actions.Open;
import net.serenitybdd.screenplay.waits.WaitUntil;
import net.thucydides.core.annotations.Step;
import org.hamcrest.Matchers;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.support.ui.ExpectedConditions;

import java.time.Duration;

import static net.serenitybdd.screenplay.matchers.WebElementStateMatchers.isVisible;
import static net.serenitybdd.screenplay.Tasks.instrumented;

public class LoginWithCognito implements Task {

    private final String username;
    private final String password;

    public LoginWithCognito(String username, String password) {
        this.username = username;
        this.password = password;
    }

    public static Performable with(String username, String password) {
        return instrumented(LoginWithCognito.class, username, password);
    }

    @Override
    @Step("Login con Cognito usando credenciales")
    public <T extends Actor> void performAs(T actor) {
        // 1. Abrir URL de Cognito
        actor.attemptsTo(
                Open.url(LoginPage.COGNITO_LOGIN_URL)
        );

        // 2. Llenar username y click Next
        actor.attemptsTo(
                WaitUntil.the(LoginPage.COGNITO_USERNAME, isVisible()).forNoMoreThan(10).seconds(),
                Enter.theValue(username).into(LoginPage.COGNITO_USERNAME),
                Click.on(LoginPage.COGNITO_NEXT_BUTTON)
        );

        // 3. Llenar password y click Continue
        actor.attemptsTo(
                WaitUntil.the(LoginPage.COGNITO_PASSWORD, isVisible()).forNoMoreThan(10).seconds(),
                Enter.theValue(password).into(LoginPage.COGNITO_PASSWORD),
                Click.on(LoginPage.COGNITO_CONTINUE_BUTTON)
        );

        // 4. Verificar que el login realmente fue exitoso
        verificarLoginExitoso(actor);
    }

    /**
     * Verifica que la autenticación fue exitosa.
     *
     * IMPORTANTE (evita falso positivo): la versión anterior forzaba la navegación a
     * {@code AgentPage.URL} y luego afirmaba que la URL contenía "/agent" — una tautología,
     * porque la URL la abría el propio test. Así un login fallido (credenciales inválidas,
     * error de Cognito) se reportaba como exitoso.
     *
     * Señal real de login correcto: tras enviar las credenciales, Cognito nos redirige FUERA
     * de su dominio de login. Si seguimos en {@code amazoncognito.com}, el login NO fue válido.
     * La navegación a /agent y la validación de contenido autenticado las hace el paso
     * siguiente (GoToAgentPage), que sí comprueba que "Caso Express" esté visible.
     */
    private void verificarLoginExitoso(Actor actor) {
        WebDriver driver = BrowseTheWeb.as(actor).getDriver();
        try {
            // 1) Salir de Cognito = credenciales aceptadas. Si seguimos aquí, el login falló.
            new WebDriverWait(driver, Duration.ofSeconds(20)).until(
                d -> !d.getCurrentUrl().contains("amazoncognito.com")
            );

            // 2) CRÍTICO: esperar a que termine la redirección OAuth y la app quede en su
            //    dominio. Si navegáramos a /agent mientras la app aún procesa /auth?code=...,
            //    abortaríamos el intercambio del token y la sesión quedaría sin autenticar
            //    (síntoma: el botón "Caso Express" nunca aparece en el paso siguiente).
            new WebDriverWait(driver, Duration.ofSeconds(30)).until(
                d -> d.getCurrentUrl().contains("sura-konecta.com")
                  && !d.getCurrentUrl().contains("/auth?")
                  && !d.getCurrentUrl().contains("amazoncognito.com")
            );

            // 3) Esperar a que la SPA termine de cargar antes de continuar.
            new WebDriverWait(driver, Duration.ofSeconds(20)).until(
                d -> "complete".equals(((JavascriptExecutor) d).executeScript("return document.readyState"))
            );
        } catch (TimeoutException e) {
            throw new AssertionError(
                "Login NO completado: la app no quedó autenticada/cargada tras enviar las credenciales "
                + "(credenciales inválidas, error de Cognito o redirección OAuth incompleta). "
                + "URL actual: " + driver.getCurrentUrl(), e);
        }
    }
}
