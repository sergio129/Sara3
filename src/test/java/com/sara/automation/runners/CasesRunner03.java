package com.sara.automation.runners;

import io.cucumber.junit.CucumberOptions;
import net.serenitybdd.cucumber.CucumberWithSerenity;
import org.junit.runner.RunWith;

@RunWith(CucumberWithSerenity.class)
@CucumberOptions(
        features = "src/test/resources/features/cases/open_cases.feature",
        glue = "com.sara.automation.stepdefinitions",
        tags = "@batch2",
        snippets = CucumberOptions.SnippetType.UNDERSCORE
)
public class CasesRunner03 {
    // Los usuarios se asignan ALEATORIAMENTE desde UserPoolManager
    // Asignacion intercalada: runner03 -> escenario @batch2
}
