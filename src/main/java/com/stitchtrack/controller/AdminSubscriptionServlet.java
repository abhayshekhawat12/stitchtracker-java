package com.stitchtrack.controller;

import com.stitchtrack.dao.*;
import com.stitchtrack.model.User;
import com.stitchtrack.util.ServletUtil;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * GET /admin/subscriptions
 * Provides the admin with all subscription transaction records.
 * This is embedded into the admin dashboard via a tab.
 */
@WebServlet("/admin/subscriptions")
public class AdminSubscriptionServlet extends HttpServlet {

    private final SubscriptionDAO subDao = new SubscriptionDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User admin = ServletUtil.user(req);
        if (admin == null || !admin.isAdmin()) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        try {
            req.setAttribute("subTransactions", subDao.getAllTransactions());
            req.getRequestDispatcher("/WEB-INF/views/admin-subscriptions.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
