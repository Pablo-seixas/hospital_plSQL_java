package com.medcore.financial.application;

public interface FinancialCommandHandler {
    void settle(long titleId, SettleTitleCommand command, String actor);
}
