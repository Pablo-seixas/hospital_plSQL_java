package com.medcore.admission.application;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record TransferBedCommand(@NotNull Long expectedBedId, @NotNull Long targetBedId, @NotBlank String reason, @NotBlank String correlationId) {
}

