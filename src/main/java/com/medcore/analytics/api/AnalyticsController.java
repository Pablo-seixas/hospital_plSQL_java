package com.medcore.analytics.api;

import com.medcore.analytics.infrastructure.ExecutiveKpiRepository;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {
    private final ExecutiveKpiRepository repository;

    public AnalyticsController(ExecutiveKpiRepository repository) {
        this.repository = repository;
    }

    @GetMapping("/executive")
    @PreAuthorize("hasAuthority('reports.view')")
    List<ExecutiveKpi> executive() {
        return repository.findAll();
    }
}

