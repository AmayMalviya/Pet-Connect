package com.petconnect.controller;

import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.auth.UserRecord;
import com.petconnect.model.User;
import com.petconnect.service.AuthService;
import com.petconnect.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserService userService;

    @PostMapping("/register")
    public Map<String, String> registerUser(@RequestBody User user) throws FirebaseAuthException, ExecutionException, InterruptedException {
        System.out.println("Received UID: " + user.getUid());
        System.out.println("Received Email: " + user.getEmail());
        System.out.println("Received DisplayName: " + user.getDisplayName());

        String uid = authService.registerUser(user);
        return Collections.singletonMap("uid", uid);
    }

    @PostMapping("/login")
    public Map<String, Object> loginUser(@RequestBody Map<String, String> requestBody) throws FirebaseAuthException {
        String idToken = requestBody.get("idToken");
        FirebaseToken decodedToken = authService.verifyIdToken(idToken);
        return Collections.singletonMap("uid", decodedToken.getUid());
    }

    @GetMapping("/details/{uid}")
    public UserRecord getUserDetails(@PathVariable String uid) throws FirebaseAuthException {
        return userService.getUserDetails(uid);
    }
}
