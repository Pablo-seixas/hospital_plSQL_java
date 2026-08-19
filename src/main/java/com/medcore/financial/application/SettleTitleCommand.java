package com.medcore.financial.application;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import java.math.BigDecimal;

public record SettleTitleCommand(@NotBlank String idempotencyKey, @Positive BigDecimal principal,
                                 @PositiveOrZero BigDecimal interest, @PositiveOrZero BigDecimal penalty,
                                 @PositiveOrZero BigDecimal discount, @NotBlank String correlationId) {
}

