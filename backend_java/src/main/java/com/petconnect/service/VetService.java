package com.petconnect.service;

import com.petconnect.model.Vet;
import com.petconnect.repository.VetRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class VetService {

    private final VetRepository vetRepository;

    public VetService(VetRepository vetRepository) {
        this.vetRepository = vetRepository;
    }

    public Optional<Vet> getVet(String id) {
        return vetRepository.findById(id);
    }

    public Vet saveVet(Vet vet) {
        return vetRepository.save(vet);
    }
}
