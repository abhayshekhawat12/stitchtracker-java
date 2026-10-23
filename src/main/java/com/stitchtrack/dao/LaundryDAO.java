package com.stitchtrack.dao;

import com.stitchtrack.config.DBConnection;
import com.stitchtrack.model.LaundryOrder;
import com.stitchtrack.util.CreditRules;
import java.sql.*;
import java.util.*;

/**
 * LaundryDAO — Credit-aware laundry order management.
 *
 * Credit model:
 *   • Normal items (shirts, jeans, etc.) = 1 credit/item.
 *   • Large items (blanket, bedsheet, …) = 3 credits/item.
 *   • membership_used tracks CREDITS (not raw item count).
 *   • Quota is PRE-DEDUCTED at create() and RESTORED on reject/cancel.
 *   • Delivery (deliverByQr) does NOT deduct again — credits already consumed.
 */
public class LaundryDAO {
    private static final String SELECT =
        "SELECT o.*, COALESCE(u.name,'Unknown Student') student_name, " +
        "COALESCE(u.roll_number,'-') student_roll, u.phone student_phone " +
        "FROM laundry_orders o LEFT JOIN users u ON u.id=o.student_id";

    // ---------------------------------------------------------------
    // CREATE — calculates credits server-side, pre-deducts quota
    // ---------------------------------------------------------------
    public long create(long studentId, Map<String,Integer> items) throws SQLException {
        int totalItems  = CreditRules.totalItems(items);
        int totalCredit = CreditRules.totalCredits(items);
        if (totalItems <= 0) throw new SQLException("At least one garment is required.");

        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                // Lock user row and check quota
                int limit, used;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT membership_limit, membership_used FROM users WHERE id=? FOR UPDATE")) {
                    q.setLong(1, studentId);
                    try (ResultSet r = q.executeQuery()) {
                        if (!r.next()) throw new SQLException("Student not found");
                        limit = r.getInt(1); used = r.getInt(2);
                    }
                }
                if (used + totalCredit > limit)
                    throw new SQLException("Insufficient credits. You need " + totalCredit +
                            " credits but only " + Math.max(0, limit - used) + " remain.");

                // Pre-deduct credits
                try (PreparedStatement p = c.prepareStatement(
                        "UPDATE users SET membership_used = membership_used + ? WHERE id=?")) {
                    p.setInt(1, totalCredit); p.setLong(2, studentId); p.executeUpdate();
                }

                // Insert order with total_items and total_credits
                String orderNo = "ST-ORD-" + System.currentTimeMillis(); long orderId;
                try (PreparedStatement p = c.prepareStatement(
                        "INSERT INTO laundry_orders(order_number,student_id,total_items,total_credits,status,current_stage) " +
                        "VALUES(?,?,?,?,'Pending Approval','Pending Approval')",
                        Statement.RETURN_GENERATED_KEYS)) {
                    p.setString(1, orderNo); p.setLong(2, studentId);
                    p.setInt(3, totalItems); p.setInt(4, totalCredit); p.executeUpdate();
                    try (ResultSet k = p.getGeneratedKeys()) { k.next(); orderId = k.getLong(1); }
                }

                // Insert items with credit_rate and credits_consumed
                try (PreparedStatement p = c.prepareStatement(
                        "INSERT INTO laundry_items(order_id,category,item_count,credit_rate,credits_consumed) VALUES(?,?,?,?,?)")) {
                    for (var e : items.entrySet()) {
                        if (e.getValue() > 0) {
                            int rate    = CreditRules.rateFor(e.getKey());
                            int credits = e.getValue() * rate;
                            p.setLong(1, orderId); p.setString(2, e.getKey());
                            p.setInt(3, e.getValue()); p.setInt(4, rate); p.setInt(5, credits);
                            p.addBatch();
                        }
                    }
                    p.executeBatch();
                }

