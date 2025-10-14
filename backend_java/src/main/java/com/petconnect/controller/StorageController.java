package com.petconnect.controller;

import com.google.firebase.auth.FirebaseToken;
import com.petconnect.model.User;
import com.petconnect.service.StorageService;
import com.petconnect.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Optional;

@RestController
@RequestMapping("/api/storage")
public class StorageController {

    private final StorageService storageService;
    private final UserService userService;

    public StorageController(StorageService storageService, UserService userService) {
        this.storageService = storageService;
        this.userService = userService;
    }

    @PostMapping("/upload")
    public ResponseEntity<User> uploadFile(@RequestParam("file") MultipartFile file, @AuthenticationPrincipal FirebaseToken decodedToken) {
        try {
            String photoUrl = storageService.uploadFile(file);
            Optional<User> updatedUser = userService.updateUserPhoto(decodedToken.getUid(), photoUrl);
            return updatedUser
                    .map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity.status(500).build();
        }
    }
}
