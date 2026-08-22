package com.medcore.financial.infrastructure;

import com.medcore.financial.application.SettleTitleCommand;
import com.medcore.financial.application.FinancialCommandHandler;
import com.medcore.shared.infrastructure.OracleErrorTranslator;
import java.sql.Types;
import java.util.Map;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

@Repository
public class OracleFinancialOperations implements FinancialCommandHandler {
    private final SimpleJdbcCall settleTitle;
    private final OracleErrorTranslator translator;

    public OracleFinancialOperations(JdbcTemplate jdbcTemplate, OracleErrorTranslator translator) {
        this.translator = translator;
        this.settleTitle = new SimpleJdbcCall(jdbcTemplate).withCatalogName("PKG_FINANCIAL").withProcedureName("SETTLE_TITLE")
                .withoutProcedureColumnMetaDataAccess().declareParameters(
                        new SqlParameter("P_TITLE_ID", Types.NUMERIC), new SqlParameter("P_IDEMPOTENCY_KEY", Types.VARCHAR),
                        new SqlParameter("P_PRINCIPAL", Types.NUMERIC), new SqlParameter("P_INTEREST", Types.NUMERIC),
                        new SqlParameter("P_PENALTY", Types.NUMERIC), new SqlParameter("P_DISCOUNT", Types.NUMERIC),
                        new SqlParameter("P_ACTOR", Types.VARCHAR), new SqlParameter("P_CORRELATION_ID", Types.VARCHAR));
    }

    @Override
    public void settle(long titleId, SettleTitleCommand command, String actor) {
        try {
            settleTitle.execute(Map.of("P_TITLE_ID", titleId, "P_IDEMPOTENCY_KEY", command.idempotencyKey(),
                    "P_PRINCIPAL", command.principal(), "P_INTEREST", command.interest(), "P_PENALTY", command.penalty(),
                    "P_DISCOUNT", command.discount(), "P_ACTOR", actor, "P_CORRELATION_ID", command.correlationId()));
        } catch (DataAccessException exception) {
            throw translator.translate(exception);
        }
    }
}
