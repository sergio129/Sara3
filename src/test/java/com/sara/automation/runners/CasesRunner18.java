package com.sara.automation.runners;

import io.cucumber.junit.CucumberOptions;
import net.serenitybdd.cucumber.CucumberWithSerenity;
import org.junit.runner.RunWith;

@RunWith(CucumberWithSerenity.class)
@CucumberOptions(
        features = "src/test/resources/features/cases/open_cases.feature",
        glue = "com.sara.automation.stepdefinitions",
        tags = "@batch19",
        snippets = CucumberOptions.SnippetType.UNDERSCORE
)
public class CasesRunner18 {
    // Los usuarios se asignan ALEATORIAMENTE desde UserPoolManager
    // Asignacion intercalada: runner18 -> escenario @batch19
}
