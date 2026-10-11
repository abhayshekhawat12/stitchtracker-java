package com.stitchtrack.controller;

import com.stitchtrack.model.User;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet({"", "/home"})
public class HomeServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        User user = (session == null) ? null : (User) session.getAttribute("user");
        
        String dest;
        if (user == null) {
            dest = "/login";
        } else if (user.isAdmin()) {
            dest = "/admin/dashboard";
        } else if (user.isStaff()) {
            dest = "/staff/dashboard";
        } else {
            dest = "/student/dashboard";
        }
        
        resp.sendRedirect(req.getContextPath() + dest);
    }
}
