package com.example.sports;

import com.example.sports.action.EnvironmentalActionService;
import com.example.sports.agent.OutdoorSportsAgent;
import com.example.sports.model.Models.SportType;
import com.example.sports.model.Models.SportsForecast;
import com.example.sports.model.Models.SportsMatchContext;
import java.time.LocalDate;

public class Main {
    public static void main(String[] args) {
        EnvironmentalActionService environmentalService = new EnvironmentalActionService();
        OutdoorSportsAgent agent = new OutdoorSportsAgent(environmentalService);
        
        System.out.println("--- Scenario 1: Formula 1 in Monaco ---");
        SportsMatchContext f1Context = new SportsMatchContext(
            SportType.FORMULA_1, 
            "Monaco Grand Prix Circuit", 
            LocalDate.of(2026, 5, 24)
        );
        SportsForecast f1Report = agent.evaluateMatchFeasibility(f1Context);
        printReport(f1Context, f1Report);
    }

    private static void printReport(SportsMatchContext ctx, SportsForecast report) {
        System.out.println("Sport Checked        : " + ctx.sportType());
        System.out.println("Location             : " + ctx.location());
        System.out.println("Operational Status   : " + report.status());
        System.out.println("Atmospheric Summary  : " + report.weatherSummary());
        System.out.println("Sport-Specific Impact: " + report.sportSpecificImpact());
    }
}
