package com.outdoorsports.agent;

import com.embabel.agent.api.annotation.*;
import com.embabel.agent.api.annotation.support.AgentCapabilities;
import com.embabel.agent.api.common.OperationContext;
import com.outdoorsports.models.Models.*;
import com.outdoorsports.service.EnvironmentalActionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * OutdoorSportsAgent.java
 *
 * The core Embabel agent that predicts playing conditions for outdoor sports.
 *
 * ┌──────────────────────────────────────────────────────────────────┐
 * │  EMBABEL CONCEPTS IN USE                                         │
 * │  ────────────────────────────────────────────────────────────── │
 * │  @Agent      – marks this Spring bean as an Embabel agent        │
 * │  @Action     – individual capability step; the GOAP planner      │
 * │                sequences these automatically based on I/O types  │
 * │  @AchievesGoal – signals the final output type; the planner      │
 * │                  stops when this type appears on the blackboard  │
 * │  OperationContext – handle for calling the LLM (promptForObject) │
 * └──────────────────────────────────────────────────────────────────┘
 *
 * DATA FLOW (GOAP-planned, not hardcoded):
 *   SportsPredictionRequest  →  [fetchWeatherData]  →  WeatherData
 *   WeatherData              →  [analyseSportConditions]  →  SportConditions
 *   SportConditions + Request →  [compileReport]  →  PlayingConditionReport ✓GOAL
 */
@Agent(
        name        = "OutdoorSportsAgent",
        description = "Predicts playing conditions for outdoor sports based on real-time "
                    + "weather data, location, datetime, and sport-specific requirements. "
                    + "Provide a sports type (e.g. football, cycling, tennis), a location, "
                    + "coordinates, and a desired datetime."
)
@Component
public class OutdoorSportsAgent {

    private static final Logger log = LoggerFactory.getLogger(OutdoorSportsAgent.class);
    private static final DateTimeFormatter DT_FMT =
            DateTimeFormatter.ofPattern("EEEE, d MMMM yyyy 'at' HH:mm");

    private final EnvironmentalActionService weatherService;

