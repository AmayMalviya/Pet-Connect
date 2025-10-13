package com.petconnect.service;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.WriteResult;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.cloud.FirestoreClient;
import com.petconnect.model.User;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutionException;

@Service
public class AuthService {

    public String registerUser(User user) throws FirebaseAuthException, ExecutionException, InterruptedException {
        Firestore dbFirestore = FirestoreClient.getFirestore();
        ApiFuture<WriteResult> collectionsApiFuture = dbFirestore.collection("users").document(user.getUid()).set(user);
        collectionsApiFuture.get(); // Wait for the write to complete
        return user.getUid();
    }

    public FirebaseToken verifyIdToken(String idToken) throws FirebaseAuthException {
        return FirebaseAuth.getInstance().verifyIdToken(idToken);
    }
}
