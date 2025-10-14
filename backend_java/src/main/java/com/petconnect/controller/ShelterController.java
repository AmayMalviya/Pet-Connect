package com.petconnect.controller;

import com.petconnect.model.Shelter;
import com.petconnect.service.ShelterService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/api/shelters")
public class ShelterController {

    private final ShelterService shelterService;

    public ShelterController(ShelterService shelterService) {
        this.shelterService = shelterService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<Shelter> getShelter(@PathVariable String id) {
        Optional<Shelter> shelterOptional = shelterService.getShelter(id);
        return shelterOptional
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Shelter> saveShelter(@RequestBody Shelter shelter) {
        return ResponseEntity.ok(shelterService.saveShelter(shelter));
    }
}
