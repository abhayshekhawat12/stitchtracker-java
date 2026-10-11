package com.stitchtrack.controller;
import com.stitchtrack.dao.*;import com.stitchtrack.model.User;import com.stitchtrack.util.ServletUtil;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;import java.security.SecureRandom;
@WebServlet({"/admin/action", "/admin/actions"})
public class AdminActionServlet extends HttpServlet {
    private final UserDAO users = new UserDAO();
    private final LaundryDAO laundry = new LaundryDAO();
    private final SupportDAO support = new SupportDAO();
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
                case "stage" -> laundry.updateStage(ServletUtil.longParam(r, "orderId"), r.getParameter("stage"));
                case "renewal" -> support.resolveRenewal(ServletUtil.longParam(r, "requestId"), Boolean.parseBoolean(r.getParameter("approve")), r.getParameter("notes"));
                case "complaint" -> support.resolveComplaint(ServletUtil.longParam(r, "complaintId"), r.getParameter("notes"));
                default -> throw new IllegalArgumentException("Unknown action: " + a);
            }
            support.audit(admin.getId(), admin.getRole(), "Admin Action", a, r.getRemoteAddr());
            ServletUtil.flash(r, "success", "Action completed successfully.");
        } catch (Exception e) {
            ServletUtil.flash(r, "error", e.getMessage());
        }

        String tab = r.getParameter("tab");
        String redirect = r.getContextPath() + "/admin/dashboard" + (tab != null && !tab.isBlank() ? "?tab=" + tab : "");
        s.sendRedirect(redirect);
    }
}
