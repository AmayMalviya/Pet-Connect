package com.petconnect.controller;

import com.google.firebase.auth.FirebaseToken;
import com.petconnect.model.Pet;
import com.petconnect.service.PetService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/pets")
public class PetController {

    private final PetService petService;

    public PetController(PetService petService) {
        this.petService = petService;
    }

    @GetMapping
    public ResponseEntity<List<Pet>> getMyPets(@AuthenticationPrincipal FirebaseToken decodedToken) {
        if (decodedToken == null) {
            return ResponseEntity.status(401).build();
        }
        List<Pet> pets = petService.getPetsByOwnerId(decodedToken.getUid());
        return ResponseEntity.ok(pets);
    }

    @PostMapping
    public ResponseEntity<Pet> addPet(@AuthenticationPrincipal FirebaseToken decodedToken, @RequestBody Pet pet) {
        if (decodedToken == null) {
            return ResponseEntity.status(401).build();
        }
        // Set the owner ID from the authenticated user's token
        pet.setOwnerId(decodedToken.getUid());
        Pet savedPet = petService.addPet(pet);
        return ResponseEntity.ok(savedPet);
    }
}
