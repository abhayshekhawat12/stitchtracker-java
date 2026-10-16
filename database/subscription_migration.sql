-- =====================================================================
-- StitchTrack Subscription System Migration
-- Run this AFTER the base stitchtrack_mysql.sql schema is already applied.
-- =====================================================================

USE stitchtrack_java;

-- ----------------------------------------------------------------
-- 1. Add subscription tracking column to users table
--    free_quota_assigned: prevents giving free 50 clothes more than once
-- ----------------------------------------------------------------
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS free_quota_assigned TINYINT(1) NOT NULL DEFAULT 0;

-- ----------------------------------------------------------------
-- 2. Update existing students: mark as already assigned so legacy
--    accounts don't get an extra free credit on next login.
-- ----------------------------------------------------------------
UPDATE users
  SET free_quota_assigned = 1
  WHERE role = 'STUDENT' AND membership_limit > 0 AND free_quota_assigned = 0;

-- ----------------------------------------------------------------
-- 3. subscription_plans - catalogue of available plans
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscription_plans (
  id              INT PRIMARY KEY AUTO_INCREMENT,
  plan_name       VARCHAR(80)    NOT NULL,
  price_inr       INT            NOT NULL DEFAULT 0,
  clothes_added   INT            NOT NULL DEFAULT 0,
  is_free         TINYINT(1)     NOT NULL DEFAULT 0,
  display_order   INT            NOT NULL DEFAULT 0,
  is_active       TINYINT(1)     NOT NULL DEFAULT 1,
  created_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO subscription_plans (id, plan_name, price_inr, clothes_added, is_free, display_order)
VALUES
  (1, 'Free Starter',   0,   50, 1, 1),
  (2, 'Basic Pack',   200,   50, 0, 2),
  (3, 'Standard Pack',350,  100, 0, 3),
  (4, 'Premium Pack', 600,  200, 0, 4);

-- ----------------------------------------------------------------
-- 4. subscription_transactions - payment & quota history
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscription_transactions (
  id                  BIGINT        PRIMARY KEY AUTO_INCREMENT,
  student_id          BIGINT        NOT NULL,
  plan_id             INT           NOT NULL,
  razorpay_order_id   VARCHAR(120)  UNIQUE,
  razorpay_payment_id VARCHAR(120),
  razorpay_signature  VARCHAR(256),
  amount_inr          INT           NOT NULL DEFAULT 0,
  clothes_credited    INT           NOT NULL DEFAULT 0,
  payment_status      VARCHAR(30)   NOT NULL DEFAULT 'PENDING',
  credited            TINYINT(1)    NOT NULL DEFAULT 0,
  transaction_ref     VARCHAR(120)  UNIQUE NOT NULL,
  created_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (plan_id)    REFERENCES subscription_plans(id),
  INDEX idx_sub_student(student_id),
  INDEX idx_sub_status(payment_status)
);
