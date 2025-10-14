package com.petconnect.service;

import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.Storage;
import com.google.firebase.cloud.StorageClient;
import org.apache.commons.io.FilenameUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Service
public class StorageService {

    public String uploadFile(MultipartFile file) throws IOException {
        StorageClient storageClient = StorageClient.getInstance();
        String extension = FilenameUtils.getExtension(file.getOriginalFilename());
        String fileName = UUID.randomUUID().toString() + "." + extension;

        BlobId blobId = BlobId.of(storageClient.bucket().getName(), fileName);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId).setContentType(file.getContentType()).build();

        storageClient.bucket().create(fileName, file.getBytes(), file.getContentType());

        return getPublicUrl(fileName);
    }

    private String getPublicUrl(String fileName) {
        // Construct the public URL manually.
        // This assumes that the bucket is public.
        // You might need to adjust this based on your Firebase Storage security rules.
        return "https://storage.googleapis.com/" + StorageClient.getInstance().bucket().getName() + "/" + fileName;
    }
}
