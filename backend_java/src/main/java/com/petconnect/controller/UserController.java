package com.petconnect.controller;

import com.google.firebase.auth.FirebaseToken;
import com.petconnect.model.User;
import com.petconnect.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/sync")
    public ResponseEntity<User> synchronizeUser(@AuthenticationPrincipal FirebaseToken decodedToken) {
        User synchronizedUser = userService.synchronizeUser(decodedToken);
        return ResponseEntity.ok(synchronizedUser);
    }

    @GetMapping("/me")
    public ResponseEntity<User> getUserProfile(@AuthenticationPrincipal FirebaseToken decodedToken) {
        Optional<User> userOptional = userService.getUser(decodedToken.getUid());
        return userOptional
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
