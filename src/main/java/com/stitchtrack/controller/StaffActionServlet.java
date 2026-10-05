package com.stitchtrack.controller;

import com.stitchtrack.dao.LaundryDAO;
import com.stitchtrack.dao.SupportDAO;
import com.stitchtrack.model.User;
import com.stitchtrack.util.ServletUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.security.SecureRandom;

@WebServlet("/staff/action")
public class StaffActionServlet extends HttpServlet {
    private final LaundryDAO laundry = new LaundryDAO();
    private final SupportDAO support = new SupportDAO();
    private final SecureRandom random = new SecureRandom();

    protected void doPost(HttpServletRequest r, HttpServletResponse s) throws IOException {
        User staff = ServletUtil.user(r);
        String action = r.getParameter("action");
        try {
            switch (action) {
                case "accept" -> {
                    long orderId = ServletUtil.longParam(r, "orderId");
                    String token = "STITCH-" + Long.toHexString(System.nanoTime()).toUpperCase()
                            + Integer.toHexString(random.nextInt()).replace("-", "").toUpperCase();
                    laundry.accept(orderId, staff.getId(), r.getParameter("bag"), token);
                    support.audit(staff.getId(), staff.getRole(), "Staff Accept",
                            "Accepted order #" + orderId, r.getRemoteAddr());
                    
                    com.stitchtrack.model.LaundryOrder o = laundry.findById(orderId);
                    if(o != null) {
                        support.notify(o.getStudentId(), "Order Accepted", "Your laundry bag " + r.getParameter("bag") + " has been accepted. QR code generated.");
                    }
                    ServletUtil.flash(r, "success", "Request accepted & QR generated successfully.");
                }
                case "deliver" -> {
                    String token = r.getParameter("token");
                    com.stitchtrack.model.LaundryOrder o = laundry.findByQr(token);
                    boolean ok = laundry.deliverByQr(token);
                    if (ok) {
                        support.audit(staff.getId(), staff.getRole(), "Staff Deliver",
                                "Delivered via QR token", r.getRemoteAddr());
                        if(o != null) {
                            support.notify(o.getStudentId(), "Laundry Delivered", "Your laundry order has been successfully delivered and quota deducted.");
                        }
                        ServletUtil.flash(r, "success", "✅ Laundry marked as DELIVERED successfully.");
                    } else {
                        ServletUtil.flash(r, "error", "Invalid, already-used, or not-ready QR token.");
                    }
                }
                case "stage" -> {
                    long orderId = ServletUtil.longParam(r, "orderId");
                    String stage = r.getParameter("stage");
                    laundry.updateStage(orderId, stage);
                    support.audit(staff.getId(), staff.getRole(), "Staff Update Stage",
                            "Updated order #" + orderId + " to " + stage, r.getRemoteAddr());
                    ServletUtil.flash(r, "success", "Stage updated to " + stage);
                }
                default -> throw new IllegalArgumentException("Unknown action: " + action);
            }
        } catch (Exception e) {
            ServletUtil.flash(r, "error", e.getMessage());
        }
        s.sendRedirect(r.getContextPath() + "/staff/dashboard");
    }
}
