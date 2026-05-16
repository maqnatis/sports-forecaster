package com.example.sports.model;

import java.time.LocalDate;

public class Models {
    public enum SportType {
        CRICKET, GOLF, BASEBALL, TENNIS, FORMULA_1, SOCCER
    }

    public enum OperationalStatus {
        PROCEED_AS_SCHEDULED,
        DELAY_LIKELY,
        MODIFIED_RULES_REQUIRED,
        CANCELLED_OR_POSTPONED
    }

    public record SportsMatchContext(SportType sportType, String location, LocalDate date) {}

    public record WeatherReport(
        double temperatureCelsius,
        int precipitationProbability, 
        double windSpeedKph,
        boolean lightningRisk,
        double visibilityKm
    ) {}

    public record SportsForecast(
        OperationalStatus status,
        String sportSpecificImpact, 
        String weatherSummary
    ) {}
}