    public OutdoorSportsAgent(EnvironmentalActionService weatherService) {
        this.weatherService = weatherService;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ACTION 1 – Fetch real weather data for the requested location / time
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Retrieves weather from Open-Meteo for the coordinates and datetime in
     * the request. This is a deterministic (non-LLM) action that calls the
     * EnvironmentalActionService.
     *
     * Input:  SportsPredictionRequest  (already on blackboard from user input)
     * Output: WeatherData              (placed on blackboard; enables next action)
     */
    @Action(
            description = "Fetch current or forecast weather data for the requested "
                        + "location and datetime from the Open-Meteo API.",
            pre         = "SportsPredictionRequest is available",
            post        = "WeatherData is available on the blackboard"
    )
    public WeatherData fetchWeatherData(SportsPredictionRequest request) {
        log.info("[Action 1] Fetching weather for '{}' at ({}, {}) on {}",
                request.location(), request.latitude(), request.longitude(),
                request.dateTime().format(DT_FMT));

        WeatherData weather = weatherService.fetchWeather(
                request.latitude(), request.longitude(), request.dateTime());

        log.info("[Action 1] Weather received: {}", weatherService.describeConditionsBriefly(weather));
        return weather;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ACTION 2 – LLM analyses weather vs. sport-specific requirements
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Uses the configured LLM (gpt-4o-mini) to assess the fetched weather
     * data against the requirements of the requested sport.
     *
     * The prompt gives the LLM full weather context and sport type, asking
     * it to produce a structured {@link SportConditions} JSON.
     *
     * Embabel's OperationContext.promptForObject() handles:
     *   • prompt construction with the supplied text
     *   • LLM invocation
     *   • JSON deserialisation back into SportConditions record
     *
     * Input:  WeatherData + SportsPredictionRequest  (both on blackboard)
     * Output: SportConditions                        (placed on blackboard)
     */
    @Action(
            description = "Use an LLM to analyse weather data against the specific "
                        + "requirements of the requested outdoor sport and produce a "
                        + "structured conditions assessment.",
            pre         = "WeatherData is available",
            post        = "SportConditions assessment is available on the blackboard"
    )
    public SportConditions analyseSportConditions(
            WeatherData weather,
            SportsPredictionRequest request,
            OperationContext ctx) {

        log.info("[Action 2] LLM analysing conditions for '{}' sport", request.sportsType());

        String prompt = buildConditionsAnalysisPrompt(request, weather);
        SportConditions conditions = ctx.promptForObject(prompt, SportConditions.class);

        log.info("[Action 2] Analysis complete – overall rating: {}, safety: {}/10",
                conditions.overallRating(), conditions.safetyScore());
        return conditions;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ACTION 3 – Compile final report (ACHIEVES GOAL)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Assembles the final PlayingConditionReport from all blackboard objects
     * and generates the executive summary + full recommendation via LLM.
     *
     * The @AchievesGoal annotation tells Embabel's GOAP planner that when
     * this action completes and returns a PlayingConditionReport, the goal
     * is satisfied and the agent execution finishes.
     *
     * Input:  SportConditions + WeatherData + SportsPredictionRequest
     * Output: PlayingConditionReport ← GOAL ACHIEVED
     */
    @Action(
            description = "Compile the final playing-condition prediction report, "
                        + "combining the weather data and condition analysis into a "
                        + "human-readable recommendation."
    )
    @AchievesGoal(description = "A complete PlayingConditionReport has been produced "
                              + "with an executive summary and full recommendation.")
    public PlayingConditionReport compileReport(
            SportConditions conditions,
            WeatherData weather,
            SportsPredictionRequest request,
            OperationContext ctx) {

        log.info("[Action 3] Compiling final report for '{}' in '{}'",
                request.sportsType(), request.location());

        String summaryPrompt = buildSummaryPrompt(request, weather, conditions);
        String executiveSummary = ctx.promptForObject(summaryPrompt, String.class);

        String recommendationPrompt = buildRecommendationPrompt(request, weather, conditions);
        String detailedRecommendation = ctx.promptForObject(recommendationPrompt, String.class);

        String alternativePrompt = buildAlternativeTimeSuggestionPrompt(request, conditions);
        String alternativeDateTime = ctx.promptForObject(alternativePrompt, String.class);

        PlayingConditionReport report = new PlayingConditionReport(
                request,
                weather,
                conditions,
                executiveSummary,
                detailedRecommendation,
                alternativeDateTime,
                LocalDateTime.now()
        );

        log.info("[Action 3] Report compiled – verdict: {}", conditions.overallRating());
        return report;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Prompt builders (keep prompts close to the actions that use them)
    // ─────────────────────────────────────────────────────────────────────────

    private String buildConditionsAnalysisPrompt(SportsPredictionRequest req, WeatherData w) {
        return """
                You are an expert outdoor sports physiologist and meteorologist.
                Analyse the following weather conditions for %s in %s on %s.

                WEATHER CONDITIONS:
                - Temperature:          %.1f°C (feels like %.1f°C)
                - Wind Speed:           %.1f km/h (gusts up to %.1f km/h)
                - Precipitation:        %.1f mm (%.0f%% probability)
                - Humidity:             %d%%
                - UV Index:             %.1f
                - Cloud Cover:          %d%%
                - Visibility:           %.0f metres
                - Weather Description:  %s
                - Daytime:              %s

                Evaluate the conditions specifically for %s. Consider:
                1. Safety risks (lightning, extreme heat/cold, flooding, visibility)
                2. Physical comfort and performance impact
                3. Equipment and surface conditions
                4. Sport-specific weather tolerances (e.g. cyclists tolerate wind poorly)

                Return a JSON object matching this exact schema (no markdown, raw JSON only):
                {
                  "overallRating": "EXCELLENT|GOOD|FAIR|POOR|DANGEROUS",
                  "safetyScore": <int 1-10>,
                  "comfortScore": <int 1-10>,
                  "performanceScore": <int 1-10>,
                  "keyRisks": ["<risk1>", "<risk2>"],
                  "positiveFactors": ["<factor1>", "<factor2>"],
                  "sportSpecificInsights": "<detailed sport-specific analysis>",
                  "recommendedGear": ["<gear1>", "<gear2>"]
                }
                """.formatted(
                req.sportsType(), req.location(), req.dateTime().format(DT_FMT),
                w.temperatureCelsius(), w.feelsLikeCelsius(),
                w.windSpeedKmh(), w.windGustKmh(),
                w.precipitationMm(), (double) w.precipitationProbPct(),
                w.relativeHumidityPct(), w.uvIndex(), w.cloudCoverPct(),
                w.visibilityMeters(), w.weatherDescription(),
                w.isDay() ? "Yes" : "No (night)",
                req.sportsType()
        );
    }

    private String buildSummaryPrompt(SportsPredictionRequest req, WeatherData w,
                                      SportConditions c) {
        return """
                Write a single concise sentence (max 30 words) summarising whether the conditions
                are suitable for %s in %s on %s.
                Overall rating: %s. Key risk: %s.
                Do not use markdown, just plain text.
                """.formatted(
                req.sportsType(), req.location(), req.dateTime().format(DT_FMT),
                c.overallRating(),
                c.keyRisks().isEmpty() ? "none" : c.keyRisks().get(0)
        );
    }

    private String buildRecommendationPrompt(SportsPredictionRequest req, WeatherData w,
                                              SportConditions c) {
        return """
                Write a detailed 3–4 sentence recommendation for someone planning to play %s
                in %s on %s.

                Conditions summary:
                - Rating: %s  |  Safety: %d/10  |  Comfort: %d/10  |  Performance: %d/10
                - Weather: %.1f°C, wind %.1f km/h, %s
                - Key risks: %s
                - Positive factors: %s
                - Sport insights: %s
                - Gear to bring: %s

                Include practical advice about timing, preparation, and gear.
                Write in second person ("You should…"). Plain text, no markdown.
                """.formatted(
                req.sportsType(), req.location(), req.dateTime().format(DT_FMT),
                c.overallRating(), c.safetyScore(), c.comfortScore(), c.performanceScore(),
                w.temperatureCelsius(), w.windSpeedKmh(), w.weatherDescription(),
                String.join(", ", c.keyRisks()),
                String.join(", ", c.positiveFactors()),
                c.sportSpecificInsights(),
                String.join(", ", c.recommendedGear())
        );
    }

    private String buildAlternativeTimeSuggestionPrompt(SportsPredictionRequest req,
                                                         SportConditions c) {
        if ("EXCELLENT".equals(c.overallRating()) || "GOOD".equals(c.overallRating())) {
            return "Return exactly: 'Conditions are already suitable – no alternative needed.'";
        }
        return """
                The conditions for %s in %s on %s are rated %s.
                Suggest ONE specific alternative date or time window (within the next 7 days)
                that would typically offer better conditions. Reply with a single short sentence.
                Plain text only.
                """.formatted(
                req.sportsType(), req.location(), req.dateTime().format(DT_FMT), c.overallRating()
        );
    }
}
