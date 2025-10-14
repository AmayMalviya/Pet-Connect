package com.petconnect.service;

import com.petconnect.model.Shelter;
import com.petconnect.repository.ShelterRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ShelterService {

    private final ShelterRepository shelterRepository;

    public ShelterService(ShelterRepository shelterRepository) {
        this.shelterRepository = shelterRepository;
    }

    public Optional<Shelter> getShelter(String id) {
        return shelterRepository.findById(id);
    }

    public Shelter saveShelter(Shelter shelter) {
        return shelterRepository.save(shelter);
    }
}
