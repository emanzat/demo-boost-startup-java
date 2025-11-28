package com.example.demo.mapper;

import com.example.demo.dto.PersonDto;
import com.example.demo.entity.Person;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface PersonMapper extends GenericMapper<Person, PersonDto> {
}