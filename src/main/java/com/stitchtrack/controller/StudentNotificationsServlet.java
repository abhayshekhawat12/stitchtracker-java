package com.stitchtrack.controller;

import com.stitchtrack.dao.SupportDAO;
import com.stitchtrack.model.User;
import com.stitchtrack.util.ServletUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/student/notifications")
public class StudentNotificationsServlet extends HttpServlet {
    private final SupportDAO support = new SupportDAO();

    protected void doGet(HttpServletRequest r, HttpServletResponse s) throws ServletException, IOException {
        try {
            User user = ServletUtil.user(r);
            r.setAttribute("notifications", support.getNotifications(user.getId()));
            r.getRequestDispatcher("/WEB-INF/views/student-notifications.jsp").forward(r, s);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    protected void doPost(HttpServletRequest r, HttpServletResponse s) throws IOException {
        try {
            User user = ServletUtil.user(r);
            String action = r.getParameter("action");
            if ("markRead".equals(action)) {
                support.markNotificationsRead(user.getId());
                ServletUtil.flash(r, "success", "All notifications marked as read.");
            }
        } catch (Exception e) {
            ServletUtil.flash(r, "error", e.getMessage());
        }
        s.sendRedirect(r.getContextPath() + "/student/notifications");
    }
}
