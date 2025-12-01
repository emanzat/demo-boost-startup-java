package com.example.demo.controller;

import com.example.demo.dto.PersonDto;
import com.example.demo.service.PersonService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.test.web.reactive.server.WebTestClient;
import org.springframework.test.web.servlet.client.MockMvcWebTestClient;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PersonControllerTest {

    private WebTestClient client;

    @Mock
    private PersonService personService;

    @BeforeEach
    void setup() {
        client = MockMvcWebTestClient.bindToController(new PersonController(personService)).build();
    }

    @Test
    void getAllPersons_ShouldReturnListOfPersons() {
        // Given
        List<PersonDto> persons = Arrays.asList(
                new PersonDto("1", "John Doe", 30),
                new PersonDto("2", "Jane Smith", 25)
        );
        when(personService.getAllPersons()).thenReturn(persons);

        // When
        List<PersonDto> result = client.get()
                .uri("/api/persons")
                .exchange()
                .expectStatus().isOk()
                .expectBody(new ParameterizedTypeReference<List<PersonDto>>() {})
                .returnResult()
                .getResponseBody();

        // Then
        assertNotNull(result);
        assertEquals(2, result.size());
        assertEquals("1", result.get(0).id());
        assertEquals("John Doe", result.get(0).name());
        assertEquals(30, result.get(0).age());
        assertEquals("2", result.get(1).id());
        assertEquals("Jane Smith", result.get(1).name());
        assertEquals(25, result.get(1).age());
    }

    @Test
    void getPersonById_ShouldReturnPerson() {
        // Given
        PersonDto person = new PersonDto("1", "John Doe", 30);
        when(personService.getPersonByIdOrThrow("1")).thenReturn(person);

        // When
        PersonDto result = client.get()
                .uri("/api/persons/1")
                .exchange()
                .expectStatus().isOk()
                .expectBody(PersonDto.class)
                .returnResult()
                .getResponseBody();

        // Then
        assertNotNull(result);
        assertEquals("1", result.id());
        assertEquals("John Doe", result.name());
        assertEquals(30, result.age());
    }

    @Test
    void createPerson_ShouldReturnCreatedPerson() {
        // Given
        PersonDto inputDto = new PersonDto(null, "John Doe", 30);
        PersonDto createdDto = new PersonDto("1", "John Doe", 30);
        when(personService.createPerson(any(PersonDto.class))).thenReturn(createdDto);

        // When
        PersonDto result = client.post()
                .uri("/api/persons")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(inputDto)
                .exchange()
                .expectStatus().isCreated()
                .expectBody(PersonDto.class)
                .returnResult()
                .getResponseBody();

        // Then
        assertNotNull(result);
        assertEquals("1", result.id());
        assertEquals("John Doe", result.name());
        assertEquals(30, result.age());
    }

    @Test
    void updatePerson_ShouldReturnUpdatedPerson() {
        // Given
        PersonDto inputDto = new PersonDto(null, "John Updated", 31);
        PersonDto updatedDto = new PersonDto("1", "John Updated", 31);
        when(personService.updatePerson(eq("1"), any(PersonDto.class))).thenReturn(updatedDto);

        // When
        PersonDto result = client.put()
                .uri("/api/persons/1")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(inputDto)
                .exchange()
                .expectStatus().isOk()
                .expectBody(PersonDto.class)
                .returnResult()
                .getResponseBody();

        // Then
        assertNotNull(result);
        assertEquals("1", result.id());
        assertEquals("John Updated", result.name());
        assertEquals(31, result.age());
    }

    @Test
    void deletePerson_ShouldReturnNoContent() {
        // Given
        doNothing().when(personService).deletePerson("1");

        // When & Then
        client.delete()
                .uri("/api/persons/1")
                .exchange()
                .expectStatus().isNoContent();
    }
}
