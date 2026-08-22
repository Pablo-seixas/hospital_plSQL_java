package com.medcore.financial.application;

import java.math.BigDecimal;
import java.time.LocalDate;

public record FinancialTitleView(long titleId, String titleType, long unitId, Long costCenterId,
                                 String externalReference, LocalDate issueDate, LocalDate dueDate,
                                 BigDecimal originalAmount, BigDecimal openAmount, String status,
                                 String sourceType, String sourceId) {
}
