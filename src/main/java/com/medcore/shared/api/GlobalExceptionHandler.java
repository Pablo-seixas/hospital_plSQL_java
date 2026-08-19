package com.medcore.shared.api;

import java.sql.SQLException;
import java.time.Instant;
import java.util.Map;
import com.medcore.shared.domain.BusinessRuleException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessRuleException.class)
    ResponseEntity<ApiError> business(BusinessRuleException exception) {
        return ResponseEntity.unprocessableEntity().body(new ApiError(exception.code(), exception.getMessage(), Instant.now(), Map.of()));
    }

    @ExceptionHandler(BindException.class)
    ResponseEntity<ApiError> validation(BindException exception) {
        var details = exception.getFieldErrors().stream().collect(java.util.stream.Collectors.toMap(e -> e.getField(), e -> e.getDefaultMessage(), (a, b) -> a));
        return ResponseEntity.badRequest().body(new ApiError("VALIDATION_ERROR", "Request validation failed", Instant.now(), details));
    }

    @ExceptionHandler(SQLException.class)
    ResponseEntity<ApiError> oracle(SQLException exception) {
        var status = exception.getErrorCode() >= 20000 && exception.getErrorCode() <= 20999 ? HttpStatus.UNPROCESSABLE_ENTITY : HttpStatus.SERVICE_UNAVAILABLE;
        return ResponseEntity.status(status).body(new ApiError("DATABASE_ERROR_" + exception.getErrorCode(), "Database operation failed", Instant.now(), Map.of()));
    }
}
