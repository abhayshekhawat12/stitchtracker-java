package com.stitchtrack.controller;
import com.stitchtrack.dao.*;import com.stitchtrack.model.*;import com.stitchtrack.util.ServletUtil;import jakarta.servlet.*;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;
@WebServlet("/student/dashboard") public class StudentDashboardServlet extends HttpServlet{
 private final UserDAO users=new UserDAO();private final LaundryDAO laundry=new LaundryDAO();private final SupportDAO support=new SupportDAO();
 protected void doGet(HttpServletRequest r,HttpServletResponse s)throws ServletException,IOException{try{User current=ServletUtil.user(r);User fresh=users.findById(current.getId());r.getSession().setAttribute("user",fresh);r.setAttribute("user",fresh);r.setAttribute("orders",laundry.findByStudent(fresh.getId()));r.setAttribute("notifications", support.getNotifications(fresh.getId()));r.getRequestDispatcher("/WEB-INF/views/student-dashboard.jsp").forward(r,s);}catch(Exception e){throw new ServletException(e);}}
}
