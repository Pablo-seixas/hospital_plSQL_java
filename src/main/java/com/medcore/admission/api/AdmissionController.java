package com.medcore.admission.api;

import com.medcore.admission.application.AdmissionOperations;
import com.medcore.admission.application.TransferBedCommand;
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
@RequestMapping("/api/v1/admissions")
public class AdmissionController {
    private final AdmissionOperations operations;

    public AdmissionController(AdmissionOperations operations) {
        this.operations = operations;
    }

    @PostMapping("/{admissionId}/bed-transfers")
    @PreAuthorize("hasAuthority('admission.transfer')")
    ResponseEntity<Void> transferBed(@PathVariable long admissionId, @Valid @RequestBody TransferBedCommand command, Principal principal) {
        operations.transferBed(admissionId, command, principal.getName());
        return ResponseEntity.noContent().build();
    }
}

