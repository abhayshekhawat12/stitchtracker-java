package com.stitchtrack.config;

import java.sql.Connection;
import java.sql.SQLException;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DBConnection {
    private static final Logger logger = LoggerFactory.getLogger(DBConnection.class);
    private static final String DEFAULT_URL = "jdbc:mysql://localhost:3306/stitchtrack_java?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata";
    private static HikariDataSource dataSource;

    private DBConnection() {}

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            HikariConfig config = new HikariConfig();
            config.setJdbcUrl(value("STITCHTRACK_DB_URL", DEFAULT_URL));
            config.setUsername(value("STITCHTRACK_DB_USER", "root"));
            config.setPassword(value("STITCHTRACK_DB_PASSWORD", "root"));
            config.setMaximumPoolSize(20);
            config.setMinimumIdle(5);
            config.setIdleTimeout(30000);
            config.setMaxLifetime(1800000);
            config.setConnectionTimeout(30000);
            
            dataSource = new HikariDataSource(config);
            logger.info("HikariCP Database Connection Pool initialized successfully.");
        } catch (Exception e) {
            logger.error("Failed to initialize database connection pool", e);
            throw new ExceptionInInitializerError(e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    private static String value(String key, String fallback) {
        String v = System.getenv(key);
        if (v == null || v.isBlank()) v = System.getProperty(key);
        return (v == null || v.isBlank()) ? fallback : v;
    }
}
