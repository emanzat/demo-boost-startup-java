package com.example.demo.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.example.demo.dto.PersonDto;
import com.example.demo.entity.Person;
import com.example.demo.exception.PersonNotFoundException;
import com.example.demo.mapper.PersonMapper;
import com.example.demo.repository.PersonRepository;

@Service
public class PersonService {

    private final PersonRepository personRepository;
    private final PersonMapper personMapper;

    public PersonService(PersonRepository personRepository, PersonMapper personMapper) {
        this.personRepository = personRepository;
        this.personMapper = personMapper;
    }

    public List<PersonDto> getAllPersons() {
        return personMapper.toDtoList(personRepository.findAll());
    }

    public PersonDto getPersonByIdOrThrow(String id) {
        return personRepository.findById(id)
                .map(personMapper::toDto)
                .orElseThrow(() -> new PersonNotFoundException(id));
    }

    public PersonDto createPerson(PersonDto dto) {
        Person person = personMapper.toEntity(dto);
        Person savedPerson = personRepository.save(person);
        return personMapper.toDto(savedPerson);
    }

    public PersonDto updatePerson(String id, PersonDto dto) {
        if (!personRepository.existsById(id)) {
            throw new PersonNotFoundException(id);
        }
        Person updatedPerson = new Person(id, dto.name(), dto.age());
        Person savedPerson = personRepository.save(updatedPerson);
        return personMapper.toDto(savedPerson);
    }

    public void deletePerson(String id) {
        if (!personRepository.existsById(id)) {
            throw new PersonNotFoundException(id);
        }
        personRepository.deleteById(id);
    }
}