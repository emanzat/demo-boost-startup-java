package com.example.demo.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;

import java.time.OffsetDateTime;

@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(Exception.class)
    @ResponseBody
    public ProblemDetail handleAllExceptions(Exception ex) {
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
        String title = "Internal Server Error";
        String detail = ex.getMessage();
        if (ex instanceof PersonNotFoundException) {
            status = HttpStatus.NOT_FOUND;
            title = "Not Found";
        } else if (ex instanceof org.springframework.web.bind.MethodArgumentNotValidException) {
            status = HttpStatus.BAD_REQUEST;
            title = "Validation Failed";
            detail = "Validation failed";
        }
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, detail);
        problem.setTitle(title);
        problem.setProperty("timestamp", OffsetDateTime.now());
        return problem;
    }
}