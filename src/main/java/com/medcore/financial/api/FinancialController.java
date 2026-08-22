package com.medcore.financial.api;

import com.medcore.financial.application.SettleTitleCommand;
import com.medcore.financial.application.FinancialCommandHandler;
import com.medcore.financial.application.FinancialQueryService;
import com.medcore.financial.application.FinancialTitleView;
import com.medcore.financial.application.FinancialAgingView;
import jakarta.validation.Valid;
import java.security.Principal;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/financial/titles")
public class FinancialController {
    private final FinancialCommandHandler commandHandler;
    private final FinancialQueryService queryService;

    public FinancialController(FinancialCommandHandler commandHandler, FinancialQueryService queryService) {
        this.commandHandler = commandHandler;
        this.queryService = queryService;
    }

    @PostMapping("/{titleId}/settlements")
    @PreAuthorize("hasAuthority('financial.settle')")
    ResponseEntity<Void> settle(@PathVariable long titleId, @Valid @RequestBody SettleTitleCommand command, Principal principal) {
        commandHandler.settle(titleId, command, principal.getName());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{titleId}")
    @PreAuthorize("hasAuthority('financial.view')")
    ResponseEntity<FinancialTitleView> findById(@PathVariable long titleId) {
        return queryService.findById(titleId).map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/aging/{unitId}")
    @PreAuthorize("hasAuthority('financial.view')")
    List<FinancialAgingView> findAging(@PathVariable long unitId) {
        return queryService.findAging(unitId);
    }
}
