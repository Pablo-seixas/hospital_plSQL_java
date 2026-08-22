package com.medcore.analytics.api;

import java.math.BigDecimal;

public record ExecutiveKpi(long unitId, String unitCode, long activeAdmissions, long availableBeds, BigDecimal receivables, BigDecimal payables) {
}

