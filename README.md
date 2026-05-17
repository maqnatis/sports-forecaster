# 🏃 Outdoor Sports Agent

An **Embabel-powered agentic Java application** that predicts playing conditions for outdoor sports using real-time weather data, location, datetime, and sport-specific AI reasoning.

Built with:
- **Embabel 0.3.2** – GOAP-based JVM agent framework by Rod Johnson (Spring creator)
- **Spring Boot 3.5** – application infrastructure
- **Spring AI + OpenAI GPT-4o-mini** – LLM reasoning layer
- **Open-Meteo API** – free weather data (no API key required for weather)
- **Java 21** – records, pattern matching, sealed classes

---

## Architecture

```
User Input (natural language)
        │
        ▼
SportsPredictionRequest  ──[Action 1: fetchWeatherData]──►  WeatherData
                                                                  │
                                                   [Action 2: analyseSportConditions]
                                                                  │
                                                            SportConditions
                                                                  │
                                                  [Action 3: compileReport] ← GOAL
                                                                  │
                                                    PlayingConditionReport ✓
```

Embabel's **Goal-Oriented Action Planning (GOAP)** engine automatically sequences the three `@Action` methods by matching their input/output types — the developer never hardcodes the workflow.

---

## Project Structure

```
outdoor-sports-agent/
├── .devcontainer/
│   └── devcontainer.json              # GitHub Codespace configuration
├── src/main/java/com/outdoorsports/
│   ├── Main.java                      # Spring Boot entry point + @EnableAgentShell
│   ├── models/
│   │   └── Models.java                # All domain record types (4 records)
│   ├── agent/
│   │   └── OutdoorSportsAgent.java    # @Agent with 3 @Action methods
│   └── service/
│       └── EnvironmentalActionService.java  # Open-Meteo weather API client
├── src/main/resources/
│   └── application.properties         # All configuration properties
└── pom.xml                            # Maven build + all dependencies
```

---

## Prerequisites

| Tool | Required Version | Notes |
|------|-----------------|-------|
| Java | 21+ | Pre-installed in the Codespace image |
| Maven | 3.9+ | Pre-installed in the Codespace image |
| OpenAI API Key | Any | Get one at https://platform.openai.com/api-keys |

---

## Step-by-Step: Run on GitHub Codespace

### Step 1 – Fork / Clone the Repository

```bash
# Option A: Use this repo directly
git clone https://github.com/YOUR_USERNAME/outdoor-sports-agent.git
cd outdoor-sports-agent

# Option B: If starting from scratch, initialise git
git init
git add .
git commit -m "Initial commit: Outdoor Sports Agent"
```

### Step 2 – Set Your OpenAI API Key as a Codespace Secret

> ⚠️ **Never commit API keys to source control.**

1. Go to your GitHub repository page
2. Click **Settings** → **Secrets and variables** → **Codespaces**
3. Click **New repository secret**
4. Name: `OPENAI_API_KEY`
5. Value: `sk-...` (your OpenAI API key)
6. Click **Add secret**

### Step 3 – Open in GitHub Codespace

1. Go to your repository on GitHub
2. Click the green **`<> Code`** button
3. Click **Codespaces** tab
4. Click **Create codespace on main**
5. Wait ~2 minutes for the container to build and `postCreateCommand` to run

The Codespace will automatically:
- Use Java 21 (from `.devcontainer/devcontainer.json`)
- Install all VS Code Java extensions
- Run `mvn dependency:resolve` in the background

### Step 4 – Verify the Environment

