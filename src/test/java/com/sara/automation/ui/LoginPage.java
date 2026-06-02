package com.sara.automation.ui;

import net.serenitybdd.screenplay.targets.Target;
import org.openqa.selenium.By;

public class LoginPage {

    // Generic locators for compatibility
    public static final Target USERNAME = Target.the("Campo de usuario")
            .located(By.cssSelector("input[name='username'], input[id='username'], input[name='email'], input[type='email']"));

    public static final Target PASSWORD = Target.the("Campo de contraseña")
            .located(By.cssSelector("input[name='password'], input[type='password']"));

    public static final Target LOGIN_BUTTON = Target.the("Botón de inicio de sesión")
            .located(By.cssSelector("button[type='submit'], input[type='submit'], button[id*='login'], button[class*='login']"));

    // Cognito specific locators
    public static final String COGNITO_LOGIN_URL = "https://us-east-1s66ymlwwk.auth.us-east-1.amazoncognito.com/login?client_id=2hfo5293cfbh1h9fbe9m7g07dn&response_type=code&scope=email+openid+profile&redirect_uri=https%3A%2F%2Fasistenciaapp.kit.sura-konecta.com%2Fauth";

    public static final Target COGNITO_USERNAME = Target.the("Campo de usuario de Cognito")
            .located(By.cssSelector("input[name='username']"));

    public static final Target COGNITO_NEXT_BUTTON = Target.the("Botón siguiente de Cognito")
            .located(By.cssSelector("button[type='submit']"));

    public static final Target COGNITO_PASSWORD = Target.the("Campo de contraseña de Cognito")
            .located(By.cssSelector("input[name='password']"));

    public static final Target COGNITO_CONTINUE_BUTTON = Target.the("Botón continuar de Cognito")
            .located(By.cssSelector("button[type='submit']"));

    private LoginPage() {}
}

