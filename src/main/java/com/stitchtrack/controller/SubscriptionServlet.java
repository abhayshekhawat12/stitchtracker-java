package com.stitchtrack.controller;

import com.stitchtrack.dao.*;
import com.stitchtrack.model.*;
import com.stitchtrack.util.CloudinaryService;
import com.stitchtrack.util.ServletUtil;
import jakarta.servlet.*;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;

/**
 * Handles the Subscription page:
 * - GET: renders subscription.jsp with active plans, UPI details & student purchase history
 * - POST: accepts manual UPI payment submissions (UTR number + screenshot proof)
 *         or creates Razorpay orders if gateway is used.
 */
@WebServlet("/student/subscription")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,       // 10MB
    maxRequestSize = 1024 * 1024 * 20     // 20MB
)
public class SubscriptionServlet extends HttpServlet {

    private final SubscriptionDAO subDao = new SubscriptionDAO();
    private final UserDAO userDAO = new UserDAO();

    private static final String DEFAULT_UPI_ID = "8949690598@ybl";
    private static final String DEFAULT_UPI_NAME = "StitchTrack Facility";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            User u = ServletUtil.user(req);
            User fresh = userDAO.findById(u.getId());
            if (fresh != null) {
                req.getSession().setAttribute("user", fresh);
                req.setAttribute("user", fresh);
            } else {
                req.setAttribute("user", u);
            }

            List<SubscriptionPlan> plans = subDao.getActivePlans();
            List<SubscriptionTransaction> history = subDao.getStudentHistory(u.getId());

            req.setAttribute("plans", plans);
            req.setAttribute("txHistory", history);

            // UPI Payment Configuration (No gateway required)
            String upiId = System.getenv("UPI_ID");
            if (upiId == null || upiId.isBlank()) upiId = System.getProperty("UPI_ID", DEFAULT_UPI_ID);

            String upiName = System.getenv("UPI_PAYEE_NAME");
            if (upiName == null || upiName.isBlank()) upiName = System.getProperty("UPI_PAYEE_NAME", DEFAULT_UPI_NAME);

            req.setAttribute("upiId", upiId);
            req.setAttribute("upiName", upiName);

            // Optional Razorpay credentials if ever set
            String rzpKey = System.getenv("RAZORPAY_KEY_ID");
            if (rzpKey == null) rzpKey = System.getProperty("RAZORPAY_KEY_ID");
            req.setAttribute("razorpayKeyId", rzpKey != null ? rzpKey : "");
            req.setAttribute("razorpayConfigured", rzpKey != null && !rzpKey.isBlank());

