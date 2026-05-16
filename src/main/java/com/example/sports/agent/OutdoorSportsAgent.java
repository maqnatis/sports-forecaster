package com.example.sports.agent;

import com.example.sports.action.EnvironmentalActionService;
import com.example.sports.model.Models.SportsForecast;
import com.example.sports.model.Models.SportsMatchContext;
import io.embabel.agent.EmbabelAgent;
import io.embabel.agent.annotation.Agent;
import io.embabel.agent.annotation.Goal;
import io.embabel.agent.AgentSession;
import org.springframework.beans.factory.annotation.Autowired;

@Agent(description = "An enterprise agent that evaluates weather matrices against specific outdoor sport rulebooks.")
public class OutdoorSportsAgent extends EmbabelAgent {

    private final EnvironmentalActionService environmentalService;

    @Autowired
    public OutdoorSportsAgent(EnvironmentalActionService environmentalService) {
        this.environmentalService = environmentalService;
    }

    @Goal(description = "Ingest the match framework, execute weather gathering, and output a sport-tailored operational assessment.")
    public SportsForecast evaluateMatchFeasibility(SportsMatchContext context) {
        AgentSession session = this.createSession();
        session.getBlackboard().put("matchContext", context);
        
        return session.execute(
            """
            Analyze the 'matchContext' and retrieved 'WeatherReport' data on the blackboard.
            Apply sport-specific guidelines based on the targeted SportType:
            - TENNIS/BASEBALL: Highly sensitive to moisture. If precipitationProbability > 30%, status should be DELAY_LIKELY or CANCELLED.
            - GOLF: Extreme sensitivity to lightning. If lightningRisk is true, status MUST be CANCELLED_OR_POSTPONED.
            - FORMULA_1: Rain changes operations. If precipitationProbability > 50%, status is MODIFIED_RULES_REQUIRED (Wet track protocols).
            - CRICKET: Status becomes MODIFIED_RULES_REQUIRED for rain (over reduction) or BAD_LIGHT if visibilityKm < 10.0.
            - SOCCER: Highly resilient; only flag disruptions if windSpeedKph > 50 or severe lightningRisk is true.
            
            Generate the output ensuring the 'sportSpecificImpact' field focuses directly on the logistical realities of that specific sport.
            """,
            SportsForecast.class
        );
    }
}