Open the **Terminal** in VS Code (`` Ctrl+` ``) and run:

```bash
# Check Java version (must be 21+)
java -version

# Check Maven version (must be 3.9+)
mvn -version

# Verify the API key is set (should print: sk-...)
echo $OPENAI_API_KEY
```

Expected output:
```
openjdk version "21.0.x" ...
Apache Maven 3.9.x ...
sk-proj-...
```

### Step 5 – Build the Project

```bash
# Full clean build (downloads deps, compiles, runs unit tests)
mvn clean package -DskipTests

# Or build + run tests (no API key needed for unit tests)
mvn clean package
```

Successful build output ends with:
```
[INFO] BUILD SUCCESS
[INFO] outdoor-sports-agent-1.0.0.jar
```

### Step 6 – Run the Application

```bash
# Run the fat JAR (Spring Shell interactive mode)
java --enable-preview \
     -jar target/outdoor-sports-agent-1.0.0.jar

# --- OR using Maven Spring Boot plugin ---
mvn spring-boot:run \
    -Dspring-boot.run.jvmArguments="--enable-preview"
```

You will see the Embabel/Spring Shell banner followed by a `shell:>` prompt.

### Step 7 – Predict Sports Conditions

At the `shell:>` prompt, use the `execute` command with a natural language instruction:

#### Example 1 – Football / Soccer
```shell
shell:> execute "Predict playing conditions for football in Dubai, UAE (25.2, 55.3) on 2025-07-20 at 18:00"
```

#### Example 2 – Cycling
```shell
shell:> execute "Will conditions be good for cycling in Paris, France (48.85, 2.35) this Saturday at 08:00?"
```

#### Example 3 – Tennis
```shell
shell:> execute "Assess tennis conditions in Sydney, Australia (-33.87, 151.21) for 2025-08-10 at 10:00"
```

#### Example 4 – Trail Running
```shell
shell:> execute "Is it safe to go trail running in Chamonix, France (45.92, 6.87) on 2025-12-01 at 07:00?"
```

#### Example 5 – Swimming (outdoor)
```shell
shell:> execute "Outdoor swimming conditions in Barcelona, Spain (41.39, 2.15) on 2025-06-21 at 14:00"
```

### Step 8 – Understand the Output

The agent prints its GOAP plan before executing:

```
[INFO] Embabel - formulated plan:
  OutdoorSportsAgent.fetchWeatherData
  -> OutdoorSportsAgent.analyseSportConditions
  -> OutdoorSportsAgent.compileReport

[Action 1] Fetching weather for 'Dubai, UAE' at (25.2, 55.3) on Sunday, 20 July 2025 at 18:00
[Action 2] LLM analysing conditions for 'football' sport
[Action 3] Compiling final report...

═══════════════════════════════════════════════════════════
 PLAYING CONDITION REPORT
═══════════════════════════════════════════════════════════
 Sport:    Football
 Location: Dubai, UAE
 DateTime: Sunday, 20 July 2025 at 18:00
 Rating:   POOR

 🌡  42.3°C | 💨 18 km/h | 🌧 0 mm | ☁ 5% cloud | UV 6.2

 VERDICT:
 Conditions are rated POOR for football – extreme heat (42°C)
 poses serious dehydration and heat stroke risk at this time.

 RECOMMENDATION:
 You should postpone this session. The 42°C temperature at 18:00
 in July Dubai far exceeds safe exercise thresholds...

 ALTERNATIVE:
 Consider playing early morning (06:00–07:00) when temperatures
 are typically 28–30°C.
═══════════════════════════════════════════════════════════
```

### Step 9 – Other Shell Commands

```shell
# See all available commands
shell:> help

# Interactive chat mode (multi-turn conversation with the agent)
shell:> chat

# Exit the application
shell:> quit
```

---

## Configuration Reference

### application.properties

| Property | Default | Description |
|----------|---------|-------------|
| `spring.ai.openai.api-key` | `${OPENAI_API_KEY}` | Your OpenAI key (from env var) |
| `spring.ai.openai.chat.options.model` | `gpt-4o-mini` | Change to `gpt-4o` for higher quality |
| `embabel.models.default-llm` | `gpt-4o-mini` | Embabel's default model identifier |
| `embabel.logging.log-prompts` | `false` | Set `true` to see prompts sent to LLM |
| `embabel.logging.log-responses` | `false` | Set `true` to see raw LLM responses |
| `weather.api.base-url` | Open-Meteo URL | The free weather API endpoint |

### Using Anthropic Claude Instead of OpenAI

1. Add the Anthropic starter to `pom.xml`:
```xml
<dependency>
    <groupId>com.embabel.agent</groupId>
    <artifactId>embabel-agent-starter-anthropic</artifactId>
    <version>0.3.2</version>
</dependency>
```

2. Replace OpenAI config in `application.properties`:
```properties
spring.ai.anthropic.api-key=${ANTHROPIC_API_KEY:}
embabel.models.default-llm=claude-sonnet-4-20250514
```

3. Set `ANTHROPIC_API_KEY` as a Codespace secret (same as Step 2).

---

## Troubleshooting

### ❌ `OPENAI_API_KEY not set`
```bash
# In the terminal, manually export the key for the current session:
export OPENAI_API_KEY="sk-..."
# Then rerun the application
```

### ❌ `ClassNotFoundException: com.embabel.agent.api.annotation.Agent`
The Embabel JAR didn't download. Force dependency resolution:
```bash
mvn dependency:resolve -U
mvn clean package -DskipTests
```

### ❌ Weather API returns no data (network restricted Codespace)
The `EnvironmentalActionService` includes automatic fallback to synthetic
weather data (mild/sunny conditions) when the Open-Meteo API is unreachable.
The agent still runs end-to-end – you'll see `(synthetic fallback)` in the
weather description.

### ❌ `--enable-preview` compile error
Some CI environments disable preview features. Remove the `<compilerArgs>` block
in `pom.xml` if Java 21 standard features are sufficient for your use.

### ❌ Out of memory in Codespace
```bash
# Increase Maven heap
export MAVEN_OPTS="-Xmx2g"
mvn spring-boot:run
```

---

## Extending the Agent

### Add a New Action (e.g. historical trends)
```java
@Action(description = "Fetch historical weather data for the same date in past years")
public HistoricalData fetchHistoricalData(SportsPredictionRequest request, OperationContext ctx) {
    // ... call a historical weather API
    return new HistoricalData(...);
}
```
Embabel's GOAP planner will automatically incorporate this action into the plan
when `HistoricalData` is needed by a downstream action — no workflow changes required.

### Add MCP Tool Support
```java
// In Main.java, replace @EnableAgentShell with:
@EnableAgents(mcpServers = { McpServers.DOCKER_DESKTOP })
// Then configure MCP servers in application.properties
```

### Switch to Utility AI (exploration mode)
In `application.properties`:
```properties
embabel.planning.strategy=utility-ai
```
This switches from strict GOAP precondition/postcondition planning to
score-based action selection – useful for open-ended sports recommendation.

---

## License

Apache 2.0 – same as the Embabel framework itself.
