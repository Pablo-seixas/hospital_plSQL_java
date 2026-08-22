package com.medcore.financial.infrastructure;

import com.medcore.financial.application.FinancialAgingView;
import com.medcore.financial.application.FinancialQueryService;
import com.medcore.financial.application.FinancialTitleView;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class JdbcFinancialQueryService implements FinancialQueryService {
    private final JdbcTemplate jdbcTemplate;

    public JdbcFinancialQueryService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Optional<FinancialTitleView> findById(long titleId) {
        var results = jdbcTemplate.query("""
                select title_id, title_type, unit_id, cost_center_id, external_reference, issue_date, due_date,
                       original_amount, open_amount, status, source_type, source_id
                  from mc_financial_title
                 where title_id = ?
                """, (resultSet, rowNumber) -> new FinancialTitleView(
                resultSet.getLong("title_id"),
                resultSet.getString("title_type"),
                resultSet.getLong("unit_id"),
                resultSet.getObject("cost_center_id", Long.class),
                resultSet.getString("external_reference"),
                resultSet.getDate("issue_date").toLocalDate(),
                resultSet.getDate("due_date").toLocalDate(),
                resultSet.getBigDecimal("original_amount"),
                resultSet.getBigDecimal("open_amount"),
                resultSet.getString("status"),
                resultSet.getString("source_type"),
                resultSet.getString("source_id")), titleId);
        return results.stream().findFirst();
    }

    @Override
    public List<FinancialAgingView> findAging(long unitId) {
        return jdbcTemplate.query("""
                select title_type, aging_bucket, title_count, open_amount
                  from vw_mc_financial_aging
                 where unit_id = ?
                 order by title_type, aging_bucket
                """, (resultSet, rowNumber) -> new FinancialAgingView(
                resultSet.getString("title_type"),
                resultSet.getString("aging_bucket"),
                resultSet.getLong("title_count"),
                resultSet.getBigDecimal("open_amount")), unitId);
    }
}
