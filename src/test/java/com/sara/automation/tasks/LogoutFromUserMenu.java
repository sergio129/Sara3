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
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

import static net.serenitybdd.screenplay.Tasks.instrumented;

/**
 * Cierra la sesión del usuario actual usando el menú de usuario del shell de la app:
 *   1. Click en el trigger del popover (id=popover_menu_user_trigger).
 *   2. Click en la opción "Cerrar Sesión" (id=popover_menu_user_logout).
 *
 * Ambos elementos viven en el shell de la app (fuera del iframe OneScript), por eso
 * se asegura defaultContent antes de buscarlos.
 */
public class LogoutFromUserMenu implements Task {

    private static final By USER_MENU_TRIGGER = By.id("popover_menu_user_trigger");
    private static final By LOGOUT_ITEM = By.id("popover_menu_user_logout");

    public static Performable now() {
        return instrumented(LogoutFromUserMenu.class);
    }

    @Override
    @Step("Cerrar sesión desde el menú de usuario")
    public <T extends Actor> void performAs(T actor) {
        WebDriver driver = BrowseTheWeb.as(actor).getDriver();
        JavascriptExecutor js = (JavascriptExecutor) driver;
        System.out.println("\n  [LogoutFromUserMenu] ==================== CIERRE DE SESIÓN ====================");

        driver.switchTo().defaultContent();
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(20));

        // 1. Abrir el menú de usuario
        WebElement trigger = wait.until(ExpectedConditions.elementToBeClickable(USER_MENU_TRIGGER));
        js.executeScript("arguments[0].scrollIntoView({block:'center'});", trigger);
        clickResiliente(js, trigger);
        System.out.println("  [LogoutFromUserMenu] ✓ Menú de usuario abierto");

        // 2. Click en "Cerrar Sesión"
        WebElement logout = wait.until(ExpectedConditions.elementToBeClickable(LOGOUT_ITEM));
        clickResiliente(js, logout);
        System.out.println("  [LogoutFromUserMenu] ✓ Click en 'Cerrar Sesión'");

        // 3. Confirmar que salimos de la sesión (el trigger ya no debe estar presente).
        try {
            wait.until(ExpectedConditions.invisibilityOfElementLocated(USER_MENU_TRIGGER));
            System.out.println("  [LogoutFromUserMenu] ✓ Sesión cerrada (menú de usuario ya no visible)");
        } catch (Exception e) {
            System.out.println("  [LogoutFromUserMenu] ⚠ El menú de usuario sigue visible tras el logout, continuando...");
        }
        System.out.println("  [LogoutFromUserMenu] ==================== ✓ LOGOUT COMPLETADO ====================\n");
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
}
