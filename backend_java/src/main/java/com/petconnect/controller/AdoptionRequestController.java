package com.petconnect.controller;

import com.petconnect.model.AdoptionRequest;
import com.petconnect.service.AdoptionRequestService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/adoption-requests")
public class AdoptionRequestController {

    private final AdoptionRequestService adoptionRequestService;

    public AdoptionRequestController(AdoptionRequestService adoptionRequestService) {
        this.adoptionRequestService = adoptionRequestService;
    }

    @GetMapping("/shelter/{shelterOwnerId}")
    public ResponseEntity<List<AdoptionRequest>> getAdoptionRequestsByShelterOwnerId(@PathVariable String shelterOwnerId) {
        return ResponseEntity.ok(adoptionRequestService.getAdoptionRequestsByShelterOwnerId(shelterOwnerId));
    }

    @PostMapping
    public ResponseEntity<AdoptionRequest> createAdoptionRequest(@RequestBody AdoptionRequest adoptionRequest) {
        return ResponseEntity.ok(adoptionRequestService.createAdoptionRequest(adoptionRequest));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<AdoptionRequest> updateAdoptionRequestStatus(@PathVariable Long id, @RequestBody String status) {
        AdoptionRequest updatedRequest = adoptionRequestService.updateAdoptionRequestStatus(id, status);
        if (updatedRequest != null) {
            return ResponseEntity.ok(updatedRequest);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
