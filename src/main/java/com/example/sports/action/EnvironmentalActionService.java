package com.example.sports.action;

import com.example.sports.model.Models.WeatherReport;
import io.embabel.agent.Action;
import org.springframework.stereotype.Component;
import java.time.LocalDate;

@Component
public class EnvironmentalActionService {

    @Action(description = "Retrieves structural weather metrics and atmospheric anomalies for a given location and date")
    public WeatherReport fetchEnvironmentalMetrics(String location, LocalDate date) {
        if (location.toLowerCase().contains("monaco")) {
            return new WeatherReport(18.0, 85, 15.0, false, 12.0);
        } else if (location.toLowerCase().contains("florida")) {
            return new WeatherReport(31.0, 60, 25.0, true, 8.0);
        } else {
            return new WeatherReport(24.0, 0, 10.0, false, 15.0);
        }
    }
}
