package com.stitchtrack.config;

import java.net.URI;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DBConnection {
    private static final Logger logger = LoggerFactory.getLogger(DBConnection.class);
    private static final String DEFAULT_URL = "jdbc:mysql://localhost:3306/stitchtrack_java?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata";
    private static volatile HikariDataSource dataSource;
    private static final Object lock = new Object();
    private static volatile boolean schemaBootstrapped = false;

    private DBConnection() {}

    private static HikariDataSource getDataSource() throws SQLException {
        HikariDataSource ds = dataSource;
        if (ds == null) {
            synchronized (lock) {
                ds = dataSource;
                if (ds == null) {
                    ds = createDataSource();
                    dataSource = ds;
                }
            }
        }
        return ds;
    }

    public static Connection getConnection() throws SQLException {
        HikariDataSource ds = getDataSource();
        if (!schemaBootstrapped) {
            synchronized (lock) {
                if (!schemaBootstrapped) {
                    autoBootstrapSchema(ds);
                    schemaBootstrapped = true;
                }
            }
        }
        return ds.getConnection();
    }

    private static HikariDataSource createDataSource() throws SQLException {
        String dbUrl = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            HikariConfig config = new HikariConfig();

            // 1. Check for full database connection strings:
            // Checks DATABASE_URL, MYSQL_URL, JDBC_DATABASE_URL, STITCHTRACK_DB_URL
            dbUrl = env("DATABASE_URL", "MYSQL_URL", "JDBC_DATABASE_URL", "STITCHTRACK_DB_URL");
            String dbUser = env("STITCHTRACK_DB_USER", "MYSQLUSER", "MYSQL_USER", "DB_USER");
            String dbPass = env("STITCHTRACK_DB_PASSWORD", "MYSQLPASSWORD", "MYSQL_PASSWORD", "DB_PASSWORD");

            if (dbUrl != null && (dbUrl.startsWith("mysql://") || dbUrl.startsWith("mysql2://"))) {
                // Parse standard cloud mysql:// URLs (e.g. Railway, Render, Clever Cloud, Aiven, TiDB)
                try {
                    String cleanUrl = dbUrl.replace("mysql2://", "").replace("mysql://", "");
                    String query = "";
                    int qIdx = cleanUrl.indexOf('?');
                    if (qIdx != -1) {
                        query = cleanUrl.substring(qIdx + 1);
                        cleanUrl = cleanUrl.substring(0, qIdx);
                    }

                    String userInfo = null;
                    int atIdx = cleanUrl.lastIndexOf('@');
                    if (atIdx != -1) {
                        userInfo = cleanUrl.substring(0, atIdx);
                        cleanUrl = cleanUrl.substring(atIdx + 1);
                    }

                    if (userInfo != null) {
                        int colonIdx = userInfo.indexOf(':');
                        if (colonIdx != -1) {
                            if (dbUser == null || dbUser.isBlank()) dbUser = userInfo.substring(0, colonIdx);
                            if (dbPass == null || dbPass.isBlank()) dbPass = userInfo.substring(colonIdx + 1);
                        } else {
                            if (dbUser == null || dbUser.isBlank()) dbUser = userInfo;
                        }
                    }

                    String host = cleanUrl;
                    int port = 3306;
                    String dbName = "stitchtrack_java";

                    int slashIdx = host.indexOf('/');
                    if (slashIdx != -1) {
                        dbName = host.substring(slashIdx + 1);
                        host = host.substring(0, slashIdx);
                    }

                    int portIdx = host.lastIndexOf(':');
                    if (portIdx != -1) {
                        try {
                            port = Integer.parseInt(host.substring(portIdx + 1));
                            host = host.substring(0, portIdx);
                        } catch (NumberFormatException ignored) {}
                    }

                    StringBuilder jdbcUrl = new StringBuilder("jdbc:mysql://").append(host).append(":").append(port).append("/").append(dbName);
                    jdbcUrl.append("?allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata");
                    if (!query.isBlank()) {
                        jdbcUrl.append("&").append(query);
                    } else {
                        jdbcUrl.append("&useSSL=true");
                    }
                    config.setJdbcUrl(jdbcUrl.toString());
                } catch (Exception ex) {
                    logger.warn("Could not parse URI formatted DB URL, using raw format: {}", dbUrl, ex);
                    config.setJdbcUrl(dbUrl.startsWith("jdbc:") ? dbUrl : "jdbc:" + dbUrl);
                }
            } else if (dbUrl != null && dbUrl.startsWith("jdbc:mysql://")) {
                config.setJdbcUrl(dbUrl);
            } else {
                // 2. Check for individual host/port/database variables
                String host = env("MYSQLHOST", "MYSQL_HOST", "DB_HOST");
                if (host != null && !host.isBlank()) {
                    String port = env("MYSQLPORT", "MYSQL_PORT", "DB_PORT");
                    if (port == null || port.isBlank()) port = "3306";
                    String dbName = env("MYSQLDATABASE", "MYSQL_DATABASE", "DB_NAME");
                    if (dbName == null || dbName.isBlank()) dbName = "stitchtrack_java";

                    String constructed = "jdbc:mysql://" + host + ":" + port + "/" + dbName
                            + "?allowPublicKeyRetrieval=true&useSSL=true&serverTimezone=Asia/Kolkata";
                    config.setJdbcUrl(constructed);
                } else {
                    // Fallback to local default URL
                    config.setJdbcUrl(DEFAULT_URL);
                    if (dbUser == null) dbUser = "root";
                    if (dbPass == null) dbPass = "root";
                }
            }

            if (dbUser != null && !dbUser.isBlank()) config.setUsername(dbUser);
            if (dbPass != null) config.setPassword(dbPass);

            config.setMaximumPoolSize(15);
            config.setMinimumIdle(2);
            config.setIdleTimeout(30000);
            config.setMaxLifetime(1800000);
            config.setConnectionTimeout(20000);
            config.setLeakDetectionThreshold(60000);

            HikariDataSource ds = new HikariDataSource(config);
            logger.info("HikariCP Database Connection Pool initialized successfully for URL: {}", config.getJdbcUrl().replaceAll("://.*@", "://***@"));
            return ds;
        } catch (Exception e) {
            logger.error("Failed to initialize database connection pool", e);
            String hint = (dbUrl != null) ? "Configured DB URL: " + dbUrl.replaceAll("://.*@", "://***@")
                    : "No DATABASE_URL or STITCHTRACK_DB_URL environment variable found. On Render, add DATABASE_URL or STITCHTRACK_DB_URL in the service Environment settings.";
            throw new SQLException("Database connection failed. " + hint + " | Details: " + e.getMessage(), e);
        }
    }

    private static String env(String... keys) {
        for (String k : keys) {
            String v = System.getenv(k);
            if (v != null && !v.isBlank()) return v.trim();
            v = System.getProperty(k);
            if (v != null && !v.isBlank()) return v.trim();
        }
        return null;
    }

    private static void autoBootstrapSchema(HikariDataSource ds) {
        try (Connection c = ds.getConnection(); Statement s = c.createStatement()) {
            // Create tables if not existing
            s.execute("""
                CREATE TABLE IF NOT EXISTS users (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  name VARCHAR(120) NOT NULL,
                  roll_number VARCHAR(50) UNIQUE,
                  email VARCHAR(160) NOT NULL UNIQUE,
                  phone VARCHAR(30),
                  hostel VARCHAR(100),
                  room_no VARCHAR(30),
                  password_hash VARCHAR(100) NOT NULL,
                  gender VARCHAR(20),
                  membership_limit INT NOT NULL DEFAULT 0,
                  membership_used INT NOT NULL DEFAULT 0,
                  quota_reset_date DATE,
                  account_status VARCHAR(40) NOT NULL DEFAULT 'Pending Verification',
                  verification_status VARCHAR(30) NOT NULL DEFAULT 'Pending',
                  renewal_status VARCHAR(30) NOT NULL DEFAULT 'None',
                  role VARCHAR(20) NOT NULL DEFAULT 'STUDENT',
                  profile_photo VARCHAR(255),
                  id_card VARCHAR(255),
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_user_role(role), INDEX idx_user_status(account_status)
                )
            """);

            s.execute("""
                CREATE TABLE IF NOT EXISTS laundry_orders (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  order_number VARCHAR(40) NOT NULL UNIQUE,
                  student_id BIGINT NOT NULL,
                  bag_number VARCHAR(30),
                  qr_token VARCHAR(120) UNIQUE,
                  qr_status VARCHAR(20) NOT NULL DEFAULT 'none',
                  total_items INT NOT NULL DEFAULT 0,
                  total_credits INT NOT NULL DEFAULT 0,
                  scale_weight_kg DECIMAL(5,2),
                  status VARCHAR(40) NOT NULL DEFAULT 'Pending Approval',
                  current_stage VARCHAR(60) NOT NULL DEFAULT 'Pending Approval',
                  accepted_by BIGINT,
                  accepted_at TIMESTAMP NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  estimated_completion TIMESTAMP NULL,
                  delivered_at TIMESTAMP NULL,
                  INDEX idx_order_student(student_id), INDEX idx_order_status(status), INDEX idx_order_bag(bag_number)
                )
            """);

            s.execute("""
                CREATE TABLE IF NOT EXISTS laundry_items (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  order_id BIGINT NOT NULL,
                  category VARCHAR(60) NOT NULL,
                  item_count INT NOT NULL DEFAULT 0,
                  credit_rate INT NOT NULL DEFAULT 1,
                  credits_consumed INT NOT NULL DEFAULT 0,
                  INDEX idx_item_order(order_id)
                )
            """);

            s.execute("""
                CREATE TABLE IF NOT EXISTS renewal_requests (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  student_id BIGINT NOT NULL,
                  requested_credits INT NOT NULL DEFAULT 200,
                  status VARCHAR(20) NOT NULL DEFAULT 'Pending',
                  staff_notes VARCHAR(500),
                  requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  resolved_at TIMESTAMP NULL,
                  INDEX idx_renew_status(status)
                )
            """);

            s.execute("""
                CREATE TABLE IF NOT EXISTS complaints (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  student_id BIGINT NOT NULL,
                  order_id BIGINT NULL,
                  bag_number VARCHAR(30),
                  category VARCHAR(40) NOT NULL,
                  issue_type VARCHAR(100) NOT NULL,
                  description VARCHAR(1000),
                  status VARCHAR(20) NOT NULL DEFAULT 'Unresolved',
                  resolution_notes VARCHAR(1000),
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  resolved_at TIMESTAMP NULL,
                  INDEX idx_complaint_status(status)
                )
            """);

            s.execute("""
                CREATE TABLE IF NOT EXISTS audit_logs (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  actor_id BIGINT NULL,
                  actor_role VARCHAR(30),
                  action VARCHAR(120) NOT NULL,
                  details VARCHAR(1200),
                  ip_address VARCHAR(80),
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_audit_created(created_at)
                )
            """);

            s.execute("""
                CREATE TABLE IF NOT EXISTS notifications (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  title VARCHAR(150) NOT NULL,
                  message VARCHAR(600) NOT NULL,
                  is_read BOOLEAN NOT NULL DEFAULT FALSE,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_notif_user(user_id)
                )
            """);

            // Insert default Admin and Staff if not already present
            s.execute("""
                INSERT IGNORE INTO users(name, roll_number, email, password_hash, hostel, room_no, membership_limit, membership_used, account_status, verification_status, role)
                VALUES ('Facility Admin','STAFF-01','stitchtrackeradmin@gmail.com','$2a$12$t4CA0/DV/bcysq8CHp/K5Ou5jD8WeqOLNhCuGr8RF/J8MwKdzHMeW','Laundry Desk','-',9999,0,'Active','Approved','ADMIN')
            """);

            s.execute("""
                INSERT IGNORE INTO users(name, roll_number, email, password_hash, hostel, room_no, membership_limit, membership_used, account_status, verification_status, role)
                VALUES ('Laundry Staff','STAFF-02','laundrystaff@stitchtrack.com','$2a$12$H1PlJ/Tu.hjuUrTiqS9LwOikMCgGqLkrsK8V5u2FfsrJc3MONg.b.','Laundry Room','Counter-1',9999,0,'Active','Approved','STAFF')
            """);

            // Safely add credit columns to existing tables (ALTER IF NOT EXISTS – MySQL 8.0.3+)
            try { s.execute("ALTER TABLE laundry_orders ADD COLUMN IF NOT EXISTS total_credits INT NOT NULL DEFAULT 0"); } catch(Exception ignored){}
            try { s.execute("ALTER TABLE laundry_items ADD COLUMN IF NOT EXISTS credit_rate INT NOT NULL DEFAULT 1"); } catch(Exception ignored){}
            try { s.execute("ALTER TABLE laundry_items ADD COLUMN IF NOT EXISTS credits_consumed INT NOT NULL DEFAULT 0"); } catch(Exception ignored){}
            // Safely add free_quota_assigned column
            try { s.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS free_quota_assigned TINYINT(1) NOT NULL DEFAULT 0"); } catch(Exception ignored){}

            logger.info("Database schema verification and bootstrap completed successfully.");
        } catch (Exception e) {
            logger.warn("Database auto-bootstrap skipped or encountered error (tables may already exist): {}", e.getMessage());
        }

        try {
            com.stitchtrack.dao.SubscriptionDAO.ensureSchema();
        } catch (Exception e) {
            logger.warn("Subscription schema bootstrap skipped: {}", e.getMessage());
        }
    }
}
