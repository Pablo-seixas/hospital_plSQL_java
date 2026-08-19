package com.medcore.financial.api;

import com.medcore.financial.application.SettleTitleCommand;
import com.medcore.financial.infrastructure.OracleFinancialOperations;
import jakarta.validation.Valid;
import java.security.Principal;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/financial/titles")
public class FinancialController {
    private final OracleFinancialOperations operations;

    public FinancialController(OracleFinancialOperations operations) {
        this.operations = operations;
    }

    @PostMapping("/{titleId}/settlements")
    @PreAuthorize("hasAuthority('financial.settle')")
    ResponseEntity<Void> settle(@PathVariable long titleId, @Valid @RequestBody SettleTitleCommand command, Principal principal) {
        operations.settle(titleId, command, principal.getName());
        return ResponseEntity.noContent().build();
    }
}

