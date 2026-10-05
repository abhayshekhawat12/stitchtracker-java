package com.stitchtrack.util;
import org.mindrot.jbcrypt.BCrypt;
public class TestHash {
    public static void main(String[] args) {
        String adminHash = "$2a$12$t4CA0/DV/bcysq8CHp/K5Ou5jD8WeqOLNhCuGr8RF/J8MwKdzHMeW";
        String staffHash = "$2a$12$H1PlJ/Tu.hjuUrTiqS9LwOikMCgGqLkrsK8V5u2FfsrJc3MONg.b.";
        System.out.println("Admin pw check : " + BCrypt.checkpw("stitchtracker56@", adminHash));
        System.out.println("Staff pw check : " + BCrypt.checkpw("laundry@staff123", staffHash));
        // Generate fresh hashes
        System.out.println("NEW_ADMIN_HASH=" + BCrypt.hashpw("stitchtracker56@", BCrypt.gensalt(12)));
        System.out.println("NEW_STAFF_HASH=" + BCrypt.hashpw("laundry@staff123", BCrypt.gensalt(12)));
    }
}
