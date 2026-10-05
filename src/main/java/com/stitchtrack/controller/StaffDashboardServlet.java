package com.stitchtrack.controller;

import com.stitchtrack.dao.LaundryDAO;
import com.stitchtrack.dao.SupportDAO;
import com.stitchtrack.util.ServletUtil;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/staff/dashboard")
public class StaffDashboardServlet extends HttpServlet {
    private final LaundryDAO laundry = new LaundryDAO();
    private final SupportDAO support = new SupportDAO();

    protected void doGet(HttpServletRequest r, HttpServletResponse s)
            throws ServletException, IOException {
        try {
            r.setAttribute("orders", laundry.findAll());
        } catch (Exception e) {
            r.setAttribute("orders", java.util.Collections.emptyList());
            r.setAttribute("error", e.getMessage());
        }
        r.getRequestDispatcher("/WEB-INF/views/staff-dashboard.jsp").forward(r, s);
    }
}