                c.commit(); return orderId;
            } catch (Exception e) {
                c.rollback();
                if (e instanceof SQLException se) throw se;
                throw new SQLException(e);
            } finally { c.setAutoCommit(true); }
        }
    }

    // ---------------------------------------------------------------
    // QUERIES
    // ---------------------------------------------------------------
    public List<LaundryOrder> findByStudent(long sid) throws SQLException {
        return query(SELECT + " WHERE o.student_id=? ORDER BY o.created_at DESC", sid);
    }
    public List<LaundryOrder> findAll() throws SQLException {
        return query(SELECT + " ORDER BY o.created_at DESC");
    }
    public LaundryOrder findById(long id) throws SQLException {
        List<LaundryOrder> x = query(SELECT + " WHERE o.id=?", id);
        return x.isEmpty() ? null : x.get(0);
    }

    // ---------------------------------------------------------------
    // ACCEPT (bag assignment by staff/admin)
    // ---------------------------------------------------------------
    public void accept(long orderId, long staffId, String bagNumber, String qrToken) throws SQLException {
        if (bagNumber == null || bagNumber.isBlank()) bagNumber = String.valueOf(orderId);
        bagNumber = bagNumber.trim();
        if (!bagNumber.matches("\\d+")) throw new SQLException("Bag number must be numeric (e.g. 1, 2, 101).");
        try (Connection c = DBConnection.getConnection()) {
            try (PreparedStatement chk = c.prepareStatement(
                    "SELECT COUNT(*) FROM laundry_orders WHERE UPPER(bag_number)=UPPER(?) AND id!=? AND UPPER(status) NOT IN ('DELIVERED','CANCELLED','REJECTED')")) {
                chk.setString(1, bagNumber); chk.setLong(2, orderId);
                try (ResultSet r = chk.executeQuery()) {
                    r.next(); if (r.getInt(1) > 0) throw new SQLException("This bag is already in use.");
                }
            }
            try (PreparedStatement p = c.prepareStatement(
                    "UPDATE laundry_orders SET bag_number=?,qr_token=?,qr_status='unused',status='Received'," +
                    "current_stage='Received',accepted_by=?,accepted_at=NOW()," +
                    "estimated_completion=DATE_ADD(NOW(),INTERVAL 2 DAY) " +
                    "WHERE id=? AND UPPER(status) IN ('PENDING APPROVAL','PENDING')")) {
                p.setString(1, bagNumber.toUpperCase()); p.setString(2, qrToken);
                p.setLong(3, staffId); p.setLong(4, orderId);
                if (p.executeUpdate() == 0) throw new SQLException("Order is no longer pending approval.");
            }
        }
    }

    // ---------------------------------------------------------------
    // REJECT — restores total_credits to membership_used
    // ---------------------------------------------------------------
    public void reject(long orderId) throws SQLException {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                long studentId; int credits;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT student_id, total_credits FROM laundry_orders WHERE id=? FOR UPDATE")) {
                    q.setLong(1, orderId);
                    try (ResultSet r = q.executeQuery()) {
                        if (!r.next()) throw new SQLException("Order not found");
                        studentId = r.getLong(1);
                        credits   = r.getInt(2);
                        // Legacy rows may have total_credits=0; fall back to total_items
                        if (credits == 0) credits = r.getInt("total_credits"); // already fetched
                    }
                }
                // Fall back for pre-credit-system rows
                if (credits == 0) {
                    try (PreparedStatement q2 = c.prepareStatement(
                            "SELECT COALESCE(SUM(credits_consumed),total_items) val FROM laundry_orders o " +
                            "LEFT JOIN laundry_items i ON i.order_id=o.id WHERE o.id=?")) {
                        q2.setLong(1, orderId);
                        try (ResultSet r2 = q2.executeQuery()) { if (r2.next()) credits = r2.getInt(1); }
                    }
                }

                try (PreparedStatement p = c.prepareStatement(
                        "UPDATE laundry_orders SET status='Rejected',current_stage='Rejected' " +
                        "WHERE id=? AND UPPER(status) IN ('PENDING APPROVAL','PENDING')")) {
                    p.setLong(1, orderId);
                    if (p.executeUpdate() == 0) throw new SQLException("Order is no longer pending approval.");
                }
                // Restore credits
                try (PreparedStatement p = c.prepareStatement(
                        "UPDATE users SET membership_used=GREATEST(0, membership_used-?) WHERE id=?")) {
                    p.setInt(1, credits); p.setLong(2, studentId); p.executeUpdate();
                }
                c.commit();
            } catch (Exception e) {
                c.rollback();
                if (e instanceof SQLException se) throw se;
                throw new SQLException(e);
            } finally { c.setAutoCommit(true); }
        }
        LaundryOrder o = findById(orderId);
        if (o != null) new SupportDAO().notify(o.getStudentId(), "Order Rejected",
            "Your laundry request #" + o.getOrderNumber() + " was rejected. " +
            o.getTotalCredits() + " credits have been restored to your account.");
    }

    // ---------------------------------------------------------------
    // UPDATE STAGE — restores credits on Cancelled/Rejected
    // ---------------------------------------------------------------
    public void updateStage(long orderId, String stage) throws SQLException {
        Set<String> allowed = Set.of("Received","Sorting","Washing","Drying","Ironing",
                "Ready for Pickup","Delivered","Rejected","Cancelled");
        if (!allowed.contains(stage)) throw new SQLException("Invalid stage");

        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                long studentId; int credits; String currentStatus;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT student_id,total_credits,total_items,status FROM laundry_orders WHERE id=? FOR UPDATE")) {
                    q.setLong(1, orderId);
                    try (ResultSet r = q.executeQuery()) {
                        if (!r.next()) throw new SQLException("Order not found");
                        studentId     = r.getLong("student_id");
                        credits       = r.getInt("total_credits");
                        int legacyItems = r.getInt("total_items");
                        currentStatus = r.getString("status");
                        if (credits == 0) credits = legacyItems; // backward compat
                    }
                }

                String status = switch (stage) {
                    case "Received"        -> "Received";
                    case "Ready for Pickup"-> "Ready";
                    case "Delivered"       -> "Delivered";
                    case "Rejected"        -> "Rejected";
                    case "Cancelled"       -> "Cancelled";
                    default                -> "In Progress";
                };
                String sql = "UPDATE laundry_orders SET current_stage=?,status=?" +
                        ("Delivered".equals(stage) ? ",delivered_at=NOW()" : "") + " WHERE id=?";
                try (PreparedStatement p = c.prepareStatement(sql)) {
                    p.setString(1, stage); p.setString(2, status); p.setLong(3, orderId); p.executeUpdate();
                }

                // Restore credits when cancelling or rejecting (only if not already terminal)
                boolean isTerminal = "Delivered".equalsIgnoreCase(currentStatus)
                        || "Cancelled".equalsIgnoreCase(currentStatus)
                        || "Rejected".equalsIgnoreCase(currentStatus);
                if (("Cancelled".equals(stage) || "Rejected".equals(stage)) && !isTerminal) {
                    try (PreparedStatement p = c.prepareStatement(
                            "UPDATE users SET membership_used=GREATEST(0,membership_used-?) WHERE id=?")) {
                        p.setInt(1, credits); p.setLong(2, studentId); p.executeUpdate();
                    }
                }
                c.commit();
            } catch (Exception e) {
                c.rollback();
                if (e instanceof SQLException se) throw se;
                throw new SQLException(e);
            } finally { c.setAutoCommit(true); }
        }

        LaundryOrder o = findById(orderId);
        if (o != null) {
            boolean restored = "Cancelled".equals(stage) || "Rejected".equals(stage);
            String msg = restored
                ? "Your order #" + o.getOrderNumber() + " is now: " + stage + ". " +
                  o.getTotalCredits() + " credits restored to your account."
                : "Your order #" + o.getOrderNumber() + " is now: " + stage;
            new SupportDAO().notify(o.getStudentId(), "Order Update", msg);
        }
    }

    // ---------------------------------------------------------------
    // QR DELIVERY — quota already deducted at create(); no re-deduction
    // ---------------------------------------------------------------
    public LaundryOrder findByQr(String token) throws SQLException {
        List<LaundryOrder> x = query(SELECT + " WHERE o.qr_token=?", token);
        return x.isEmpty() ? null : x.get(0);
    }

    public boolean deliverByQr(String token) throws SQLException {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                long id; String status, qrStatus;
                try (PreparedStatement q = c.prepareStatement(
                        "SELECT id,status,qr_status FROM laundry_orders WHERE qr_token=? FOR UPDATE")) {
                    q.setString(1, token);
                    try (ResultSet r = q.executeQuery()) {
                        if (!r.next()) return false;
                        id = r.getLong(1); status = r.getString(2); qrStatus = r.getString(3);
                    }
                }
                if (!"unused".equalsIgnoreCase(qrStatus) || !"Ready".equals(status)) return false;
                // Credits were pre-deducted at create(); just mark delivered
                try (PreparedStatement p = c.prepareStatement(
                        "UPDATE laundry_orders SET qr_status='used',status='Delivered'," +
                        "current_stage='Delivered',delivered_at=NOW() WHERE id=?")) {
                    p.setLong(1, id); p.executeUpdate();
                }
                c.commit(); return true;
            } catch (Exception e) {
                c.rollback();
                throw e instanceof SQLException ? (SQLException) e : new SQLException(e);
            } finally { c.setAutoCommit(true); }
        }
    }

    // ---------------------------------------------------------------
    // INTERNAL HELPERS
    // ---------------------------------------------------------------
    private List<LaundryOrder> query(String sql, Object... params) throws SQLException {
        List<LaundryOrder> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection(); PreparedStatement p = c.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) p.setObject(i + 1, params[i]);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) { LaundryOrder o = map(r); loadItems(c, o); list.add(o); }
            }
        }
        return list;
    }

    private void loadItems(Connection c, LaundryOrder o) throws SQLException {
        try (PreparedStatement p = c.prepareStatement(
                "SELECT category, item_count FROM laundry_items WHERE order_id=? ORDER BY category")) {
            p.setLong(1, o.getId());
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) o.getItems().put(r.getString("category"), r.getInt("item_count"));
            }
        }
    }

    private LaundryOrder map(ResultSet r) throws SQLException {
        LaundryOrder o = new LaundryOrder();
        o.setId(r.getLong("id")); o.setStudentId(r.getLong("student_id"));
        o.setOrderNumber(r.getString("order_number"));
        o.setStudentName(r.getString("student_name")); o.setStudentRoll(r.getString("student_roll"));
        o.setStudentPhone(r.getString("student_phone"));
        o.setBagNumber(r.getString("bag_number")); o.setQrToken(r.getString("qr_token"));
        o.setQrStatus(r.getString("qr_status")); o.setStatus(r.getString("status"));
        o.setCurrentStage(r.getString("current_stage")); o.setTotalItems(r.getInt("total_items"));
        try { o.setTotalCredits(r.getInt("total_credits")); } catch (SQLException ignored) {}
        o.setCreatedAt(r.getTimestamp("created_at"));
        o.setEstimatedCompletion(r.getTimestamp("estimated_completion"));
        o.setDeliveredAt(r.getTimestamp("delivered_at"));
        return o;
    }
}
