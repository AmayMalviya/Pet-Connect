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

    public Pet getPetById(Long id) {
        return petRepository.findById(id).orElse(null);
    }

    public List<Pet> getPetsByOwnerId(String ownerId) {
        return petRepository.findByOwnerId(ownerId);
    }

    public List<Pet> getPetsByStatus(String status) {
        return petRepository.findByStatus(status);
    }

    public Pet addPet(Pet pet) {
        return petRepository.save(pet);
    }

    public Pet updatePet(Long id, Pet pet) {
        return petRepository.findById(id)
                .map(existingPet -> {
                    existingPet.setName(pet.getName());
                    existingPet.setBreed(pet.getBreed());
                    existingPet.setAge(pet.getAge());
                    return petRepository.save(existingPet);
                })
                .orElse(null);
    }

    public void deletePet(Long id) {
        petRepository.deleteById(id);
    }
}