            req.getRequestDispatcher("/WEB-INF/views/subscription.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        User u = ServletUtil.user(req);
        if (u == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");
        String contentType = req.getContentType();

        // -------------------------------------------------------------
        // Case 1: Manual UPI Payment Submission (UTR + Screenshot)
        // -------------------------------------------------------------
        if ("manual-upi".equals(action) || (contentType != null && contentType.startsWith("multipart/form-data"))) {
            try {
                String planIdStr = req.getParameter("planId");
                String utr = req.getParameter("utrNumber");

                if (planIdStr == null || planIdStr.isBlank()) {
                    ServletUtil.flash(req, "error", "Please select a valid subscription plan.");
                    resp.sendRedirect(req.getContextPath() + "/student/subscription");
                    return;
                }

                int planId = Integer.parseInt(planIdStr);
                SubscriptionPlan plan = subDao.getPlanById(planId);
                if (plan == null || !plan.isActive() || plan.isFree()) {
                    ServletUtil.flash(req, "error", "Selected subscription plan is not available.");
                    resp.sendRedirect(req.getContextPath() + "/student/subscription");
                    return;
                }

                if (utr == null || utr.trim().length() < 6) {
                    ServletUtil.flash(req, "error", "Please enter a valid 12-digit UPI Reference / UTR Number.");
                    resp.sendRedirect(req.getContextPath() + "/student/subscription");
                    return;
                }

                // Handle payment screenshot file upload
                Part part = req.getPart("screenshot");
                String screenshotUrl = null;

                if (part != null && part.getSize() > 0) {
                    String submittedFileName = Paths.get(part.getSubmittedFileName()).getFileName().toString();
                    String safeFileName = UUID.randomUUID().toString() + "_" + submittedFileName.replaceAll("[^a-zA-Z0-9._-]", "_");

                    // Try Cloudinary first
                    try {
                        screenshotUrl = CloudinaryService.uploadImage(part.getInputStream(), safeFileName);
                    } catch (Exception ex) {
                        screenshotUrl = null;
                    }

                    // Fallback to local storage
                    if (screenshotUrl == null) {
                        String appPath = req.getServletContext().getRealPath("");
                        String basePath = (appPath != null ? appPath : System.getProperty("java.io.tmpdir"));
                        File uploadDir = new File(basePath, "uploads" + File.separator + "payments");
                        if (!uploadDir.exists()) uploadDir.mkdirs();

                        File target = new File(uploadDir, safeFileName);
                        part.write(target.getAbsolutePath());
                        screenshotUrl = "uploads/payments/" + safeFileName;
                    }
                } else {
                    ServletUtil.flash(req, "error", "Please upload a screenshot of your successful UPI payment.");
                    resp.sendRedirect(req.getContextPath() + "/student/subscription");
                    return;
                }

                // Submit manual payment into database
                SubscriptionTransaction tx = subDao.submitManualPayment(u.getId(), planId, utr, screenshotUrl);
                if (tx != null) {
                    ServletUtil.flash(req, "success",
                            "🎉 Payment proof submitted successfully! Ref: " + tx.getTransactionRef() +
                            ". Facility Admin will verify your transaction and credit " + plan.getClothesAdded() + " clothes to your quota.");
                } else {
                    ServletUtil.flash(req, "error", "Failed to submit payment proof. Please try again.");
                }

                resp.sendRedirect(req.getContextPath() + "/student/subscription");
                return;

            } catch (Exception e) {
                ServletUtil.flash(req, "error", "Error submitting payment: " + e.getMessage());
                resp.sendRedirect(req.getContextPath() + "/student/subscription");
                return;
            }
        }

        // -------------------------------------------------------------
        // Case 2: Razorpay JSON API (if gateway ever configured)
        // -------------------------------------------------------------
        resp.setContentType("application/json;charset=UTF-8");
        String planIdStr = req.getParameter("planId");
        try {
            if (planIdStr == null) {
                resp.setStatus(400);
                resp.getWriter().write("{\"error\":\"Missing planId\"}");
                return;
            }
            int planId = Integer.parseInt(planIdStr);
            SubscriptionPlan plan = subDao.getPlanById(planId);
            if (plan == null || !plan.isActive() || plan.isFree()) {
                resp.setStatus(400);
                resp.getWriter().write("{\"error\":\"Invalid plan\"}");
                return;
            }

            String rzpKeyId = System.getenv("RAZORPAY_KEY_ID");
            String rzpKeySecret = System.getenv("RAZORPAY_KEY_SECRET");
            if (rzpKeyId == null || rzpKeyId.isBlank() || rzpKeySecret == null || rzpKeySecret.isBlank()) {
                resp.setStatus(503);
                resp.getWriter().write("{\"error\":\"Payment gateway is not configured. Please use manual UPI payment.\"}");
                return;
            }

            int amountPaise = plan.getPriceInr() * 100;
            String razorpayOrderId = RazorpayHelper.createOrder(rzpKeyId, rzpKeySecret, amountPaise);
            if (razorpayOrderId == null || razorpayOrderId.isBlank()) {
                resp.setStatus(502);
                resp.getWriter().write("{\"error\":\"Failed to create payment order. Please try again.\"}");
                return;
            }

            subDao.createPendingOrder(u.getId(), planId, plan.getPriceInr(), plan.getClothesAdded(), razorpayOrderId);
            resp.setStatus(200);
            resp.getWriter().write(
                "{\"orderId\":\"" + razorpayOrderId + "\"," +
                "\"amount\":" + amountPaise + "," +
                "\"currency\":\"INR\"," +
                "\"key\":\"" + rzpKeyId + "\"," +
                "\"planName\":\"" + plan.getPlanName() + "\"," +
                "\"clothes\":" + plan.getClothesAdded() + "}");
        } catch (Exception e) {
            resp.setStatus(500);
            resp.getWriter().write("{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}");
        }
    }
}
