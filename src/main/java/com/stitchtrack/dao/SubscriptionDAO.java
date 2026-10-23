package com.stitchtrack.dao;

import com.stitchtrack.config.DBConnection;
import com.stitchtrack.model.SubscriptionPlan;
import com.stitchtrack.model.SubscriptionTransaction;
import java.sql.*;
import java.util.*;

/**
 * SubscriptionDAO handles:
 *  - Auto-bootstrapping the subscription schema at first access.
 *  - Free quota assignment (once per student account).
 *  - Fetching subscription plans.
 *  - Creating Razorpay orders and verifying payment signatures.
 *  - Crediting quota to users after successful payment.
 *  - Fetching transaction history for student and admin dashboards.
 */
public class SubscriptionDAO {

    // ---------------------------------------------------------------
    // Schema bootstrap – called once at app start from DBConnection,
    // and also lazily on first DAO usage so tests work standalone.
    // ---------------------------------------------------------------
    public static void ensureSchema() {
        try (Connection c = DBConnection.getConnection()) {
            ensureSchema(c);
        } catch (Exception e) {
            System.err.println("[SubscriptionDAO] Schema bootstrap warning: " + e.getMessage());
        }
    }

    public static void ensureSchema(Connection c) {
        try (Statement s = c.createStatement()) {
            // free_quota_assigned column (MySQL syntax: ALTER without IF NOT EXISTS)
            try {
                s.execute("ALTER TABLE users ADD COLUMN free_quota_assigned TINYINT(1) NOT NULL DEFAULT 0");
            } catch (SQLException ignored) {}

            s.execute("""
                CREATE TABLE IF NOT EXISTS subscription_plans (
                  id            INT PRIMARY KEY AUTO_INCREMENT,
                  plan_name     VARCHAR(80)  NOT NULL,
                  price_inr     INT          NOT NULL DEFAULT 0,
                  clothes_added INT          NOT NULL DEFAULT 0,
                  is_free       TINYINT(1)   NOT NULL DEFAULT 0,
                  display_order INT          NOT NULL DEFAULT 0,
                  is_active     TINYINT(1)   NOT NULL DEFAULT 1,
                  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
            """);

            s.execute("INSERT IGNORE INTO subscription_plans (id,plan_name,price_inr,clothes_added,is_free,display_order) VALUES (1,'Free Starter',0,50,1,1)");
            s.execute("INSERT IGNORE INTO subscription_plans (id,plan_name,price_inr,clothes_added,is_free,display_order) VALUES (2,'Basic Pack',200,50,0,2)");
            s.execute("INSERT IGNORE INTO subscription_plans (id,plan_name,price_inr,clothes_added,is_free,display_order) VALUES (3,'Standard Pack',350,100,0,3)");
            s.execute("INSERT IGNORE INTO subscription_plans (id,plan_name,price_inr,clothes_added,is_free,display_order) VALUES (4,'Premium Pack',600,200,0,4)");

            s.execute("""
                CREATE TABLE IF NOT EXISTS subscription_transactions (
                  id                  BIGINT       PRIMARY KEY AUTO_INCREMENT,
                  student_id          BIGINT       NOT NULL,
                  plan_id             INT          NOT NULL,
                  razorpay_order_id   VARCHAR(120) UNIQUE,
                  razorpay_payment_id VARCHAR(120),
                  razorpay_signature  VARCHAR(256),
                  amount_inr          INT          NOT NULL DEFAULT 0,
                  clothes_credited    INT          NOT NULL DEFAULT 0,
                  payment_status      VARCHAR(30)  NOT NULL DEFAULT 'PENDING',
                  credited            TINYINT(1)   NOT NULL DEFAULT 0,
                  transaction_ref     VARCHAR(120) UNIQUE NOT NULL,
                  utr_number          VARCHAR(120),
                  payment_screenshot  VARCHAR(500),
                  created_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  updated_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
                  FOREIGN KEY (plan_id)    REFERENCES subscription_plans(id),
                  INDEX idx_sub_student(student_id),
                  INDEX idx_sub_status(payment_status)
                )
            """);

            try { s.execute("ALTER TABLE subscription_transactions ADD COLUMN payment_screenshot VARCHAR(500)"); } catch (Exception ignored) {}
            try { s.execute("ALTER TABLE subscription_transactions ADD COLUMN utr_number VARCHAR(120)"); } catch (Exception ignored) {}

        } catch (Exception e) {
            // Log but do not crash startup – tables may already exist
            System.err.println("[SubscriptionDAO] Schema bootstrap warning: " + e.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // Free Quota Assignment
    // Called from LoginServlet right after a student authenticates.
    // Returns the number of clothes credited (50 if first time, else 0).
    // Uses a DB transaction + row-level lock to prevent double-credit.
    // ---------------------------------------------------------------
    public int assignFreeQuotaIfNeeded(long studentId) throws SQLException {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                int alreadyAssigned;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT free_quota_assigned FROM users WHERE id=? FOR UPDATE")) {
                    q.setLong(1, studentId);
                    try (ResultSet r = q.executeQuery()) {
                        if (!r.next()) { c.rollback(); return 0; }
                        alreadyAssigned = r.getInt(1);
                    }
                }
                if (alreadyAssigned == 1) { c.rollback(); return 0; }

                // Get plan details for Free Starter (id=1)
                int freeClothes = 50;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT clothes_added FROM subscription_plans WHERE id=1")) {
                    try (ResultSet r = q.executeQuery()) {
                        if (r.next()) freeClothes = r.getInt(1);
                    }
                }

                // Credit quota and mark assigned
                try (PreparedStatement p = c.prepareStatement(
                        "UPDATE users SET membership_limit = membership_limit + ?, free_quota_assigned = 1 WHERE id=?")) {
                    p.setInt(1, freeClothes);
                    p.setLong(2, studentId);
                    p.executeUpdate();
                }

                // Record transaction
                String ref = "FREE-" + studentId + "-" + System.currentTimeMillis();
                try (PreparedStatement p = c.prepareStatement(
                        "INSERT INTO subscription_transactions(student_id,plan_id,amount_inr,clothes_credited,payment_status,credited,transaction_ref) VALUES(?,1,0,?,?,1,?)")) {
                    p.setLong(1, studentId);
                    p.setInt(2, freeClothes);
                    p.setString(3, "FREE");
                    p.setString(4, ref);
                    p.executeUpdate();
                }

                c.commit();
                return freeClothes;
            } catch (Exception e) {
                c.rollback();
                if (e instanceof SQLException se) throw se;
                throw new SQLException(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    // ---------------------------------------------------------------
    // Fetch active plans (ordered for display)
    // ---------------------------------------------------------------
    public List<SubscriptionPlan> getActivePlans() throws SQLException {
        List<SubscriptionPlan> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement p = c.prepareStatement(
                     "SELECT * FROM subscription_plans WHERE is_active=1 ORDER BY display_order");
             ResultSet r = p.executeQuery()) {
            while (r.next()) list.add(mapPlan(r));
        }
        return list;
    }

    public SubscriptionPlan getPlanById(int planId) throws SQLException {
        try (Connection c = DBConnection.getConnection();
             PreparedStatement p = c.prepareStatement("SELECT * FROM subscription_plans WHERE id=?")) {
            p.setInt(1, planId);
            try (ResultSet r = p.executeQuery()) {
                return r.next() ? mapPlan(r) : null;
            }
        }
    }

    // ---------------------------------------------------------------
    // Razorpay: create a pending order record before redirecting
    // ---------------------------------------------------------------
    public long createPendingOrder(long studentId, int planId, int amountInr,
                                    int clothesAdded, String razorpayOrderId) throws SQLException {
        String ref = "RZP-" + razorpayOrderId;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement p = c.prepareStatement(
                     "INSERT INTO subscription_transactions(student_id,plan_id,razorpay_order_id,amount_inr,clothes_credited,payment_status,credited,transaction_ref) VALUES(?,?,?,?,?,'PENDING',0,?)",
                     Statement.RETURN_GENERATED_KEYS)) {
            p.setLong(1, studentId);
            p.setInt(2, planId);
            p.setString(3, razorpayOrderId);
            p.setInt(4, amountInr);
            p.setInt(5, clothesAdded);
            p.setString(6, ref);
            p.executeUpdate();
            try (ResultSet k = p.getGeneratedKeys()) {
                return k.next() ? k.getLong(1) : 0;
            }
        }
    }

    // ---------------------------------------------------------------
    // Razorpay: verify + credit (idempotent via 'credited' flag)
    // Returns clothes credited (> 0 on success, 0 if already done or failed).
    // ---------------------------------------------------------------
    public int verifyAndCredit(String razorpayOrderId,
                                String razorpayPaymentId,
                                String razorpaySignature,
                                boolean signatureValid) throws SQLException {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                long txId; long studentId; int clothes; int credited;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT id,student_id,clothes_credited,credited FROM subscription_transactions WHERE razorpay_order_id=? FOR UPDATE")) {
                    q.setString(1, razorpayOrderId);
                    try (ResultSet r = q.executeQuery()) {
                        if (!r.next()) { c.rollback(); return 0; }
                        txId = r.getLong("id");
                        studentId = r.getLong("student_id");
                        clothes = r.getInt("clothes_credited");
                        credited = r.getInt("credited");
                    }
                }

                if (credited == 1) { c.rollback(); return 0; } // already processed

                if (!signatureValid) {
                    // Mark as FAILED
                    try (PreparedStatement p = c.prepareStatement(
                            "UPDATE subscription_transactions SET payment_status='FAILED',razorpay_payment_id=?,razorpay_signature=? WHERE id=?")) {
                        p.setString(1, razorpayPaymentId);
                        p.setString(2, razorpaySignature);
                        p.setLong(3, txId);
                        p.executeUpdate();
                    }
                    c.commit();
                    return 0;
                }

                // Mark SUCCESS and credit quota
                try (PreparedStatement p = c.prepareStatement(
                        "UPDATE subscription_transactions SET payment_status='SUCCESS',credited=1,razorpay_payment_id=?,razorpay_signature=? WHERE id=?")) {
                    p.setString(1, razorpayPaymentId);
                    p.setString(2, razorpaySignature);
                    p.setLong(3, txId);
                    p.executeUpdate();
                }
                try (PreparedStatement p = c.prepareStatement(
                        "UPDATE users SET membership_limit = membership_limit + ? WHERE id=?")) {
                    p.setInt(1, clothes);
                    p.setLong(2, studentId);
                    p.executeUpdate();
                }

                c.commit();
                return clothes;
            } catch (Exception e) {
                c.rollback();
                if (e instanceof SQLException se) throw se;
                throw new SQLException(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    // ---------------------------------------------------------------
    // Quota restoration when order is rejected / cancelled
    // ---------------------------------------------------------------
    public void restoreQuotaForOrder(long orderId) throws SQLException {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                long studentId; int items; String status;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT student_id,total_items,status FROM laundry_orders WHERE id=? FOR UPDATE")) {
                    q.setLong(1, orderId);
                    try (ResultSet r = q.executeQuery()) {
                        if (!r.next()) { c.rollback(); return; }
                        studentId = r.getLong("student_id");
                        items = r.getInt("total_items");
                        status = r.getString("status");
                    }
                }
                // Only restore if not already delivered (delivery marks used via deliverByQr)
                if (!"Delivered".equals(status)) {
                    // membership_used is only incremented on delivery, so we don't need to decrement it.
                    // However, if quota was pre-deducted in create() we must restore.
                    // Current create() does NOT pre-deduct; delivery does.
                    // So no restoration needed unless we change that flow.
                    // This method is kept for explicit calls / future use.
                }
                c.commit();
            } catch (Exception e) {
                c.rollback();
                if (e instanceof SQLException se) throw se;
                throw new SQLException(e);
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    // ---------------------------------------------------------------
    // History for student dashboard
    // ---------------------------------------------------------------
    public List<SubscriptionTransaction> getStudentHistory(long studentId) throws SQLException {
        return queryTransactions(
                "SELECT t.*, p.plan_name FROM subscription_transactions t " +
                "JOIN subscription_plans p ON p.id=t.plan_id " +
                "WHERE t.student_id=? ORDER BY t.created_at DESC",
                studentId);
    }

    // ---------------------------------------------------------------
    // History for admin dashboard (all students)
    // ---------------------------------------------------------------
    public List<SubscriptionTransaction> getAllTransactions() throws SQLException {
        return queryTransactions(
                "SELECT t.*, p.plan_name, u.name student_name, u.roll_number student_roll " +
                "FROM subscription_transactions t " +
                "JOIN subscription_plans p ON p.id=t.plan_id " +
                "JOIN users u ON u.id=t.student_id " +
                "ORDER BY t.created_at DESC LIMIT 500");
    }

    // ---------------------------------------------------------------
    // Private helpers
    // ---------------------------------------------------------------
    private List<SubscriptionTransaction> queryTransactions(String sql, Object... params) throws SQLException {
        List<SubscriptionTransaction> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement p = c.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) p.setObject(i + 1, params[i]);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) list.add(mapTx(r));
            }
        }
        return list;
    }

    private SubscriptionPlan mapPlan(ResultSet r) throws SQLException {
        SubscriptionPlan sp = new SubscriptionPlan();
        sp.setId(r.getInt("id"));
        sp.setPlanName(r.getString("plan_name"));
        sp.setPriceInr(r.getInt("price_inr"));
        sp.setClothesAdded(r.getInt("clothes_added"));
        sp.setFree(r.getInt("is_free") == 1);
        sp.setDisplayOrder(r.getInt("display_order"));
        sp.setActive(r.getInt("is_active") == 1);
        return sp;
    }

    // ---------------------------------------------------------------
    // Manual UPI Payment Submission (No Payment Gateway Needed)
    // ---------------------------------------------------------------
    public SubscriptionTransaction submitManualPayment(long studentId, int planId, String utrNumber, String screenshotUrl) throws SQLException {
        SubscriptionPlan plan = getPlanById(planId);
        if (plan == null) throw new IllegalArgumentException("Invalid subscription plan");

        String ref = "UPI-" + System.currentTimeMillis() + "-" + (int)(Math.random() * 9000 + 1000);
        String sql = "INSERT INTO subscription_transactions (student_id, plan_id, amount_inr, clothes_credited, payment_status, credited, transaction_ref, utr_number, payment_screenshot) "
                   + "VALUES (?, ?, ?, ?, 'PENDING_VERIFICATION', 0, ?, ?, ?)";

        try (Connection c = DBConnection.getConnection();
             PreparedStatement p = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            p.setLong(1, studentId);
            p.setInt(2, planId);
            p.setInt(3, plan.getPriceInr());
            p.setInt(4, plan.getClothesAdded());
            p.setString(5, ref);
            p.setString(6, utrNumber != null ? utrNumber.trim() : "");
            p.setString(7, screenshotUrl);
            p.executeUpdate();
            try (ResultSet rs = p.getGeneratedKeys()) {
                if (rs.next()) {
                    long txId = rs.getLong(1);
                    return getTransactionById(txId);
                }
            }
        }
        return null;
    }

    public SubscriptionTransaction getTransactionById(long id) throws SQLException {
        List<SubscriptionTransaction> list = queryTransactions(
                "SELECT t.*, p.plan_name, u.name student_name, u.roll_number student_roll " +
                "FROM subscription_transactions t " +
                "JOIN subscription_plans p ON p.id=t.plan_id " +
                "JOIN users u ON u.id=t.student_id " +
                "WHERE t.id=?", id);
        return list.isEmpty() ? null : list.get(0);
    }

    // ---------------------------------------------------------------
    // Admin Approval & Rejection of Manual UPI Payments
    // ---------------------------------------------------------------
    public boolean approveTransaction(long txId, long adminId) throws SQLException {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                SubscriptionTransaction tx = null;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT t.*, p.plan_name FROM subscription_transactions t "
                      + "JOIN subscription_plans p ON p.id=t.plan_id WHERE t.id=? FOR UPDATE")) {
                    q.setLong(1, txId);
                    try (ResultSet r = q.executeQuery()) {
                        if (r.next()) tx = mapTx(r);
                    }
                }
                if (tx == null || tx.isCredited() || !"PENDING_VERIFICATION".equals(tx.getPaymentStatus())) {
                    c.rollback();
                    return false;
                }

                // 1. Credit clothes quota to student
                try (PreparedStatement upUser = c.prepareStatement(
                        "UPDATE users SET membership_limit = membership_limit + ? WHERE id=?")) {
                    upUser.setInt(1, tx.getClothesCredited());
                    upUser.setLong(2, tx.getStudentId());
                    upUser.executeUpdate();
                }

                // 2. Mark transaction as SUCCESS and credited=1
                try (PreparedStatement upTx = c.prepareStatement(
                        "UPDATE subscription_transactions SET payment_status='SUCCESS', credited=1 WHERE id=?")) {
                    upTx.setLong(1, txId);
                    upTx.executeUpdate();
                }

                // 3. Notification to student
                try (PreparedStatement notif = c.prepareStatement(
                        "INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)")) {
                    notif.setLong(1, tx.getStudentId());
                    notif.setString(2, "🎉 Subscription Approved!");
                    notif.setString(3, "Your payment for " + tx.getPlanName() + " (₹" + tx.getAmountInr() + ") was verified! +"
                            + tx.getClothesCredited() + " clothes added to your quota.");
                    notif.executeUpdate();
                }

                // 4. Audit trail
                try (PreparedStatement audit = c.prepareStatement(
                        "INSERT INTO audit_logs (actor_id, actor_role, action, details) VALUES (?, 'ADMIN', 'Approve Subscription', ?)")) {
                    audit.setLong(1, adminId);
                    audit.setString(2, "Approved subscription tx #" + txId + " (" + tx.getPlanName() + ", ₹" + tx.getAmountInr() + ", " + tx.getClothesCredited() + " credits) for student #" + tx.getStudentId());
                    audit.executeUpdate();
                }

                c.commit();
                return true;
            } catch (Exception ex) {
                c.rollback();
                throw ex;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public boolean rejectTransaction(long txId, long adminId, String reason) throws SQLException {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                SubscriptionTransaction tx = null;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT t.*, p.plan_name FROM subscription_transactions t "
                      + "JOIN subscription_plans p ON p.id=t.plan_id WHERE t.id=? FOR UPDATE")) {
                    q.setLong(1, txId);
                    try (ResultSet r = q.executeQuery()) {
                        if (r.next()) tx = mapTx(r);
                    }
                }
                if (tx == null || tx.isCredited()) {
                    c.rollback();
                    return false;
                }

                try (PreparedStatement upTx = c.prepareStatement(
                        "UPDATE subscription_transactions SET payment_status='REJECTED' WHERE id=?")) {
                    upTx.setLong(1, txId);
                    upTx.executeUpdate();
                }

                try (PreparedStatement notif = c.prepareStatement(
                        "INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)")) {
                    notif.setLong(1, tx.getStudentId());
                    notif.setString(2, "Subscription Payment Rejected");
                    notif.setString(3, "Payment verification for " + tx.getPlanName() + " (Ref: " + tx.getTransactionRef() + ") was rejected. " + (reason != null && !reason.isBlank() ? "Reason: " + reason : "Please recheck the UTR / Screenshot."));
                    notif.executeUpdate();
                }

                try (PreparedStatement audit = c.prepareStatement(
                        "INSERT INTO audit_logs (actor_id, actor_role, action, details) VALUES (?, 'ADMIN', 'Reject Subscription', ?)")) {
                    audit.setLong(1, adminId);
                    audit.setString(2, "Rejected subscription tx #" + txId + " for student #" + tx.getStudentId() + ". Reason: " + reason);
                    audit.executeUpdate();
                }

                c.commit();
                return true;
            } catch (Exception ex) {
                c.rollback();
                throw ex;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private SubscriptionTransaction mapTx(ResultSet r) throws SQLException {
        SubscriptionTransaction t = new SubscriptionTransaction();
        t.setId(r.getLong("id"));
        t.setStudentId(r.getLong("student_id"));
        t.setPlanId(r.getInt("plan_id"));
        t.setAmountInr(r.getInt("amount_inr"));
        t.setClothesCredited(r.getInt("clothes_credited"));
        t.setPaymentStatus(r.getString("payment_status"));
        t.setCredited(r.getInt("credited") == 1);
        t.setTransactionRef(r.getString("transaction_ref"));
        t.setRazorpayOrderId(r.getString("razorpay_order_id"));
        t.setRazorpayPaymentId(r.getString("razorpay_payment_id"));
        t.setCreatedAt(r.getTimestamp("created_at"));
        t.setUpdatedAt(r.getTimestamp("updated_at"));
        try { t.setPaymentScreenshot(r.getString("payment_screenshot")); } catch (SQLException ignored) {}
        try { t.setUtrNumber(r.getString("utr_number")); } catch (SQLException ignored) {}
        // plan_name joined
        try { t.setPlanName(r.getString("plan_name")); } catch (SQLException ignored) {}
        // student info (only in admin query)
        try { t.setStudentName(r.getString("student_name")); } catch (SQLException ignored) {}
        try { t.setStudentRoll(r.getString("student_roll")); } catch (SQLException ignored) {}
        return t;
    }
}
