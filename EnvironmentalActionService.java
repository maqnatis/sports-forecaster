package com.outdoorsports.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.outdoorsports.models.Models.WeatherData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

/**
 * EnvironmentalActionService.java
 *
 * Responsible for fetching real-time or forecast weather data from the
 * Open-Meteo API (https://api.open-meteo.com).
 *
 * Open-Meteo is completely free and requires no API key, making it ideal
 * for development and GitHub Codespace environments.
 *
 * The service builds a structured {@link WeatherData} record that the
 * {@link com.outdoorsports.agent.OutdoorSportsAgent} places on its blackboard
 * for the LLM to reason about in subsequent @Action methods.
 */
@Service
public class EnvironmentalActionService {

    private static final Logger log = LoggerFactory.getLogger(EnvironmentalActionService.class);

    // ── WMO Weather Code → human-readable description mapping ────────────────
    private static final Map<Integer, String> WMO_CODES = Map.ofEntries(
            Map.entry(0,  "Clear sky"),
            Map.entry(1,  "Mainly clear"),
            Map.entry(2,  "Partly cloudy"),
            Map.entry(3,  "Overcast"),
            Map.entry(45, "Foggy"),
            Map.entry(48, "Rime fog"),
            Map.entry(51, "Light drizzle"),
            Map.entry(53, "Moderate drizzle"),
            Map.entry(55, "Dense drizzle"),
            Map.entry(61, "Slight rain"),
            Map.entry(63, "Moderate rain"),
            Map.entry(65, "Heavy rain"),
            Map.entry(71, "Slight snow"),
            Map.entry(73, "Moderate snow"),
            Map.entry(75, "Heavy snow"),
            Map.entry(77, "Snow grains"),
            Map.entry(80, "Slight showers"),
            Map.entry(81, "Moderate showers"),
            Map.entry(82, "Violent showers"),
            Map.entry(85, "Slight snow showers"),
            Map.entry(86, "Heavy snow showers"),
            Map.entry(95, "Thunderstorm"),
            Map.entry(96, "Thunderstorm with slight hail"),
            Map.entry(99, "Thunderstorm with heavy hail")
    );

    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    /**
     * @param baseUrl injected from application.properties → weather.api.base-url
     */
    public EnvironmentalActionService(
            @Value("${weather.api.base-url:https://api.open-meteo.com/v1/forecast}") String baseUrl,
            ObjectMapper objectMapper) {
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Accept", "application/json")
                .build();
        this.objectMapper = objectMapper;
        log.info("EnvironmentalActionService initialised with base URL: {}", baseUrl);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Public API
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Fetch weather data for the given coordinates and desired datetime.
     *
     * If {@code targetDateTime} is within the next 7 days, Open-Meteo returns
     * a proper hourly forecast. For times in the past it falls back to the
     * current conditions as a best-effort approximation.
     *
     * @param latitude     WGS-84 latitude
     * @param longitude    WGS-84 longitude
     * @param targetDateTime  the date/time the user wants to play sports
     * @return             a populated {@link WeatherData} record
     */
    public WeatherData fetchWeather(double latitude, double longitude, LocalDateTime targetDateTime) {
        log.info("Fetching weather for lat={}, lon={}, dateTime={}", latitude, longitude, targetDateTime);

        try {
            String responseBody = restClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .queryParam("latitude",                   latitude)
                            .queryParam("longitude",                  longitude)
                            .queryParam("hourly",
                                    "temperature_2m",
                                    "apparent_temperature",
                                    "precipitation_probability",
                                    "precipitation",
                                    "weathercode",
                                    "cloudcover",
                                    "visibility",
                                    "windspeed_10m",
                                    "windgusts_10m",
                                    "relativehumidity_2m",
                                    "uv_index",
                                    "is_day")
                            .queryParam("forecast_days", 7)
                            .queryParam("timezone", "auto")
                            .build())
                    .retrieve()
                    .body(String.class);

            return parseWeatherResponse(responseBody, targetDateTime);

        } catch (Exception ex) {
            log.warn("Failed to fetch weather from Open-Meteo ({}). Using synthetic fallback data.", ex.getMessage());
            return buildFallbackWeatherData(targetDateTime);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Parse the hourly JSON response and extract the slot closest to targetDateTime.
     */
    private WeatherData parseWeatherResponse(String json, LocalDateTime targetDateTime) throws Exception {
        JsonNode root  = objectMapper.readTree(json);
        JsonNode hourly = root.path("hourly");

        // Find the index of the hour closest to targetDateTime
        JsonNode times = hourly.path("time");
        int bestIndex = 0;
        long minDelta = Long.MAX_VALUE;
        for (int i = 0; i < times.size(); i++) {
            LocalDateTime slotTime = LocalDateTime.parse(
                    times.get(i).asText(), DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            long delta = Math.abs(java.time.Duration.between(slotTime, targetDateTime).toMinutes());
            if (delta < minDelta) {
                minDelta = delta;
                bestIndex = i;
            }
        }

        int idx = bestIndex;
        int wmoCode = hourly.path("weathercode").get(idx).asInt(0);

        return new WeatherData(
                hourly.path("temperature_2m").get(idx).asDouble(20.0),
                hourly.path("apparent_temperature").get(idx).asDouble(20.0),
                hourly.path("windspeed_10m").get(idx).asDouble(0.0),
                hourly.path("windgusts_10m").get(idx).asDouble(0.0),
                hourly.path("precipitation").get(idx).asDouble(0.0),
                hourly.path("precipitation_probability").get(idx).asInt(0),
                hourly.path("relativehumidity_2m").get(idx).asInt(50),
                hourly.path("uv_index").get(idx).asDouble(3.0),
                hourly.path("cloudcover").get(idx).asInt(20),
                wmoCode,
                WMO_CODES.getOrDefault(wmoCode, "Unknown conditions"),
                hourly.path("visibility").get(idx).asDouble(10000.0),
                hourly.path("is_day").get(idx).asInt(1) == 1
        );
    }

    /**
     * Synthetic weather data used when the API call fails (e.g. no network in some Codespace tiers).
     * Returns mild, pleasant conditions so the agent can still demonstrate its full flow.
     */
    private WeatherData buildFallbackWeatherData(LocalDateTime dateTime) {
        boolean isDaytime = dateTime.getHour() >= 6 && dateTime.getHour() < 20;
        return new WeatherData(
                22.0,     // temperatureCelsius
                21.0,     // feelsLikeCelsius
                15.0,     // windSpeedKmh
                20.0,     // windGustKmh
                0.0,      // precipitationMm
                10,       // precipitationProbPct
                55,       // relativeHumidityPct
                5.0,      // uvIndex
                20,       // cloudCoverPct
                1,        // weatherCode (mainly clear)
                "Mainly clear (synthetic fallback)",
                10000.0,  // visibilityMeters
                isDaytime
        );
    }

    /**
     * Utility: describe weather suitability for logging / shell output.
     */
    public String describeConditionsBriefly(WeatherData w) {
        return String.format(
                "%.1f°C, wind %.0f km/h, precip %.1f mm (%d%% chance), UV %.1f – %s",
                w.temperatureCelsius(), w.windSpeedKmh(), w.precipitationMm(),
                w.precipitationProbPct(), w.uvIndex(), w.weatherDescription());
    }
}
