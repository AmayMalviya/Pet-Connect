package com.petconnect.service;

import com.petconnect.model.User;
import com.petconnect.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.util.Optional;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User synchronizeUser(Principal principal) {
        // TODO: This is a temporary implementation. 
        // Replace with proper user synchronization logic based on Supabase JWT claims.
        // You will need to parse the JWT to get user details like email, etc.
        String uid = principal.getName();
        Optional<User> existingUser = userRepository.findById(uid);

        if (existingUser.isPresent()) {
            return existingUser.get();
        } else {
            User newUser = new User();
            newUser.setUid(uid);
            // newUser.setEmail(principal.getEmail()); // Cannot get email from principal directly
            // newUser.setDisplayName(principal.getName());
            return userRepository.save(newUser);
        }
    }

    public Optional<User> getUser(String uid) {
        return userRepository.findById(uid);
    }

    public Optional<User> updateUserPhoto(String uid, String photoUrl) {
        Optional<User> userOptional = userRepository.findById(uid);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setPhotoUrl(photoUrl);
            return Optional.of(userRepository.save(user));
        }
        return Optional.empty();
    }
}
