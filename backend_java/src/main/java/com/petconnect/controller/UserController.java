package com.petconnect.controller;

import com.petconnect.model.User;
import com.petconnect.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/sync")
    public ResponseEntity<User> synchronizeUser(@AuthenticationPrincipal Principal principal) {
        // TODO: Implement user synchronization with Supabase JWT
        // For now, returning a placeholder or handling it in the service layer
        User synchronizedUser = userService.synchronizeUser(principal);
        return ResponseEntity.ok(synchronizedUser);
    }

    @GetMapping("/me")
    public ResponseEntity<User> getUserProfile(@AuthenticationPrincipal Principal principal) {
        Optional<User> userOptional = userService.getUser(principal.getName());
        return userOptional
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable String id) {
        Optional<User> userOptional = userService.getUser(id);
        return userOptional
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/me/photo")
    public ResponseEntity<User> updateUserPhoto(@AuthenticationPrincipal Principal principal, @RequestBody PhotoUpdateRequest request) {
        Optional<User> updatedUser = userService.updateUserPhoto(principal.getName(), request.getPhotoUrl());
        return updatedUser
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Simple DTO for the request body
    static class PhotoUpdateRequest {
        private String photoUrl;

        public String getPhotoUrl() {
            return photoUrl;
        }

        public void setPhotoUrl(String photoUrl) {
            this.photoUrl = photoUrl;
        }
    }
}