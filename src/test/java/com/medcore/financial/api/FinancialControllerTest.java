package com.medcore.financial.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.medcore.configuration.SecurityConfiguration;
import com.medcore.financial.application.FinancialAgingView;
import com.medcore.financial.application.FinancialCommandHandler;
import com.medcore.financial.application.FinancialQueryService;
import com.medcore.financial.application.FinancialTitleView;
import com.medcore.financial.application.SettleTitleCommand;
import com.medcore.shared.api.GlobalExceptionHandler;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(FinancialController.class)
@Import({SecurityConfiguration.class, GlobalExceptionHandler.class})
class FinancialControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean FinancialCommandHandler commandHandler;
    @MockitoBean FinancialQueryService queryService;

    @Test
    void settlesTitleWithCommandAuthority() throws Exception {
        mvc.perform(post("/api/v1/financial/titles/42/settlements")
                        .with(user("operator").authorities(() -> "financial.settle"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idempotencyKey\":\"pay-001\",\"principal\":100.00,\"interest\":0,\"penalty\":0,\"discount\":0,\"correlationId\":\"req-001\"}"))
                .andExpect(status().isNoContent());
        verify(commandHandler).settle(eq(42L), any(SettleTitleCommand.class), eq("operator"));
    }

    @Test
    void readsTitleWithQueryAuthority() throws Exception {
        when(queryService.findById(42L)).thenReturn(Optional.of(new FinancialTitleView(
                42L, "RECEIVABLE", 1L, null, "INV-42", LocalDate.of(2026, 8, 1),
                LocalDate.of(2026, 8, 31), new BigDecimal("500.00"), new BigDecimal("200.00"),
                "PARTIAL", "BILLING", "42")));

        mvc.perform(get("/api/v1/financial/titles/42")
                        .with(user("viewer").authorities(() -> "financial.view")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.titleId").value(42))
                .andExpect(jsonPath("$.openAmount").value(200.00));
    }

    @Test
    void readsAgingWithQueryAuthority() throws Exception {
        when(queryService.findAging(1L)).thenReturn(List.of(
                new FinancialAgingView("PAYABLE", "1_30", 3L, new BigDecimal("900.00"))));

        mvc.perform(get("/api/v1/financial/titles/aging/1")
                        .with(user("viewer").authorities(() -> "financial.view")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].titleCount").value(3));
    }

    @Test
    void rejectsQueryWithoutAuthority() throws Exception {
        mvc.perform(get("/api/v1/financial/titles/42").with(user("caller")))
                .andExpect(status().isForbidden());
    }
}
