package com.petconnect.config;

import com.google.api.client.http.HttpTransport;
import com.google.api.client.http.javanet.NetHttpTransport;
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
        if (FirebaseApp.getApps().isEmpty()) {
            FileInputStream serviceAccount =
                    new FileInputStream("/Users/amaymalviya/Documents/Development/Key/pet-connect-7c145-firebase-adminsdk-fbsvc-b175bbff2e.json");

            HttpTransport httpTransport = new NetHttpTransport.Builder()
                    .setConnectTimeout(60000) // 60 seconds
                    .setReadTimeout(60000)    // 60 seconds
                    .build();

            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .setDatabaseUrl("https://pet-connect-7c145-default-rtdb.firebaseio.com")
                    .setHttpTransport(httpTransport)
                    .build();

            return FirebaseApp.initializeApp(options);
        } else {
            return FirebaseApp.getInstance();
        }
    }
}
