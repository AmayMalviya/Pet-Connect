package com.petconnect.service;

import com.petconnect.model.CatBreed;
import com.petconnect.model.DogBreed;
import com.petconnect.repository.CatBreedRepository;
import com.petconnect.repository.DogBreedRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BreedService {

    private final DogBreedRepository dogBreedRepository;
    private final CatBreedRepository catBreedRepository;

    public BreedService(DogBreedRepository dogBreedRepository, CatBreedRepository catBreedRepository) {
        this.dogBreedRepository = dogBreedRepository;
        this.catBreedRepository = catBreedRepository;
    }

    public List<DogBreed> getAllDogBreeds() {
        return dogBreedRepository.findAll();
    }

    public List<CatBreed> getAllCatBreeds() {
        return catBreedRepository.findAll();
    }
}
