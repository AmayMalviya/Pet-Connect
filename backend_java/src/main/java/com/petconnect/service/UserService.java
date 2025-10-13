package com.petconnect.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    public UserRecord getUserDetails(String uid) throws FirebaseAuthException {
        return FirebaseAuth.getInstance().getUser(uid);
    }
}
