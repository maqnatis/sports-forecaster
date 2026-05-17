package com.outdoorsports.models;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Models.java
 *
 * Contains all domain record types used across the Outdoor Sports Agent.
 * Java 21 records serve as Embabel's typed domain objects – they flow
 * between @Action methods on the agent "blackboard" and are used as
 * strongly-typed prompts and LLM response targets.
 *
 * Record hierarchy:
 *   SportsPredictionRequest   – user input
 *       └─► WeatherData       – fetched from Open-Meteo
 *       └─► SportConditions   – LLM-generated assessment
 *           └─► PlayingConditionReport  – final goal output
 */
public final class Models {

    // ─────────────────────────────────────────────────────────────────────────
    // 1. USER INPUT – what the user provides to start a prediction
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * The initial request from the user.
     * This record is the starting "input" object on Embabel's blackboard.
     *
     * @param sportsType   e.g. "football", "cycling", "tennis", "trail running"
     * @param location     human-readable location e.g. "Paris, France"
     * @param latitude     geographic latitude (-90 to 90)
     * @param longitude    geographic longitude (-180 to 180)
     * @param dateTime     the desired date/time to predict conditions for
     */
    public record SportsPredictionRequest(
            @JsonProperty("sportsType")  String sportsType,
            @JsonProperty("location")    String location,
            @JsonProperty("latitude")    double latitude,
            @JsonProperty("longitude")   double longitude,
            @JsonProperty("dateTime")    LocalDateTime dateTime
    ) {}

    // ─────────────────────────────────────────────────────────────────────────
    // 2. WEATHER DATA – fetched from Open-Meteo API
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Snapshot of current or forecasted weather at the requested location/time.
     * Populated by the EnvironmentalActionService and placed on the blackboard
     * so the LLM can reason about it in the next action.
     *
     * @param temperatureCelsius    air temperature in °C
     * @param feelsLikeCelsius      apparent/feels-like temperature in °C
     * @param windSpeedKmh          wind speed in km/h
     * @param windGustKmh           wind gust speed in km/h
     * @param precipitationMm       precipitation amount in mm
     * @param precipitationProbPct  probability of precipitation (0–100)
     * @param relativeHumidityPct   relative humidity (0–100)
     * @param uvIndex               UV index (0–11+)
     * @param cloudCoverPct         cloud cover percentage (0–100)
     * @param weatherCode           WMO weather interpretation code
     * @param weatherDescription    human-readable weather description
     * @param visibilityMeters      visibility in meters
     * @param isDay                 true if daylight hours, false if night
     */
    public record WeatherData(
            @JsonProperty("temperatureCelsius")   double temperatureCelsius,
            @JsonProperty("feelsLikeCelsius")     double feelsLikeCelsius,
            @JsonProperty("windSpeedKmh")         double windSpeedKmh,
            @JsonProperty("windGustKmh")          double windGustKmh,
            @JsonProperty("precipitationMm")      double precipitationMm,
            @JsonProperty("precipitationProbPct") int    precipitationProbPct,
            @JsonProperty("relativeHumidityPct")  int    relativeHumidityPct,
            @JsonProperty("uvIndex")              double uvIndex,
            @JsonProperty("cloudCoverPct")        int    cloudCoverPct,
            @JsonProperty("weatherCode")          int    weatherCode,
            @JsonProperty("weatherDescription")   String weatherDescription,
            @JsonProperty("visibilityMeters")     double visibilityMeters,
            @JsonProperty("isDay")                boolean isDay
    ) {}

    // ─────────────────────────────────────────────────────────────────────────
    // 3. SPORT CONDITIONS – LLM analysis intermediate step
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * The LLM's structured sport-specific condition analysis.
     * The agent produces this as an intermediate blackboard object before
     * assembling the final report.
     *
     * @param overallRating          "EXCELLENT" | "GOOD" | "FAIR" | "POOR" | "DANGEROUS"
     * @param safetyScore            1–10 (10 = perfectly safe)
     * @param comfortScore           1–10 (10 = perfectly comfortable)
     * @param performanceScore       1–10 (10 = optimal performance conditions)
     * @param keyRisks               list of identified risk factors
     * @param positiveFactors        list of favourable environmental factors
     * @param sportSpecificInsights  sport-specific observations
     * @param recommendedGear        suggested equipment or clothing adjustments
     */
    public record SportConditions(
            @JsonProperty("overallRating")         String       overallRating,
            @JsonProperty("safetyScore")           int          safetyScore,
            @JsonProperty("comfortScore")          int          comfortScore,
            @JsonProperty("performanceScore")      int          performanceScore,
            @JsonProperty("keyRisks")              List<String> keyRisks,
            @JsonProperty("positiveFactors")       List<String> positiveFactors,
            @JsonProperty("sportSpecificInsights") String       sportSpecificInsights,
            @JsonProperty("recommendedGear")       List<String> recommendedGear
    ) {}

    // ─────────────────────────────────────────────────────────────────────────
    // 4. PLAYING CONDITION REPORT – the final goal object
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * The fully assembled playing-condition prediction report.
     * Embabel's GOAP planner marks success when this type appears on the
     * blackboard (annotated with @AchievesGoal in the agent).
     *
     * @param request              the original user request (for context)
     * @param weather              the fetched weather snapshot
     * @param conditions           the structured sport condition analysis
     * @param executiveSummary     1–2 sentence plain-English verdict
     * @param detailedRecommendation full recommendation narrative
     * @param alternativeDateTime  suggestion for a better time if conditions are poor
     * @param generatedAt          timestamp when this report was produced
     */
    public record PlayingConditionReport(
            @JsonProperty("request")                 SportsPredictionRequest request,
            @JsonProperty("weather")                 WeatherData             weather,
            @JsonProperty("conditions")              SportConditions         conditions,
            @JsonProperty("executiveSummary")        String                  executiveSummary,
            @JsonProperty("detailedRecommendation")  String                  detailedRecommendation,
            @JsonProperty("alternativeDateTime")     String                  alternativeDateTime,
            @JsonProperty("generatedAt")             LocalDateTime           generatedAt
    ) {}

    // Prevent instantiation – this is a namespace class only.
    private Models() {}
}
