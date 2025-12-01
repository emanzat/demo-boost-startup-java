package com.example.demo.service;

import com.example.demo.dto.PersonDto;
import com.example.demo.entity.Person;
import com.example.demo.exception.PersonNotFoundException;
import com.example.demo.mapper.PersonMapper;
import com.example.demo.repository.PersonRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PersonServiceTest {

    @Mock
    private PersonRepository personRepository;

    @Mock
    private PersonMapper personMapper;

    @InjectMocks
    private PersonService personService;

    private Person person;
    private PersonDto personDto;

    @BeforeEach
    void setUp() {
        person = new Person("1", "John Doe", 30);
        personDto = new PersonDto("1", "John Doe", 30);
    }

    @Test
    void getAllPersons_ShouldReturnListOfPersonDtos() {
        // Given
        List<Person> persons = Arrays.asList(
                new Person("1", "John Doe", 30),
                new Person("2", "Jane Smith", 25)
        );
        List<PersonDto> personDtos = Arrays.asList(
                new PersonDto("1", "John Doe", 30),
                new PersonDto("2", "Jane Smith", 25)
        );
        when(personRepository.findAll()).thenReturn(persons);
        when(personMapper.toDtoList(persons)).thenReturn(personDtos);

        // When
        List<PersonDto> result = personService.getAllPersons();

        // Then
        assertThat(result).hasSize(2);
        assertThat(result.get(0).name()).isEqualTo("John Doe");
        assertThat(result.get(1).name()).isEqualTo("Jane Smith");
        verify(personRepository).findAll();
        verify(personMapper).toDtoList(persons);
    }

    @Test
    void getPersonByIdOrThrow_WhenPersonExists_ShouldReturnPersonDto() {
        // Given
        when(personRepository.findById("1")).thenReturn(Optional.of(person));
        when(personMapper.toDto(person)).thenReturn(personDto);

        // When
        PersonDto result = personService.getPersonByIdOrThrow("1");

        // Then
        assertThat(result).isNotNull();
        assertThat(result.id()).isEqualTo("1");
        assertThat(result.name()).isEqualTo("John Doe");
        verify(personRepository).findById("1");
        verify(personMapper).toDto(person);
    }

    @Test
    void getPersonByIdOrThrow_WhenPersonNotExists_ShouldThrowException() {
        // Given
        when(personRepository.findById("999")).thenReturn(Optional.empty());

        // When & Then
        assertThatThrownBy(() -> personService.getPersonByIdOrThrow("999"))
                .isInstanceOf(PersonNotFoundException.class);
        verify(personRepository).findById("999");
        verify(personMapper, never()).toDto(any());
    }

    @Test
    void createPerson_ShouldReturnCreatedPersonDto() {
        // Given
        PersonDto inputDto = new PersonDto(null, "John Doe", 30);
        Person newPerson = new Person(null, "John Doe", 30);
        when(personMapper.toEntity(inputDto)).thenReturn(newPerson);
        when(personRepository.save(newPerson)).thenReturn(person);
        when(personMapper.toDto(person)).thenReturn(personDto);

        // When
        PersonDto result = personService.createPerson(inputDto);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.id()).isEqualTo("1");
        assertThat(result.name()).isEqualTo("John Doe");
        verify(personMapper).toEntity(inputDto);
        verify(personRepository).save(newPerson);
        verify(personMapper).toDto(person);
    }

    @Test
    void updatePerson_WhenPersonExists_ShouldReturnUpdatedPersonDto() {
        // Given
        PersonDto updateDto = new PersonDto(null, "John Updated", 31);
        Person updatedPerson = new Person("1", "John Updated", 31);
        PersonDto updatedDto = new PersonDto("1", "John Updated", 31);

        when(personRepository.existsById("1")).thenReturn(true);
        when(personRepository.save(any(Person.class))).thenReturn(updatedPerson);
        when(personMapper.toDto(updatedPerson)).thenReturn(updatedDto);

        // When
        PersonDto result = personService.updatePerson("1", updateDto);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.id()).isEqualTo("1");
        assertThat(result.name()).isEqualTo("John Updated");
        assertThat(result.age()).isEqualTo(31);
        verify(personRepository).existsById("1");
        verify(personRepository).save(any(Person.class));
        verify(personMapper).toDto(updatedPerson);
    }

    @Test
    void updatePerson_WhenPersonNotExists_ShouldThrowException() {
        // Given
        PersonDto updateDto = new PersonDto(null, "John Updated", 31);
        when(personRepository.existsById("999")).thenReturn(false);

        // When & Then
        assertThatThrownBy(() -> personService.updatePerson("999", updateDto))
                .isInstanceOf(PersonNotFoundException.class);
        verify(personRepository).existsById("999");
        verify(personRepository, never()).save(any());
    }

    @Test
    void deletePerson_WhenPersonExists_ShouldDeletePerson() {
        // Given
        when(personRepository.existsById("1")).thenReturn(true);
        doNothing().when(personRepository).deleteById("1");

        // When
        personService.deletePerson("1");

        // Then
        verify(personRepository).existsById("1");
        verify(personRepository).deleteById("1");
    }

    @Test
    void deletePerson_WhenPersonNotExists_ShouldThrowException() {
        // Given
        when(personRepository.existsById("999")).thenReturn(false);

        // When & Then
        assertThatThrownBy(() -> personService.deletePerson("999"))
                .isInstanceOf(PersonNotFoundException.class);
        verify(personRepository).existsById("999");
        verify(personRepository, never()).deleteById(any());
    }
}
