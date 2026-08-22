package com.medcore.admission.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.medcore.admission.application.AdmissionOperations;
import com.medcore.admission.application.TransferBedCommand;
import com.medcore.configuration.SecurityConfiguration;
import com.medcore.shared.api.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AdmissionController.class)
@Import({SecurityConfiguration.class, GlobalExceptionHandler.class})
class AdmissionControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean AdmissionOperations operations;

    @Test
    void transfersBedWithRequiredAuthority() throws Exception {
        mvc.perform(post("/api/v1/admissions/42/bed-transfers")
                        .with(user("operator").authorities(() -> "admission.transfer"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"expectedBedId\":7,\"targetBedId\":8,\"reason\":\"Clinical allocation\",\"correlationId\":\"req-001\"}"))
                .andExpect(status().isNoContent());
        verify(operations).transferBed(eq(42L), any(TransferBedCommand.class), eq("operator"));
    }

    @Test
    void rejectsCallerWithoutAuthority() throws Exception {
        mvc.perform(post("/api/v1/admissions/42/bed-transfers")
                        .with(user("viewer"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"expectedBedId\":7,\"targetBedId\":8,\"reason\":\"Clinical allocation\",\"correlationId\":\"req-002\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void rejectsAnonymousCaller() throws Exception {
        mvc.perform(post("/api/v1/admissions/42/bed-transfers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"expectedBedId\":7,\"targetBedId\":8,\"reason\":\"Clinical allocation\",\"correlationId\":\"req-003\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void rejectsInvalidPayload() throws Exception {
        mvc.perform(post("/api/v1/admissions/42/bed-transfers")
                        .with(user("operator").authorities(() -> "admission.transfer"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"\",\"correlationId\":\"\"}"))
                .andExpect(status().isBadRequest());
    }
}
