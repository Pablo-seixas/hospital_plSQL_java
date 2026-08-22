package com.medcore.admission.infrastructure;

import com.medcore.admission.application.AdmissionOperations;
import com.medcore.admission.application.TransferBedCommand;
import java.sql.Types;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;
import com.medcore.shared.infrastructure.OracleErrorTranslator;
import org.springframework.dao.DataAccessException;

@Repository
public class OracleAdmissionOperations implements AdmissionOperations {
    private final SimpleJdbcCall transferBed;
    private final OracleErrorTranslator translator;

    public OracleAdmissionOperations(JdbcTemplate jdbcTemplate, OracleErrorTranslator translator) {
        this.translator = translator;
        transferBed = new SimpleJdbcCall(jdbcTemplate)
                .withCatalogName("PKG_ADMISSION")
                .withProcedureName("TRANSFER_BED")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("P_ADMISSION_ID", Types.NUMERIC),
                        new SqlParameter("P_EXPECTED_BED_ID", Types.NUMERIC),
                        new SqlParameter("P_NEW_BED_ID", Types.NUMERIC),
                        new SqlParameter("P_REASON", Types.VARCHAR),
                        new SqlParameter("P_ACTOR", Types.VARCHAR),
                        new SqlParameter("P_CORRELATION_ID", Types.VARCHAR));
    }

    @Override
    public void transferBed(long admissionId, TransferBedCommand command, String actor) {
        try {
            transferBed.execute(Map.of(
                "P_ADMISSION_ID", admissionId,
                "P_EXPECTED_BED_ID", command.expectedBedId(),
                "P_NEW_BED_ID", command.targetBedId(),
                "P_REASON", command.reason(),
                "P_ACTOR", actor,
                    "P_CORRELATION_ID", command.correlationId()));
        } catch (DataAccessException exception) {
            throw translator.translate(exception);
        }
    }
}
