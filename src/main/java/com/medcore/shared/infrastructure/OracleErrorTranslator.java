package com.medcore.shared.infrastructure;

import com.medcore.shared.domain.BusinessRuleException;
import java.sql.SQLException;
import java.util.Map;
import org.springframework.core.NestedExceptionUtils;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Component;

@Component
public class OracleErrorTranslator {
    private static final Map<Integer, String> MESSAGES = Map.ofEntries(
            Map.entry(20101, "A internação não está ativa"),
            Map.entry(20102, "O leito atual foi alterado por outra operação"),
            Map.entry(20103, "O leito de destino não está disponível"),
            Map.entry(20104, "Não foi possível bloquear o leito no tempo permitido"),
            Map.entry(20202, "O estoque disponível é insuficiente"),
            Map.entry(20203, "A requisição de estoque já foi processada"),
            Map.entry(20302, "A competência contábil está fechada"),
            Map.entry(20303, "O lançamento contábil não está balanceado"),
            Map.entry(20401, "O título não permite liquidação"),
            Map.entry(20402, "O valor de liquidação é inválido"),
            Map.entry(20403, "A liquidação já foi processada"),
            Map.entry(20502, "A conta hospitalar possui itens inconsistentes"),
            Map.entry(20701, "A integração não permite reprocessamento"));

    public BusinessRuleException translate(DataAccessException exception) {
        var root = NestedExceptionUtils.getMostSpecificCause(exception);
        var errorCode = root instanceof SQLException sql ? sql.getErrorCode() : 0;
        var message = MESSAGES.getOrDefault(errorCode, "A operação não pôde ser concluída");
        return new BusinessRuleException("ORA-" + errorCode, message, exception);
    }
}

