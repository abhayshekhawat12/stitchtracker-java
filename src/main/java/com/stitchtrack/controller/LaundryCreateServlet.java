package com.stitchtrack.controller;
import com.stitchtrack.dao.*;
import com.stitchtrack.model.User;
import com.stitchtrack.util.CreditRules;
import com.stitchtrack.util.ServletUtil;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.*;

@WebServlet("/student/new-request")
public class LaundryCreateServlet extends HttpServlet {

    private final LaundryDAO  dao     = new LaundryDAO();
    private final SupportDAO  support = new SupportDAO();
    private final UserDAO     userDAO = new UserDAO();

    // Garment catalogue — must stay in sync with new-request.jsp LARGE_ITEMS JS set
    private static final String[] CATS = {
        "T-Shirt","Shirt","Jeans","Trousers","Shorts","Track Pant",
        "Hoodie","Top","Kurti","Lower","Bedsheet","Pillow Cover","Blanket","Towel"
    };

    @Override
    protected void doGet(HttpServletRequest r, HttpServletResponse s)
            throws ServletException, IOException {
        r.setAttribute("categories", CATS);
        r.setAttribute("largeItems", CreditRules.LARGE_ITEMS); // pass to JSP
        r.getRequestDispatcher("/WEB-INF/views/new-request.jsp").forward(r, s);
    }

    @Override
    protected void doPost(HttpServletRequest r, HttpServletResponse s)
            throws ServletException, IOException {
        User u = ServletUtil.user(r);

        // Build items map from form
        Map<String,Integer> items = new LinkedHashMap<>();
        for (String c : CATS) {
            items.put(c, ServletUtil.intParam(r, "item_" + c.replace(" ", "_")));
        }

        // Server-side credit calculation — never trust frontend
        int totalItems  = CreditRules.totalItems(items);
        int totalCredit = CreditRules.totalCredits(items);
        int remaining   = u.getCreditsLeft();

        if (totalItems <= 0) {
            r.setAttribute("categories", CATS);
            r.setAttribute("largeItems", CreditRules.LARGE_ITEMS);
            r.setAttribute("error", "Please select at least one garment.");
            r.getRequestDispatcher("/WEB-INF/views/new-request.jsp").forward(r, s);
            return;
        }

        if (totalCredit > remaining) {
            r.setAttribute("categories", CATS);
            r.setAttribute("largeItems", CreditRules.LARGE_ITEMS);
            r.setAttribute("error",
                "Insufficient credits! This request requires <b>" + totalCredit +
                " credits</b> but you only have <b>" + remaining + " credits</b> remaining. " +
                "<a href=\"" + r.getContextPath() + "/student/subscription\" " +
                "style=\"color:var(--blue);text-decoration:underline;\">Purchase a plan</a> to top up.");
            r.getRequestDispatcher("/WEB-INF/views/new-request.jsp").forward(r, s);
            return;
        }

        try {
            long id = dao.create(u.getId(), items);

            // Refresh session with updated membership_used
            User fresh = userDAO.findById(u.getId());
            if (fresh != null) r.getSession().setAttribute("user", fresh);

            support.audit(u.getId(), u.getRole(), "Laundry Request",
                "Created request #" + id + " (" + totalItems + " items, " + totalCredit + " credits)",
                r.getRemoteAddr());
            ServletUtil.flash(r, "success",
                "Laundry request submitted successfully! " + totalCredit +
                " credits deducted. Staff will assign a bag and generate your pickup QR.");
            s.sendRedirect(r.getContextPath() + "/student/dashboard");

        } catch (Exception e) {
            r.setAttribute("categories", CATS);
            r.setAttribute("largeItems", CreditRules.LARGE_ITEMS);
            r.setAttribute("error", e.getMessage());
            r.getRequestDispatcher("/WEB-INF/views/new-request.jsp").forward(r, s);
        }
    }
}
