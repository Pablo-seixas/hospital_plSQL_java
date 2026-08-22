package com.medcore.analytics.infrastructure;

import com.medcore.analytics.api.ExecutiveKpi;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class ExecutiveKpiRepository {
    private final JdbcTemplate jdbcTemplate;

    public ExecutiveKpiRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<ExecutiveKpi> findAll() {
        return jdbcTemplate.query("select unit_id, unit_code, active_admissions, available_beds, receivables, payables from mv_mc_executive_kpi order by unit_code",
                (rs, row) -> new ExecutiveKpi(rs.getLong("unit_id"), rs.getString("unit_code"), rs.getLong("active_admissions"), rs.getLong("available_beds"), rs.getBigDecimal("receivables"), rs.getBigDecimal("payables")));
    }
}

