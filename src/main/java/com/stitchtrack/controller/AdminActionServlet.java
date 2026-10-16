package com.stitchtrack.controller;
import com.stitchtrack.dao.*;import com.stitchtrack.model.User;import com.stitchtrack.util.ServletUtil;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;import java.security.SecureRandom;
@WebServlet({"/admin/action", "/admin/actions"})
public class AdminActionServlet extends HttpServlet {
    private final UserDAO users = new UserDAO();
    private final LaundryDAO laundry = new LaundryDAO();
    private final SupportDAO support = new SupportDAO();
    private final SubscriptionDAO subDao = new SubscriptionDAO();
    private final SecureRandom random = new SecureRandom();

    protected void doPost(HttpServletRequest r, HttpServletResponse s) throws IOException {
        User admin = ServletUtil.user(r);
        if (admin == null || !admin.isAdmin()) {
            s.sendError(HttpServletResponse.SC_FORBIDDEN, "Unauthorized: Admin access required.");
            return;
        }

        String a = r.getParameter("action");
        try {
            switch (a != null ? a : "") {
                case "verify" -> users.setVerification(ServletUtil.longParam(r, "studentId"), Boolean.parseBoolean(r.getParameter("approve")));
                case "accept", "approve" -> {
                    long id = ServletUtil.longParam(r, "orderId");
                    String bag = r.getParameter("bag");
                    String token = "STITCH-" + Long.toHexString(System.nanoTime()).toUpperCase()
                            + Integer.toHexString(random.nextInt()).replace("-", "").toUpperCase();
                    laundry.accept(id, admin.getId(), bag, token);
                }
                case "reject" -> {
                    long id = ServletUtil.longParam(r, "orderId");
                    laundry.reject(id);
                }
                case "order" -> {
                    long id = ServletUtil.longParam(r, "orderId");
                    boolean approve = Boolean.parseBoolean(r.getParameter("approve"));
                    if (approve) {
                        String bag = r.getParameter("bag");
                        String token = "STITCH-" + Long.toHexString(System.nanoTime()).toUpperCase()
                                + Integer.toHexString(random.nextInt()).replace("-", "").toUpperCase();
                        laundry.accept(id, admin.getId(), bag, token);
                    } else {
                        laundry.reject(id);
                    }
                }
                case "stage" -> {
                    long orderId = ServletUtil.longParam(r, "orderId");
                    String stage = r.getParameter("stage");
                    laundry.updateStage(orderId, stage);
                    if ("Ready for Pickup".equalsIgnoreCase(stage)) {
                        ServletUtil.flash(r, "success", "✅ Order #" + orderId + " updated to Ready for Pickup! Click the WhatsApp button to alert student.");
                    } else {
                        ServletUtil.flash(r, "success", "Stage updated to " + stage);
                    }
                }
                case "renewal" -> support.resolveRenewal(ServletUtil.longParam(r, "requestId"), Boolean.parseBoolean(r.getParameter("approve")), r.getParameter("notes"));
                case "complaint" -> support.resolveComplaint(ServletUtil.longParam(r, "complaintId"), r.getParameter("notes"));
                case "approve-sub" -> {
                    long txId = ServletUtil.longParam(r, "txId");
                    boolean ok = subDao.approveTransaction(txId, admin.getId());
                    if (ok) {
                        ServletUtil.flash(r, "success", "✅ Subscription approved! Clothes quota has been added to student's account.");
                    } else {
                        ServletUtil.flash(r, "error", "Transaction could not be approved or was already processed.");
                    }
                }
                case "reject-sub" -> {
                    long txId = ServletUtil.longParam(r, "txId");
                    String reason = r.getParameter("reason");
                    subDao.rejectTransaction(txId, admin.getId(), reason);
                    ServletUtil.flash(r, "success", "Subscription payment request marked as rejected.");
                }
                case "update-own-password" -> {
                    String currentPassword = r.getParameter("currentPassword");
                    String newPassword = r.getParameter("newPassword");
                    String confirmPassword = r.getParameter("confirmPassword");
                    if (currentPassword == null || currentPassword.isBlank()) {
                        throw new IllegalArgumentException("Current password is required.");
                    }
                    if (!users.verifyPassword(admin.getId(), currentPassword)) {
                        throw new IllegalArgumentException("Current password is incorrect.");
                    }
                    if (newPassword == null || newPassword.trim().length() < 6) {
                        throw new IllegalArgumentException("New password must be at least 6 characters.");
                    }
                    if (!newPassword.equals(confirmPassword)) {
                        throw new IllegalArgumentException("New password and confirm password do not match.");
                    }
                    boolean ok = users.updatePassword(admin.getId(), newPassword.trim());
                    if (ok) {
                        ServletUtil.flash(r, "success", "✅ Admin password updated successfully!");
                    } else {
                        throw new IllegalStateException("Failed to update password. Please try again.");
                    }
                }
                case "reset-user-password" -> {
                    long targetUserId = ServletUtil.longParam(r, "targetUserId");
                    String newPassword = r.getParameter("newPassword");
                    String confirmPassword = r.getParameter("confirmPassword");
                    if (targetUserId <= 0) {
                        throw new IllegalArgumentException("Please select a valid user account.");
                    }
                    User target = users.findById(targetUserId);
                    if (target == null) {
                        throw new IllegalArgumentException("User account not found.");
                    }
                    if (newPassword == null || newPassword.trim().length() < 6) {
                        throw new IllegalArgumentException("New password must be at least 6 characters.");
                    }
                    if (confirmPassword != null && !confirmPassword.isBlank() && !newPassword.equals(confirmPassword)) {
                        throw new IllegalArgumentException("Password confirmation does not match.");
                    }
                    boolean ok = users.updatePassword(targetUserId, newPassword.trim());
                    if (ok) {
                        ServletUtil.flash(r, "success", "✅ Password successfully reset for " + target.getName() + " (" + target.getRole() + " - " + (target.getRollNumber() != null ? target.getRollNumber() : target.getEmail()) + ")!");
                    } else {
                        throw new IllegalStateException("Failed to reset password. Please try again.");
                    }
                }
                default -> throw new IllegalArgumentException("Unknown action: " + a);
            }
            support.audit(admin.getId(), admin.getRole(), "Admin Action", a, r.getRemoteAddr());
            if (r.getSession().getAttribute("flash") == null) {
                ServletUtil.flash(r, "success", "Action completed successfully.");
            }
        } catch (Exception e) {
            ServletUtil.flash(r, "error", e.getMessage());
        }

        String tab = r.getParameter("tab");
        String redirect = r.getContextPath() + "/admin/dashboard" + (tab != null && !tab.isBlank() ? "?tab=" + tab : "");
        s.sendRedirect(redirect);
    }
}
