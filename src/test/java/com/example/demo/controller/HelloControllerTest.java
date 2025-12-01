package com.example.demo.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.client.MockMvcWebTestClient;
import org.springframework.test.web.reactive.server.WebTestClient;

import static org.junit.jupiter.api.Assertions.assertEquals;

class HelloControllerTest {

    private WebTestClient client;

    @BeforeEach
    void setup() {
        client = MockMvcWebTestClient.bindToController(new HelloController()).build();
    }

    @Test
    void hello_ShouldReturnGreetingMessage() {
        String response = client.get()
                .uri("/")
                .exchange()
                .expectStatus().isOk()
                .expectBody(String.class)
                .returnResult()
                .getResponseBody();

        assertEquals("MANZAT --> Hello from Spring Boot 4 with Java 25!", response);
    }
}
