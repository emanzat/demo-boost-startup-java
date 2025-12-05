package com.example.demo.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "#{@environment.getProperty('mongodb.collection.person')}")
public record Person(@Id String id, String name, int age) {
	public Person(String name, int age) {
		this(null, name, age);
	}
}
