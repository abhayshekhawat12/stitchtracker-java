package com.stitchtrack.controller;

import com.stitchtrack.dao.LaundryDAO;
import com.stitchtrack.dao.UserDAO;
import com.stitchtrack.model.LaundryOrder;
import com.stitchtrack.model.User;
import com.stitchtrack.util.ServletUtil;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * Staff QR scanner — GET shows scanner page,
 * POST with a token looks up the order and student details, then shows result.
 * Actual delivery is done via StaffActionServlet (POST /staff/action?action=deliver).
 */
@WebServlet("/staff/scanner")
public class StaffScannerServlet extends HttpServlet {
    private final LaundryDAO laundry = new LaundryDAO();
    private final UserDAO users = new UserDAO();

    protected void doGet(HttpServletRequest r, HttpServletResponse s)
            throws ServletException, IOException {
        r.getRequestDispatcher("/WEB-INF/views/staff-scanner.jsp").forward(r, s);
    }

    protected void doPost(HttpServletRequest r, HttpServletResponse s)
            throws ServletException, IOException {
        String token = r.getParameter("token");
        if (token == null || token.isBlank()) {
            r.setAttribute("error", "Please provide or scan a QR token.");
            doGet(r, s);
            return;
        }
        try {
            LaundryOrder order = laundry.findByQr(token.trim());
            if (order == null) {
                r.setAttribute("error", "No order found for this QR token.");
            } else {
                User student = users.findById(order.getStudentId());
                r.setAttribute("order", order);
                r.setAttribute("student", student);
                // Check if deliverable
                boolean canDeliver = "unused".equalsIgnoreCase(order.getQrStatus())
                        && "Ready".equals(order.getStatus());
                r.setAttribute("canDeliver", canDeliver);
                if (!canDeliver) {
                    String why;
                    if ("Delivered".equals(order.getStatus()) || "used".equalsIgnoreCase(order.getQrStatus())) {
                        why = "⚠️ This order has already been delivered.";
                    } else {
                        why = "⚠️ This order is not yet ready for pickup (Current stage: " + order.getCurrentStage() + ").";
                    }
                    r.setAttribute("warning", why);
                }
            }
        } catch (Exception e) {
            r.setAttribute("error", "Error: " + e.getMessage());
        }
        doGet(r, s);
    }
}
