package com.stitchtrack.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public final class DBConnection {
    private static final String DEFAULT_URL = "jdbc:mysql://localhost:3306/stitchtrack_java?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata";
    private DBConnection() {}

    static {
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
        catch (ClassNotFoundException e) { throw new ExceptionInInitializerError(e); }
    }

    public static Connection getConnection() throws SQLException {
        String url = value("STITCHTRACK_DB_URL", DEFAULT_URL);
        String user = value("STITCHTRACK_DB_USER", "root");
        String password = value("STITCHTRACK_DB_PASSWORD", "root");
        return DriverManager.getConnection(url, user, password);
    }

    private static String value(String key, String fallback) {
        String v = System.getenv(key);
        if (v == null || v.isBlank()) v = System.getProperty(key);
        return (v == null || v.isBlank()) ? fallback : v;
    }
}
