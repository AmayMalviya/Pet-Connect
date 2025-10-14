package com.petconnect.service;

import com.petconnect.model.Pet;
import com.petconnect.repository.PetRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PetService {

    private final PetRepository petRepository;

    public PetService(PetRepository petRepository) {
        this.petRepository = petRepository;
    }

    public List<Pet> getPetsByOwnerId(String ownerId) {
        return petRepository.findByOwnerId(ownerId);
    }

    public Pet addPet(Pet pet) {
        // The ownerId should be set in the controller before calling this
        return petRepository.save(pet);
    }
}
