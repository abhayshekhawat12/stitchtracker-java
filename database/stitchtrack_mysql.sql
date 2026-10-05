CREATE DATABASE IF NOT EXISTS stitchtrack_java CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE stitchtrack_java;

SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS complaints;
DROP TABLE IF EXISTS renewal_requests;
DROP TABLE IF EXISTS laundry_items;
DROP TABLE IF EXISTS laundry_orders;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  roll_number VARCHAR(50) UNIQUE,
  email VARCHAR(160) NOT NULL UNIQUE,
  phone VARCHAR(30),
  hostel VARCHAR(100),
  room_no VARCHAR(30),
  password_hash VARCHAR(100) NOT NULL,
  gender VARCHAR(20),
  membership_limit INT NOT NULL DEFAULT 200,
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
);

CREATE TABLE laundry_orders (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_number VARCHAR(40) NOT NULL UNIQUE,
  student_id BIGINT NOT NULL,
  bag_number VARCHAR(30),
  qr_token VARCHAR(120) UNIQUE,
  qr_status VARCHAR(20) NOT NULL DEFAULT 'none',
  total_items INT NOT NULL DEFAULT 0,
  scale_weight_kg DECIMAL(5,2),
  status VARCHAR(40) NOT NULL DEFAULT 'Pending Approval',
  current_stage VARCHAR(60) NOT NULL DEFAULT 'Pending Approval',
  accepted_by BIGINT,
  accepted_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estimated_completion TIMESTAMP NULL,
  delivered_at TIMESTAMP NULL,
  FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(accepted_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_order_student(student_id), INDEX idx_order_status(status), INDEX idx_order_bag(bag_number)
);

CREATE TABLE laundry_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_id BIGINT NOT NULL,
  category VARCHAR(60) NOT NULL,
  item_count INT NOT NULL DEFAULT 0,
  FOREIGN KEY(order_id) REFERENCES laundry_orders(id) ON DELETE CASCADE
);

CREATE TABLE renewal_requests (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  student_id BIGINT NOT NULL,
  requested_credits INT NOT NULL DEFAULT 200,
  status VARCHAR(20) NOT NULL DEFAULT 'Pending',
  staff_notes VARCHAR(500),
  requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_renew_status(status)
);

CREATE TABLE complaints (
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
  FOREIGN KEY(student_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(order_id) REFERENCES laundry_orders(id) ON DELETE SET NULL,
  INDEX idx_complaint_status(status)
);

CREATE TABLE audit_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  actor_id BIGINT NULL,
  actor_role VARCHAR(30),
  action VARCHAR(120) NOT NULL,
  details VARCHAR(1200),
  ip_address VARCHAR(80),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_created(created_at)
);

CREATE TABLE notifications (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  title VARCHAR(150) NOT NULL,
  message VARCHAR(600) NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Passwords are BCrypt hashes.
-- Admin password: stitchtracker56@
INSERT INTO users(name, roll_number, email, password_hash, hostel, room_no, membership_limit, membership_used, account_status, verification_status, role)
VALUES ('Facility Admin','STAFF-01','stitchtrackeradmin@gmail.com','$2a$12$t4CA0/DV/bcysq8CHp/K5Ou5jD8WeqOLNhCuGr8RF/J8MwKdzHMeW','Laundry Desk','-',9999,0,'Active','Approved','ADMIN');

-- Laundry Staff account  |  password: laundry@staff123
-- BCrypt hash of "laundry@staff123" (cost=12)
INSERT INTO users(name,roll_number,email,password_hash,hostel,room_no,membership_limit,membership_used,account_status,verification_status,role)
VALUES ('Laundry Staff','STAFF-02','laundrystaff@stitchtrack.com','$2a$12$H1PlJ/Tu.hjuUrTiqS9LwOikMCgGqLkrsK8V5u2FfsrJc3MONg.b.','Laundry Room','Counter-1',9999,0,'Active','Approved','STAFF');

