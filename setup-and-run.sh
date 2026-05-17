#!/usr/bin/env bash
# =============================================================================
#  OUTDOOR SPORTS AGENT – GitHub Codespace Setup, Build & Run Script
#  ─────────────────────────────────────────────────────────────────
#  This single script:
#   1. Checks prerequisites (Java 21, Maven, OPENAI_API_KEY)
#   2. Creates the full project directory tree
#   3. Writes every source file with exact content
#   4. Initialises a Git repo and makes an initial commit
#   5. Builds the project with Maven
#   6. Runs the Spring Boot application
#
#  Usage inside a GitHub Codespace terminal:
#    chmod +x setup-and-run.sh
#    ./setup-and-run.sh
#
#  Or in one line (no pre-download needed):
#    bash <(curl -fsSL https://your-gist-url/setup-and-run.sh)
# =============================================================================

set -euo pipefail   # exit on error, unset var, or pipe failure

# ─── Colour helpers ───────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${CYAN}  $*${RESET}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }

# ─── Configuration ────────────────────────────────────────────────────────────
PROJECT_DIR="${HOME}/outdoor-sports-agent"
EMBABEL_VERSION="0.3.2"
SPRING_BOOT_VERSION="3.5.0"
SPRING_AI_VERSION="1.0.0"
JAVA_REQUIRED=21

# =============================================================================
# STEP 0 – Banner
# =============================================================================
echo -e "
${BOLD}${GREEN}
  ╔═══════════════════════════════════════════════════╗
  ║   🏃 OUTDOOR SPORTS AGENT – Codespace Setup       ║
  ║   Embabel ${EMBABEL_VERSION} · Spring Boot ${SPRING_BOOT_VERSION} · Java ${JAVA_REQUIRED}   ║
  ╚═══════════════════════════════════════════════════╝
${RESET}"

# =============================================================================
# STEP 1 – Prerequisites check
# =============================================================================
header "STEP 1 · Checking prerequisites"

# ── Java ─────────────────────────────────────────────────────────────────────
if ! command -v java &>/dev/null; then
  error "Java not found. The Codespace should have Java 21 pre-installed."
  error "Try: sudo apt-get install -y openjdk-21-jdk"
  exit 1
fi

JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
if [[ "${JAVA_VER}" -lt "${JAVA_REQUIRED}" ]]; then
  error "Java ${JAVA_REQUIRED}+ required (found ${JAVA_VER}). Update your JAVA_HOME."
  exit 1
fi
success "Java ${JAVA_VER} detected"

# ── Maven ─────────────────────────────────────────────────────────────────────
if ! command -v mvn &>/dev/null; then
  warn "Maven not found – installing via apt..."
  sudo apt-get update -q && sudo apt-get install -y -q maven
fi
MVN_VER=$(mvn -version 2>&1 | head -1)
success "Maven detected: ${MVN_VER}"

# ── Git ───────────────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  warn "Git not found – installing..."
  sudo apt-get install -y -q git
fi
success "Git detected: $(git --version)"

# ── OPENAI_API_KEY ────────────────────────────────────────────────────────────
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  warn "OPENAI_API_KEY is not set."
  warn "The agent will build and start, but LLM calls will fail at runtime."
  warn "Fix: export OPENAI_API_KEY='sk-...' then re-run, OR set it as a"
  warn "     Codespace Secret: Repo → Settings → Secrets → Codespaces."
  echo ""
  read -r -p "$(echo -e ${YELLOW}Press ENTER to continue without the key, or Ctrl+C to abort.${RESET} )" _
else
  success "OPENAI_API_KEY is set (${#OPENAI_API_KEY} chars)"
fi

# =============================================================================
# STEP 2 – Create project directory tree
# =============================================================================
header "STEP 2 · Creating project structure"

mkdir -p "${PROJECT_DIR}"/{.devcontainer,src/main/{java/com/outdoorsports/{models,agent,service},resources}}

success "Directory tree created at ${PROJECT_DIR}"

# =============================================================================
# STEP 3 – Write all source files
# =============================================================================
header "STEP 3 · Writing source files"

