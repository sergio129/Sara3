package com.sara.automation.runners;

import io.cucumber.junit.CucumberOptions;
import net.serenitybdd.cucumber.CucumberWithSerenity;
import org.junit.runner.RunWith;

@RunWith(CucumberWithSerenity.class)
@CucumberOptions(
        features = "src/test/resources/features/cases/open_cases.feature",
        glue = "com.sara.automation.stepdefinitions",
        tags = "@batch17",
        snippets = CucumberOptions.SnippetType.UNDERSCORE
)
public class CasesRunner14 {
    // Los usuarios se asignan ALEATORIAMENTE desde UserPoolManager
    // Asignacion intercalada: runner14 -> escenario @batch17
}
