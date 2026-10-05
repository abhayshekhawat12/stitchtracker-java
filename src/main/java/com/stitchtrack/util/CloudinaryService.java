package com.stitchtrack.util;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.InputStream;
import java.util.Map;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

public class CloudinaryService {
    private static final Logger logger = LoggerFactory.getLogger(CloudinaryService.class);
    private static final Cloudinary cloudinary;

    static {
        // Initialize Cloudinary with environment variables or fallback values.
        // User should set CLOUDINARY_URL environment variable in production!
        // Format: cloudinary://my_key:my_secret@my_cloud_name
        String url = System.getenv("CLOUDINARY_URL");
        if (url == null || url.isBlank()) {
            logger.warn("CLOUDINARY_URL not set! Image uploads will fail or use fallback. Please configure Cloudinary keys.");
            // Example fallback (invalid by default, needs actual keys)
            cloudinary = new Cloudinary(ObjectUtils.asMap(
                "cloud_name", "YOUR_CLOUD_NAME",
                "api_key", "YOUR_API_KEY",
                "api_secret", "YOUR_API_SECRET"
            ));
        } else {
            cloudinary = new Cloudinary(url);
        }
    }

    /**
     * Uploads an image stream to Cloudinary and returns the secure URL.
     */
    public static String uploadImage(InputStream inputStream, String filename) {
        try {
            // Cloudinary requires a File or byte array. We will save it to a temp file first.
            Path tempFile = Files.createTempFile("cloudinary_upload_", filename);
            Files.copy(inputStream, tempFile, StandardCopyOption.REPLACE_EXISTING);

            Map uploadResult = cloudinary.uploader().upload(tempFile.toFile(), ObjectUtils.emptyMap());
            Files.deleteIfExists(tempFile);

            return (String) uploadResult.get("secure_url");
        } catch (Exception e) {
            logger.error("Failed to upload image to Cloudinary: " + filename, e);
            return null; // Return null on failure so the caller knows it failed
        }
    }
}