# ─── 3a. pom.xml ─────────────────────────────────────────────────────────────
info "Writing pom.xml ..."
cat > "${PROJECT_DIR}/pom.xml" << 'POMEOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <groupId>com.outdoorsports</groupId>
    <artifactId>outdoor-sports-agent</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    <name>Outdoor Sports Agent</name>
    <description>
        An Embabel-powered agentic application that predicts outdoor sports
        playing conditions based on weather, datetime, and location.
    </description>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.5.0</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <embabel-agent.version>0.3.2</embabel-agent.version>
        <spring-ai.version>1.0.0</spring-ai.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.ai</groupId>
                <artifactId>spring-ai-bom</artifactId>
                <version>${spring-ai.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <!-- Embabel: interactive shell starter (GOAP engine + Spring Shell) -->
        <dependency>
            <groupId>com.embabel.agent</groupId>
            <artifactId>embabel-agent-starter-shell</artifactId>
            <version>${embabel-agent.version}</version>
        </dependency>

        <!-- Embabel: OpenAI LLM provider bridge -->
        <dependency>
            <groupId>com.embabel.agent</groupId>
            <artifactId>embabel-agent-starter-openai</artifactId>
            <version>${embabel-agent.version}</version>
        </dependency>

        <!-- Spring AI: OpenAI chat auto-configuration -->
        <dependency>
            <groupId>org.springframework.ai</groupId>
            <artifactId>spring-ai-openai-spring-boot-starter</artifactId>
        </dependency>

        <!-- Spring Boot Web (RestClient for Open-Meteo weather API) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- Jackson: JSON binding for domain records -->
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.datatype</groupId>
            <artifactId>jackson-datatype-jsr310</artifactId>
        </dependency>

        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <repositories>
        <repository>
            <id>spring-milestones</id>
            <name>Spring Milestones</name>
            <url>https://repo.spring.io/milestone</url>
            <snapshots><enabled>false</enabled></snapshots>
        </repository>
    </repositories>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <mainClass>com.outdoorsports.Main</mainClass>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <source>${java.version}</source>
                    <target>${java.version}</target>
                    <compilerArgs><arg>--enable-preview</arg></compilerArgs>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <configuration>
                    <argLine>--enable-preview</argLine>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
POMEOF
success "pom.xml written"

# ─── 3b. application.properties ──────────────────────────────────────────────
info "Writing application.properties ..."
cat > "${PROJECT_DIR}/src/main/resources/application.properties" << 'PROPEOF'
# ============================================================
#  Outdoor Sports Agent – Application Properties
# ============================================================

spring.application.name=outdoor-sports-agent

# OpenAI – key injected from OPENAI_API_KEY environment variable
spring.ai.openai.api-key=${OPENAI_API_KEY:}
spring.ai.openai.chat.options.model=gpt-4o-mini
spring.ai.openai.chat.options.temperature=0.3

# Embabel
embabel.models.default-llm=gpt-4o-mini
embabel.logging.log-prompts=false
embabel.logging.log-responses=false

# Open-Meteo (free weather API – no key required)
weather.api.base-url=https://api.open-meteo.com/v1/forecast

# Spring Shell
spring.shell.interactive.enabled=true
spring.shell.command.quit.enabled=true

# Logging
logging.level.root=WARN
logging.level.com.outdoorsports=INFO
logging.level.com.embabel=INFO
PROPEOF
success "application.properties written"

# ─── 3c. Models.java ─────────────────────────────────────────────────────────
info "Writing Models.java ..."
cat > "${PROJECT_DIR}/src/main/java/com/outdoorsports/models/Models.java" << 'MODEOF'
package com.outdoorsports.models;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Models.java – all domain record types used across the Outdoor Sports Agent.
 *
 * Java 21 records act as Embabel's strongly-typed domain objects.
 * They flow between @Action methods on the agent "blackboard".
 *
 * Flow:
 *   SportsPredictionRequest  →  WeatherData  →  SportConditions
 *       →  PlayingConditionReport (GOAL)
 */
public final class Models {

    // ── 1. User Input ─────────────────────────────────────────────────────────
    public record SportsPredictionRequest(
            @JsonProperty("sportsType")  String sportsType,
            @JsonProperty("location")    String location,
            @JsonProperty("latitude")    double latitude,
            @JsonProperty("longitude")   double longitude,
            @JsonProperty("dateTime")    LocalDateTime dateTime
    ) {}

    // ── 2. Weather Data (from Open-Meteo API) ─────────────────────────────────
    public record WeatherData(
            @JsonProperty("temperatureCelsius")   double  temperatureCelsius,
            @JsonProperty("feelsLikeCelsius")     double  feelsLikeCelsius,
            @JsonProperty("windSpeedKmh")         double  windSpeedKmh,
            @JsonProperty("windGustKmh")          double  windGustKmh,
            @JsonProperty("precipitationMm")      double  precipitationMm,
            @JsonProperty("precipitationProbPct") int     precipitationProbPct,
            @JsonProperty("relativeHumidityPct")  int     relativeHumidityPct,
            @JsonProperty("uvIndex")              double  uvIndex,
            @JsonProperty("cloudCoverPct")        int     cloudCoverPct,
            @JsonProperty("weatherCode")          int     weatherCode,
            @JsonProperty("weatherDescription")   String  weatherDescription,
            @JsonProperty("visibilityMeters")     double  visibilityMeters,
            @JsonProperty("isDay")                boolean isDay
    ) {}

    // ── 3. Sport Conditions (LLM analysis) ────────────────────────────────────
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

    // ── 4. Final Report (GOAL object) ─────────────────────────────────────────
    public record PlayingConditionReport(
            @JsonProperty("request")                SportsPredictionRequest request,
            @JsonProperty("weather")                WeatherData             weather,
            @JsonProperty("conditions")             SportConditions         conditions,
            @JsonProperty("executiveSummary")       String                  executiveSummary,
            @JsonProperty("detailedRecommendation") String                  detailedRecommendation,
            @JsonProperty("alternativeDateTime")    String                  alternativeDateTime,
            @JsonProperty("generatedAt")            LocalDateTime           generatedAt
    ) {}

    private Models() {}
}
MODEOF
success "Models.java written"

# ─── 3d. EnvironmentalActionService.java ─────────────────────────────────────
info "Writing EnvironmentalActionService.java ..."
cat > "${PROJECT_DIR}/src/main/java/com/outdoorsports/service/EnvironmentalActionService.java" << 'SVCEOF'
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
 * Fetches real-time / forecast weather from Open-Meteo (free, no API key).
 * Falls back to synthetic mild weather if the API is unreachable.
 */
@Service
public class EnvironmentalActionService {

    private static final Logger log = LoggerFactory.getLogger(EnvironmentalActionService.class);

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

    public EnvironmentalActionService(
            @Value("${weather.api.base-url:https://api.open-meteo.com/v1/forecast}") String baseUrl,
            ObjectMapper objectMapper) {
        this.restClient   = RestClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Accept", "application/json")
                .build();
        this.objectMapper = objectMapper;
        log.info("EnvironmentalActionService ready – base URL: {}", baseUrl);
    }

    public WeatherData fetchWeather(double latitude, double longitude, LocalDateTime targetDateTime) {
        log.info("Fetching weather: lat={}, lon={}, time={}", latitude, longitude, targetDateTime);
        try {
            String body = restClient.get()
                    .uri(b -> b
                            .queryParam("latitude",  latitude)
                            .queryParam("longitude", longitude)
                            .queryParam("hourly",
                                    "temperature_2m", "apparent_temperature",
                                    "precipitation_probability", "precipitation",
                                    "weathercode", "cloudcover", "visibility",
                                    "windspeed_10m", "windgusts_10m",
                                    "relativehumidity_2m", "uv_index", "is_day")
                            .queryParam("forecast_days", 7)
                            .queryParam("timezone", "auto")
                            .build())
                    .retrieve()
                    .body(String.class);
            return parseWeatherResponse(body, targetDateTime);
        } catch (Exception ex) {
            log.warn("Open-Meteo unreachable ({}). Using synthetic fallback.", ex.getMessage());
            return buildFallback(targetDateTime);
        }
    }

    private WeatherData parseWeatherResponse(String json, LocalDateTime target) throws Exception {
        JsonNode hourly = objectMapper.readTree(json).path("hourly");
        JsonNode times  = hourly.path("time");

        int bestIdx = 0;
        long minDelta = Long.MAX_VALUE;
        for (int i = 0; i < times.size(); i++) {
            LocalDateTime slot = LocalDateTime.parse(
                    times.get(i).asText(), DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            long delta = Math.abs(java.time.Duration.between(slot, target).toMinutes());
            if (delta < minDelta) { minDelta = delta; bestIdx = i; }
        }

        int idx = bestIdx;
        int wmo = hourly.path("weathercode").get(idx).asInt(0);
        return new WeatherData(
                hourly.path("temperature_2m").get(idx).asDouble(20),
                hourly.path("apparent_temperature").get(idx).asDouble(20),
                hourly.path("windspeed_10m").get(idx).asDouble(0),
                hourly.path("windgusts_10m").get(idx).asDouble(0),
                hourly.path("precipitation").get(idx).asDouble(0),
                hourly.path("precipitation_probability").get(idx).asInt(0),
                hourly.path("relativehumidity_2m").get(idx).asInt(50),
                hourly.path("uv_index").get(idx).asDouble(3),
                hourly.path("cloudcover").get(idx).asInt(20),
                wmo,
                WMO_CODES.getOrDefault(wmo, "Unknown"),
                hourly.path("visibility").get(idx).asDouble(10000),
                hourly.path("is_day").get(idx).asInt(1) == 1
        );
    }

    private WeatherData buildFallback(LocalDateTime dt) {
        boolean day = dt.getHour() >= 6 && dt.getHour() < 20;
        return new WeatherData(22, 21, 15, 20, 0, 10, 55, 5, 20, 1,
                "Mainly clear (synthetic fallback)", 10000, day);
    }

    public String describeConditionsBriefly(WeatherData w) {
        return String.format("%.1f°C, wind %.0f km/h, precip %.1fmm (%d%% chance), UV %.1f – %s",
                w.temperatureCelsius(), w.windSpeedKmh(), w.precipitationMm(),
                w.precipitationProbPct(), w.uvIndex(), w.weatherDescription());
    }
}
SVCEOF
success "EnvironmentalActionService.java written"

# ─── 3e. OutdoorSportsAgent.java ─────────────────────────────────────────────
info "Writing OutdoorSportsAgent.java ..."
cat > "${PROJECT_DIR}/src/main/java/com/outdoorsports/agent/OutdoorSportsAgent.java" << 'AGENTEOF'
package com.outdoorsports.agent;

import com.embabel.agent.api.annotation.*;
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
 * Embabel agent that predicts outdoor sports playing conditions.
 *
 * GOAP Data Flow (planned automatically – not hardcoded):
 *   SportsPredictionRequest
 *       → [fetchWeatherData]         → WeatherData
 *       → [analyseSportConditions]   → SportConditions
 *       → [compileReport]            → PlayingConditionReport  ✓ GOAL
 */
@Agent(
    name        = "OutdoorSportsAgent",
    description = "Predicts playing conditions for outdoor sports based on real-time weather, "
                + "location, datetime, and sport-specific AI reasoning. Provide a sports type "
                + "(e.g. football, cycling, tennis), location name, lat/lon coordinates, "
                + "and a desired date/time."
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

    // ── ACTION 1: Fetch weather (deterministic – no LLM) ─────────────────────
    @Action(
        description = "Fetch current or forecast weather from Open-Meteo for the requested location/time.",
        pre  = "SportsPredictionRequest is available",
        post = "WeatherData is available on the blackboard"
    )
    public WeatherData fetchWeatherData(SportsPredictionRequest request) {
        log.info("[Action 1] Fetching weather for '{}' ({}, {}) on {}",
                request.location(), request.latitude(), request.longitude(),
                request.dateTime().format(DT_FMT));

        WeatherData weather = weatherService.fetchWeather(
                request.latitude(), request.longitude(), request.dateTime());
        log.info("[Action 1] Weather: {}", weatherService.describeConditionsBriefly(weather));
        return weather;
    }

    // ── ACTION 2: LLM analysis of weather vs sport requirements ──────────────
    @Action(
        description = "Use an LLM to analyse weather data against the specific requirements "
                    + "of the requested sport and produce a structured conditions assessment.",
        pre  = "WeatherData is available",
        post = "SportConditions assessment is available on the blackboard"
    )
    public SportConditions analyseSportConditions(
            WeatherData weather,
            SportsPredictionRequest request,
            OperationContext ctx) {

        log.info("[Action 2] LLM analysing '{}' conditions", request.sportsType());
        SportConditions conditions = ctx.promptForObject(
                buildConditionsPrompt(request, weather), SportConditions.class);
        log.info("[Action 2] Rating: {}, Safety: {}/10",
                conditions.overallRating(), conditions.safetyScore());
        return conditions;
    }

    // ── ACTION 3: Compile final report – GOAL ─────────────────────────────────
    @Action(description = "Compile the final playing-condition report with executive summary and recommendation.")
    @AchievesGoal(description = "A PlayingConditionReport with full recommendation has been produced.")
    public PlayingConditionReport compileReport(
            SportConditions conditions,
            WeatherData weather,
            SportsPredictionRequest request,
            OperationContext ctx) {

        log.info("[Action 3] Compiling final report for '{}' in '{}'",
                request.sportsType(), request.location());

        String summary         = ctx.promptForObject(buildSummaryPrompt(request, weather, conditions), String.class);
        String recommendation  = ctx.promptForObject(buildRecommendationPrompt(request, weather, conditions), String.class);
        String alternative     = ctx.promptForObject(buildAlternativePrompt(request, conditions), String.class);

        PlayingConditionReport report = new PlayingConditionReport(
                request, weather, conditions,
                summary, recommendation, alternative, LocalDateTime.now());

        // Pretty-print to shell
        printReport(report);
        return report;
    }

    // ── Prompt builders ───────────────────────────────────────────────────────

    private String buildConditionsPrompt(SportsPredictionRequest req, WeatherData w) {
        return """
            You are an expert outdoor sports physiologist and meteorologist.
            Analyse the weather conditions for %s in %s on %s.

            WEATHER:
            - Temperature:    %.1f°C (feels like %.1f°C)
            - Wind:           %.1f km/h (gusts %.1f km/h)
            - Precipitation:  %.1f mm (%d%% probability)
            - Humidity:       %d%%
            - UV Index:       %.1f
            - Cloud Cover:    %d%%
            - Visibility:     %.0f m
            - Conditions:     %s
            - Daytime:        %s

            Consider sport-specific tolerances, safety, comfort, and equipment.

            Respond ONLY with raw JSON (no markdown) matching:
            {
              "overallRating": "EXCELLENT|GOOD|FAIR|POOR|DANGEROUS",
              "safetyScore": <1-10>,
              "comfortScore": <1-10>,
              "performanceScore": <1-10>,
              "keyRisks": ["..."],
              "positiveFactors": ["..."],
              "sportSpecificInsights": "...",
              "recommendedGear": ["..."]
            }
            """.formatted(
                req.sportsType(), req.location(), req.dateTime().format(DT_FMT),
                w.temperatureCelsius(), w.feelsLikeCelsius(),
                w.windSpeedKmh(), w.windGustKmh(),
                w.precipitationMm(), w.precipitationProbPct(),
                w.relativeHumidityPct(), w.uvIndex(), w.cloudCoverPct(),
                w.visibilityMeters(), w.weatherDescription(),
                w.isDay() ? "Yes" : "No (night)");
    }

    private String buildSummaryPrompt(SportsPredictionRequest req, WeatherData w, SportConditions c) {
        return """
            Write ONE sentence (max 30 words) summarising whether conditions are suitable
            for %s in %s on %s. Rating: %s. Key risk: %s.
            Plain text only, no markdown.
            """.formatted(req.sportsType(), req.location(), req.dateTime().format(DT_FMT),
                c.overallRating(), c.keyRisks().isEmpty() ? "none" : c.keyRisks().get(0));
    }

    private String buildRecommendationPrompt(SportsPredictionRequest req, WeatherData w, SportConditions c) {
        return """
            Write a 3-4 sentence recommendation for someone planning to play %s in %s on %s.
            Rating: %s | Safety: %d/10 | Comfort: %d/10 | Performance: %d/10
            Weather: %.1f°C, wind %.1f km/h, %s
            Risks: %s | Positive: %s
            Gear: %s
            Write in second person. Plain text, no markdown.
            """.formatted(
                req.sportsType(), req.location(), req.dateTime().format(DT_FMT),
                c.overallRating(), c.safetyScore(), c.comfortScore(), c.performanceScore(),
                w.temperatureCelsius(), w.windSpeedKmh(), w.weatherDescription(),
                String.join(", ", c.keyRisks()),
                String.join(", ", c.positiveFactors()),
                String.join(", ", c.recommendedGear()));
    }

    private String buildAlternativePrompt(SportsPredictionRequest req, SportConditions c) {
        if ("EXCELLENT".equals(c.overallRating()) || "GOOD".equals(c.overallRating())) {
            return "Return exactly: Conditions are already suitable – no alternative needed.";
        }
        return """
            Conditions for %s in %s on %s are rated %s.
            Suggest ONE better time window within the next 7 days in one short sentence. Plain text only.
            """.formatted(req.sportsType(), req.location(),
                req.dateTime().format(DT_FMT), c.overallRating());
    }

    // ── Report printer ────────────────────────────────────────────────────────
    private void printReport(PlayingConditionReport r) {
        SportConditions c = r.conditions();
        WeatherData     w = r.weather();

        String ratingColour = switch (c.overallRating()) {
            case "EXCELLENT" -> "\033[1;32m";
            case "GOOD"      -> "\033[0;32m";
            case "FAIR"      -> "\033[0;33m";
            case "POOR"      -> "\033[0;31m";
            default          -> "\033[1;31m"; // DANGEROUS
        };
        String reset = "\033[0m";

        System.out.println("\n" + "═".repeat(60));
        System.out.printf("  🏃 OUTDOOR SPORTS CONDITION REPORT%n");
        System.out.println("═".repeat(60));
        System.out.printf("  Sport    : %s%n", r.request().sportsType());
        System.out.printf("  Location : %s%n", r.request().location());
        System.out.printf("  DateTime : %s%n", r.request().dateTime().format(DT_FMT));
        System.out.printf("  Rating   : %s%s%s%n", ratingColour, c.overallRating(), reset);
        System.out.println("─".repeat(60));
        System.out.printf("  🌡  %.1f°C  💨 %.0f km/h  🌧 %.1fmm  ☁ %d%%  UV %.1f%n",
                w.temperatureCelsius(), w.windSpeedKmh(),
                w.precipitationMm(), w.cloudCoverPct(), w.uvIndex());
        System.out.printf("  Scores → Safety: %d/10  Comfort: %d/10  Performance: %d/10%n",
                c.safetyScore(), c.comfortScore(), c.performanceScore());
        System.out.println("─".repeat(60));
        System.out.println("  VERDICT:");
        System.out.println("  " + r.executiveSummary());
        System.out.println("─".repeat(60));
        System.out.println("  RECOMMENDATION:");
        System.out.println("  " + r.detailedRecommendation().replace("\n", "\n  "));
        if (!r.alternativeDateTime().contains("already suitable")) {
            System.out.println("─".repeat(60));
            System.out.println("  ALTERNATIVE TIME:");
            System.out.println("  " + r.alternativeDateTime());
        }
        if (!c.recommendedGear().isEmpty()) {
            System.out.println("─".repeat(60));
            System.out.println("  RECOMMENDED GEAR:");
            c.recommendedGear().forEach(g -> System.out.println("    ✓ " + g));
        }
        if (!c.keyRisks().isEmpty()) {
            System.out.println("─".repeat(60));
            System.out.println("  KEY RISKS:");
            c.keyRisks().forEach(rk -> System.out.println("    ⚠ " + rk));
        }
        System.out.println("═".repeat(60) + "\n");
    }
}
AGENTEOF
success "OutdoorSportsAgent.java written"

# ─── 3f. Main.java ────────────────────────────────────────────────────────────
info "Writing Main.java ..."
cat > "${PROJECT_DIR}/src/main/java/com/outdoorsports/Main.java" << 'MAINEOF'
package com.outdoorsports;

import com.embabel.agent.shell.EnableAgentShell;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main.java – Spring Boot entry point.
 *
 * @SpringBootApplication  – auto-discovers all @Agent, @Service beans
 * @EnableAgentShell       – activates interactive shell (execute / chat / help)
 *
 * Once running, try:
 *   shell:> execute "Predict cycling conditions in London (51.5, -0.12) on 2025-08-10 at 08:00"
 */
@SpringBootApplication
@EnableAgentShell
public class Main {
    public static void main(String[] args) {
        SpringApplication.run(Main.class, args);
    }
}
MAINEOF
success "Main.java written"

# ─── 3g. .devcontainer/devcontainer.json ─────────────────────────────────────
info "Writing .devcontainer/devcontainer.json ..."
cat > "${PROJECT_DIR}/.devcontainer/devcontainer.json" << 'DCEOF'
{
  "name": "Outdoor Sports Agent – Java 21 / Embabel",
  "image": "mcr.microsoft.com/devcontainers/java:21",
  "features": {
    "ghcr.io/devcontainers-contrib/features/maven-sdkman:2": {
      "version": "3.9.6"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "vscjava.vscode-java-pack",
        "vscjava.vscode-spring-boot-dashboard",
        "vmware.vscode-spring-boot",
        "vscjava.vscode-maven",
        "redhat.vscode-yaml"
      ],
      "settings": {
        "java.compile.nullAnalysis.mode": "automatic",
        "editor.formatOnSave": true,
        "editor.tabSize": 4
      }
    }
  },
  "forwardPorts": [8080],
  "postCreateCommand": "mvn dependency:resolve -q && echo '✅ Dependencies resolved'",
  "remoteEnv": {
    "OPENAI_API_KEY": "${localEnv:OPENAI_API_KEY}"
  },
  "remoteUser": "vscode"
}
DCEOF
success ".devcontainer/devcontainer.json written"

# ─── 3h. README.md ────────────────────────────────────────────────────────────
info "Writing README.md ..."
cat > "${PROJECT_DIR}/README.md" << 'RDMEEOF'
# 🏃 Outdoor Sports Agent

An **Embabel 0.3.2** agentic Java application that predicts outdoor sports playing
conditions using GOAP planning, real-time weather data (Open-Meteo), and GPT-4o-mini.

## Quick Start (GitHub Codespace)

```bash
# 1. Set your OpenAI key
export OPENAI_API_KEY="sk-..."

# 2. Build
mvn clean package -DskipTests

# 3. Run
java --enable-preview -jar target/outdoor-sports-agent-1.0.0.jar

# 4. Predict
shell:> execute "Predict cycling conditions in London (51.5, -0.12) on 2025-08-10 at 08:00"
```

## Agent Flow

```
SportsPredictionRequest
  → [Action 1: fetchWeatherData]       → WeatherData (Open-Meteo API)
  → [Action 2: analyseSportConditions] → SportConditions (LLM)
  → [Action 3: compileReport]          → PlayingConditionReport ✓ GOAL
```

## Sample Queries

```shell
shell:> execute "Football conditions in Dubai (25.2, 55.3) on 2025-07-20 at 18:00"
shell:> execute "Is it safe for tennis in Paris (48.85, 2.35) on 2025-09-05 at 10:00?"
shell:> execute "Trail running in Chamonix (45.92, 6.87) on 2025-12-01 at 07:00"
shell:> execute "Cycling in Sydney (-33.87, 151.21) on 2025-06-21 at 08:00"
```

## Structure

```
src/main/java/com/outdoorsports/
├── Main.java                          # @SpringBootApplication + @EnableAgentShell
├── models/Models.java                 # 4 Java 21 records (domain types)
├── agent/OutdoorSportsAgent.java      # @Agent with 3 @Action methods
└── service/EnvironmentalActionService.java  # Open-Meteo weather client
```

## Switching to Claude

Add `embabel-agent-starter-anthropic` to pom.xml, then in application.properties:
```properties
spring.ai.anthropic.api-key=${ANTHROPIC_API_KEY:}
embabel.models.default-llm=claude-sonnet-4-20250514
```
RDMEEOF
success "README.md written"

# ─── Verify all files exist ───────────────────────────────────────────────────
info "Verifying file tree..."
find "${PROJECT_DIR}" -type f | sort | while read -r f; do
    echo "    ✓ ${f#$PROJECT_DIR/}"
done

# =============================================================================
# STEP 4 – Git initialisation
# =============================================================================
header "STEP 4 · Initialising Git repository"

cd "${PROJECT_DIR}"

if [[ ! -d ".git" ]]; then
    git init -b main
    success "Git repo initialised"
else
    success "Git repo already exists"
fi

# .gitignore
cat > .gitignore << 'GIEOF'
target/
*.class
*.jar
.idea/
*.iml
.DS_Store
.env
GIEOF

git add -A
git commit -m "feat: Initial commit – Outdoor Sports Agent (Embabel 0.3.2)" \
           --allow-empty-message 2>/dev/null || true

success "Git commit created"

# =============================================================================
# STEP 5 – Maven build
# =============================================================================
header "STEP 5 · Building with Maven (this downloads ~150 MB of dependencies)"
info  "This typically takes 3–5 minutes on first run."
echo  ""

cd "${PROJECT_DIR}"
mvn clean package -DskipTests \
    --no-transfer-progress \
    -Dmaven.compiler.showWarnings=false 2>&1 | tee /tmp/mvn-build.log

BUILD_EXIT=${PIPESTATUS[0]}

if [[ ${BUILD_EXIT} -eq 0 ]]; then
    JAR_FILE=$(find target -name "*.jar" -not -name "*sources*" | head -1)
    JAR_SIZE=$(du -sh "${JAR_FILE}" 2>/dev/null | cut -f1)
    echo ""
    success "Build successful!"
    success "Artifact: ${JAR_FILE} (${JAR_SIZE})"
else
    echo ""
    error "Maven build FAILED. Check /tmp/mvn-build.log for details."
    error "Common fixes:"
    error "  • No internet access → run: mvn clean package -DskipTests -o (offline)"
    error "  • Java version wrong → run: java -version (must be 21+)"
    error "  • Dep not found → run: mvn dependency:resolve -U"
    exit 1
fi

# =============================================================================
# STEP 6 – Launch the application
# =============================================================================
header "STEP 6 · Launching Outdoor Sports Agent"

echo -e "
${BOLD}${GREEN}
  ┌─────────────────────────────────────────────────────────┐
  │  The agent is starting. When you see 'shell:>' prompt,  │
  │  try one of these commands:                             │
  │                                                         │
  │  execute \"Predict football conditions in London         │
  │           (51.5, -0.12) on 2025-08-10 at 17:00\"        │
  │                                                         │
  │  execute \"Cycling in Paris (48.85, 2.35)               │
  │           on 2025-07-20 at 08:00\"                       │
  │                                                         │
  │  execute \"Tennis in Sydney (-33.87, 151.21)            │
  │           on 2025-09-05 at 10:00\"                       │
  │                                                         │
  │  Type 'help' for all commands. Type 'quit' to exit.     │
  └─────────────────────────────────────────────────────────┘
${RESET}"

sleep 2

JAR_FILE=$(find "${PROJECT_DIR}/target" -name "*.jar" -not -name "*sources*" | head -1)

exec java \
    --enable-preview \
    -Xmx512m \
    -jar "${JAR_FILE}"
