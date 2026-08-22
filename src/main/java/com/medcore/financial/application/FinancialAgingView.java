package com.medcore.financial.application;

import java.math.BigDecimal;

public record FinancialAgingView(String titleType, String agingBucket, long titleCount, BigDecimal openAmount) {
}
