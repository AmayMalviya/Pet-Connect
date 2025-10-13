package com.petconnect.controller;

import com.petconnect.model.Pet;
import com.petconnect.service.PetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/pets")
public class PetController {

    @Autowired
    private PetService petService;

    @PostMapping("/add")
    public String addPet(@RequestBody Pet pet) throws ExecutionException, InterruptedException {
        return petService.addPet(pet);
    }

    @GetMapping("/owner/{ownerUid}")
    public List<Pet> getPetsByOwnerUid(@PathVariable String ownerUid) throws ExecutionException, InterruptedException {
        return petService.getPetsByOwnerUid(ownerUid);
    }
}
