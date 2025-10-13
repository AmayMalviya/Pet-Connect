package com.petconnect.service;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import com.google.firebase.cloud.FirestoreClient;
import com.petconnect.model.Pet;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class PetService {

    public String addPet(Pet pet) throws ExecutionException, InterruptedException {
        Firestore dbFirestore = FirestoreClient.getFirestore();
        ApiFuture<WriteResult> collectionsApiFuture = dbFirestore.collection("pets").document(pet.getName()).set(pet);
        return collectionsApiFuture.get().getUpdateTime().toString();
    }

    public List<Pet> getPetsByOwnerUid(String ownerUid) throws ExecutionException, InterruptedException {
        Firestore dbFirestore = FirestoreClient.getFirestore();
        ApiFuture<QuerySnapshot> future = dbFirestore.collection("pets").whereEqualTo("ownerUid", ownerUid).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();
        List<Pet> pets = new ArrayList<>();
        for (QueryDocumentSnapshot document : documents) {
            pets.add(document.toObject(Pet.class));
        }
        return pets;
    }
}
