package com.medcore.admission.application;

public interface AdmissionOperations {
    void transferBed(long admissionId, TransferBedCommand command, String actor);
}

