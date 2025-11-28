package com.example.demo.controller;

import com.example.demo.dto.PersonDto;
import com.example.demo.service.PersonService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/persons")
public class PersonController {

    private final PersonService personService;

    public PersonController(PersonService personService) {
        this.personService = personService;
    }

    @GetMapping
    public List<PersonDto> getAllPersons() {
        return personService.getAllPersons();
    }

    @GetMapping("/{id}")
    public PersonDto getPersonById(@PathVariable String id) {
        return personService.getPersonByIdOrThrow(id);
    }

    @PostMapping
    public ResponseEntity<PersonDto> createPerson(@RequestBody PersonDto dto) {
        PersonDto createdPerson = personService.createPerson(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdPerson);
    }

    @PutMapping("/{id}")
    public PersonDto updatePerson(@PathVariable String id, @RequestBody PersonDto dto) {
        return personService.updatePerson(id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePerson(@PathVariable String id) {
        personService.deletePerson(id);
        return ResponseEntity.noContent().build();
    }
}