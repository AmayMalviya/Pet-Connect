package com.petconnect.controller;

import com.petconnect.model.CatBreed;
import com.petconnect.model.DogBreed;
import com.petconnect.service.BreedService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/breeds")
public class BreedController {

    private final BreedService breedService;

    public BreedController(BreedService breedService) {
        this.breedService = breedService;
    }

    @GetMapping("/dogs")
    public ResponseEntity<List<DogBreed>> getAllDogBreeds() {
        return ResponseEntity.ok(breedService.getAllDogBreeds());
    }

    @GetMapping("/cats")
    public ResponseEntity<List<CatBreed>> getAllCatBreeds() {
        return ResponseEntity.ok(breedService.getAllCatBreeds());
    }
}
