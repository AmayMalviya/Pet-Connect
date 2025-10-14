package com.petconnect.service;

import com.petconnect.model.AdoptionRequest;
import com.petconnect.repository.AdoptionRequestRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdoptionRequestService {

    private final AdoptionRequestRepository adoptionRequestRepository;
    private final PetService petService;
    private final UserService userService;

    public AdoptionRequestService(AdoptionRequestRepository adoptionRequestRepository, PetService petService, UserService userService) {
        this.adoptionRequestRepository = adoptionRequestRepository;
        this.petService = petService;
        this.userService = userService;
    }

    public List<AdoptionRequest> getAdoptionRequestsByShelterOwnerId(String shelterOwnerId) {
        List<AdoptionRequest> requests = adoptionRequestRepository.findByShelterOwnerId(shelterOwnerId);
        return requests.stream()
                .map(request -> {
                    request.setPet(petService.getPetById(request.getPetId()));
                    request.setRequester(userService.getUser(request.getRequesterId()).orElse(null));
                    return request;
                })
                .collect(Collectors.toList());
    }

    public AdoptionRequest createAdoptionRequest(AdoptionRequest adoptionRequest) {
        return adoptionRequestRepository.save(adoptionRequest);
    }

    public AdoptionRequest updateAdoptionRequestStatus(Long id, String status) {
        return adoptionRequestRepository.findById(id)
                .map(existingRequest -> {
                    existingRequest.setStatus(status);
                    return adoptionRequestRepository.save(existingRequest);
                })
                .orElse(null);
    }
}
