package com.stitchtrack.controller;

import com.stitchtrack.dao.*;
import com.stitchtrack.model.User;
import com.stitchtrack.util.ServletUtil;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * POST /student/payment/verify
 *
 * Called by the frontend after Razorpay checkout completes.
 * Verifies the HMAC-SHA256 signature on the server BEFORE crediting quota.
 * Idempotent: duplicate calls for the same order are silently ignored (credited flag).
 */
@WebServlet("/student/payment/verify")
public class PaymentVerifyServlet extends HttpServlet {

    private final SubscriptionDAO subDao = new SubscriptionDAO();
    private final UserDAO userDAO = new UserDAO();
    private final SupportDAO support = new SupportDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");

        User u = ServletUtil.user(req);
        if (u == null) {
            resp.setStatus(401);
            resp.getWriter().write("{\"error\":\"Not authenticated\"}");
            return;
        }

        String razorpayOrderId   = req.getParameter("razorpay_order_id");
        String razorpayPaymentId = req.getParameter("razorpay_payment_id");
        String razorpaySignature = req.getParameter("razorpay_signature");

        if (razorpayOrderId == null || razorpayPaymentId == null || razorpaySignature == null) {
            resp.setStatus(400);
            resp.getWriter().write("{\"error\":\"Missing payment parameters\"}");
            return;
        }

        try {
            String rzpKeySecret = System.getenv("RAZORPAY_KEY_SECRET");
            if (rzpKeySecret == null) rzpKeySecret = System.getProperty("RAZORPAY_KEY_SECRET");

            if (rzpKeySecret == null || rzpKeySecret.isBlank()) {
                resp.setStatus(503);
                resp.getWriter().write("{\"error\":\"Payment gateway not configured.\"}");
                return;
            }

            boolean signatureValid = RazorpayHelper.verifySignature(
                    razorpayOrderId, razorpayPaymentId, razorpaySignature, rzpKeySecret);

            int clothes = subDao.verifyAndCredit(
                    razorpayOrderId, razorpayPaymentId, razorpaySignature, signatureValid);

            if (!signatureValid) {
                support.audit(u.getId(), u.getRole(), "Payment Failed",
                        "Invalid signature for order " + razorpayOrderId, req.getRemoteAddr());
                resp.setStatus(400);
                resp.getWriter().write("{\"success\":false,\"error\":\"Payment signature verification failed.\"}");
                return;
            }

            if (clothes == 0) {
                // Either already credited (idempotent) or mismatch
                resp.setStatus(200);
                resp.getWriter().write("{\"success\":true,\"message\":\"Already processed\",\"clothesCredited\":0}");
                return;
            }

            // Refresh session with updated quota
            User fresh = userDAO.findById(u.getId());
            if (fresh != null) req.getSession().setAttribute("user", fresh);

            support.audit(u.getId(), u.getRole(), "Subscription Purchase",
                    "+" + clothes + " clothes, order " + razorpayOrderId, req.getRemoteAddr());
            support.notify(u.getId(), "Subscription Activated",
                    "Your quota has been topped up by " + clothes + " clothes. Enjoy!");

            resp.setStatus(200);
            resp.getWriter().write("{\"success\":true,\"clothesCredited\":" + clothes + "}");

        } catch (Exception e) {
            resp.setStatus(500);
            resp.getWriter().write("{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}");
        }
    }
}
