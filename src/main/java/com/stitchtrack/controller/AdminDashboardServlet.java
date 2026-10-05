package com.stitchtrack.controller;
import com.stitchtrack.dao.*;import jakarta.servlet.*;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;
@WebServlet("/admin/dashboard") public class AdminDashboardServlet extends HttpServlet{
 private final UserDAO users=new UserDAO();private final LaundryDAO laundry=new LaundryDAO();private final SupportDAO support=new SupportDAO();
 protected void doGet(HttpServletRequest r,HttpServletResponse s)throws ServletException,IOException{try{r.setAttribute("students",users.findAllStudents());r.setAttribute("staffList",users.findAllStaff());r.setAttribute("orders",laundry.findAll());r.setAttribute("renewals",support.renewals());r.setAttribute("complaints",support.complaints());r.setAttribute("auditLogs",support.auditLogs());r.getRequestDispatcher("/WEB-INF/views/admin-dashboard.jsp").forward(r,s);}catch(Exception e){throw new ServletException(e);}}
}
