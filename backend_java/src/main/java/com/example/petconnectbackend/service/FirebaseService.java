package com.example.petconnectbackend.service;

import java.io.FileInputStream;
import java.io.IOException;

import javax.annotation.PostConstruct;

import org.springframework.stereotype.Service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

@Service
public class FirebaseService {

    private FirebaseDatabase firebaseDatabase;

    @PostConstruct
    public void initialize() {
        try {
            FileInputStream serviceAccount =
                    new FileInputStream("/Users/amaymalviya/Documents/Development/Key"); // TODO: Add your service account key

            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .setDatabaseUrl("https://pet-connect-7c145-default-rtdb.firebaseio.com") // TODO: Add your database URL
                    .build();

            FirebaseApp.initializeApp(options);
            firebaseDatabase = FirebaseDatabase.getInstance();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public DatabaseReference getDatabaseReference() {
        return firebaseDatabase.getReference();
    }
}
