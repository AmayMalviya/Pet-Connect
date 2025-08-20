package com.example.petconnectbackend.controller;

import com.example.petconnectbackend.service.FirebaseService;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ValueEventListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/pets")
public class PetController {

    @Autowired
    private FirebaseService firebaseService;

    @GetMapping("/has-pet/{userId}")
    public CompletableFuture<Boolean> hasPet(@PathVariable String userId) {
        CompletableFuture<Boolean> future = new CompletableFuture<>();
        DatabaseReference userPetsRef = firebaseService.getDatabaseReference().child("users").child(userId).child("pets");

        userPetsRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                future.complete(dataSnapshot.exists() && dataSnapshot.hasChildren());
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {
                future.completeExceptionally(databaseError.toException());
            }
        });

        return future;
    }
}
