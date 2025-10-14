package com.petconnect.controller;

import com.petconnect.model.Vet;
import com.petconnect.service.VetService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/api/vets")
public class VetController {

    private final VetService vetService;

    public VetController(VetService vetService) {
        this.vetService = vetService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<Vet> getVet(@PathVariable String id) {
        Optional<Vet> vetOptional = vetService.getVet(id);
        return vetOptional
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Vet> saveVet(@RequestBody Vet vet) {
        return ResponseEntity.ok(vetService.saveVet(vet));
    }
}
