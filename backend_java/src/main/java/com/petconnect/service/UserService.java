package com.petconnect.service;

import com.google.firebase.auth.FirebaseToken;
import com.petconnect.model.User;
import com.petconnect.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User synchronizeUser(FirebaseToken decodedToken) {
        Optional<User> existingUser = userRepository.findById(decodedToken.getUid());

        if (existingUser.isPresent()) {
            return existingUser.get();
        } else {
            User newUser = new User();
            newUser.setUid(decodedToken.getUid());
            newUser.setEmail(decodedToken.getEmail());
            newUser.setDisplayName(decodedToken.getName());
            return userRepository.save(newUser);
        }
    }

    public Optional<User> getUser(String uid) {
        return userRepository.findById(uid);
    }
}
