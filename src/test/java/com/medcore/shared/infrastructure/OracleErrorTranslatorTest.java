package com.medcore.shared.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.SQLException;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessResourceFailureException;

class OracleErrorTranslatorTest {
    private final OracleErrorTranslator translator = new OracleErrorTranslator();

    @Test
    void translatesKnownBusinessErrorWithoutLeakingSql() {
        var sqlException = new SQLException("internal package details", "72000", 20202);
        var translated = translator.translate(new DataAccessResourceFailureException("call failed", sqlException));
        assertThat(translated.code()).isEqualTo("ORA-20202");
        assertThat(translated.getMessage()).isEqualTo("O estoque disponível é insuficiente");
        assertThat(translated.getMessage()).doesNotContain("package");
    }

    @Test
    void usesSafeMessageForUnknownDatabaseError() {
        var sqlException = new SQLException("select secret from internal_table", "72000", 20999);
        var translated = translator.translate(new DataAccessResourceFailureException("call failed", sqlException));
        assertThat(translated.getMessage()).isEqualTo("A operação não pôde ser concluída");
        assertThat(translated.getMessage()).doesNotContain("secret");
    }
}
