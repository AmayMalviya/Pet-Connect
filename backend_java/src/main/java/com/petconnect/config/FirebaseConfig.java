package com.petconnect.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;

@Configuration
public class FirebaseConfig {

    @Bean
    public FirebaseApp firebaseApp() throws IOException {
        // IMPORTANT:
        // 1. Download your service account key from the Firebase console.
        // 2. Save it as 'serviceAccountKey.json' in the 'src/main/resources' directory.
        // 3. Make sure the file is not committed to your version control system.
        FileInputStream serviceAccount =
                new FileInputStream("src/main/resources/serviceAccountKey.json");

        FirebaseOptions options = new FirebaseOptions.Builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .setStorageBucket("pet-connect-6ce96.appspot.com") // Replace with your Firebase Storage bucket name
                .build();

        return FirebaseApp.initializeApp(options);
    }
}