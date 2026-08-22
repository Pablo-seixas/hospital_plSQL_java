package com.medcore.financial.application;

import java.util.List;
import java.util.Optional;

public interface FinancialQueryService {
    Optional<FinancialTitleView> findById(long titleId);

    List<FinancialAgingView> findAging(long unitId);
}
