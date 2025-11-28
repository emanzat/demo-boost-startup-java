package com.example.demo.exception;

public class PersonNotFoundException extends RuntimeException {
    private static final long serialVersionUID = 1L;

	public PersonNotFoundException(String id) {
        super("Person not found with id: " + id);
    }
}
