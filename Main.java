package com.outdoorsports;

import com.embabel.agent.shell.EnableAgentShell;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main.java
 *
 * Spring Boot entry point for the Outdoor Sports Agent application.
 *
 * ── @SpringBootApplication ────────────────────────────────────────────────
 *    Enables component scanning, auto-configuration, and property loading.
 *    All classes in the com.outdoorsports package (and sub-packages) are
 *    automatically discovered, including:
 *      • OutdoorSportsAgent   (@Agent → registered with AgentPlatform)
 *      • EnvironmentalActionService (@Service → injected into the agent)
 *
 * ── @EnableAgentShell ─────────────────────────────────────────────────────
 *    Activates the Embabel Spring Shell integration, which provides
 *    interactive commands in the terminal:
 *
 *      execute "<natural language instruction>"
 *          Embabel classifies the intent, selects OutdoorSportsAgent,
 *          formulates a GOAP plan, and runs all @Action methods in order.
 *
 *      chat "<message>"
 *          Interactive multi-turn conversation mode.
 *
 *      help
 *          Lists all available shell commands.
 *
 * ── How the Agent is Invoked ──────────────────────────────────────────────
 *    When you type:
 *      execute "Predict cycling conditions in London, UK (51.5, -0.1) for
 *               2025-07-15T09:00"
 *
 *    Embabel will:
 *    1. Parse the natural language input into a SportsPredictionRequest
 *    2. Run OutdoorSportsAgent.fetchWeatherData()   → WeatherData
 *    3. Run OutdoorSportsAgent.analyseSportConditions() → SportConditions
 *    4. Run OutdoorSportsAgent.compileReport()      → PlayingConditionReport
 *    5. Print the result to the shell
 *
 * ── Prerequisites ─────────────────────────────────────────────────────────
 *    OPENAI_API_KEY environment variable must be set before starting:
 *      export OPENAI_API_KEY="sk-..."
 */
@SpringBootApplication
@EnableAgentShell
public class Main {

    public static void main(String[] args) {
        SpringApplication.run(Main.class, args);
    }
}
