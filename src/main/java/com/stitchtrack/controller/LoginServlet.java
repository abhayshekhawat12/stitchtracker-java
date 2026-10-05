package com.stitchtrack.controller;
import com.stitchtrack.dao.*;import com.stitchtrack.model.User;import jakarta.servlet.*;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;
@WebServlet("/login") public class LoginServlet extends HttpServlet{
 private final UserDAO users=new UserDAO(); private final SupportDAO support=new SupportDAO();
 protected void doGet(HttpServletRequest r,HttpServletResponse s)throws ServletException,IOException{r.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(r,s);}
 protected void doPost(HttpServletRequest r,HttpServletResponse s)throws ServletException,IOException{String id=r.getParameter("identifier"),pw=r.getParameter("password"),roleChoice=r.getParameter("roleChoice");if(id!=null)id=id.trim();try{User u=users.authenticate(id,pw);if(u==null){r.setAttribute("error","Invalid email/roll number or password.");doGet(r,s);return;}
 if(roleChoice!=null && !u.getRole().equalsIgnoreCase(roleChoice)){r.setAttribute("error","This account does not have "+roleChoice+" access.");doGet(r,s);return;}
 if("STUDENT".equalsIgnoreCase(u.getRole())&&!"Approved".equalsIgnoreCase(u.getVerificationStatus())){r.setAttribute("error","Student account is waiting for admin verification.");doGet(r,s);return;}
 if("STAFF".equalsIgnoreCase(u.getRole())&&!"Approved".equalsIgnoreCase(u.getVerificationStatus())){r.setAttribute("error","Staff account is waiting for admin verification.");doGet(r,s);return;}
 r.getSession(true).setAttribute("user",u);support.audit(u.getId(),u.getRole(),"Login",u.getEmail()+" authenticated",r.getRemoteAddr());String dest="ADMIN".equalsIgnoreCase(u.getRole())?"/admin/dashboard":"STAFF".equalsIgnoreCase(u.getRole())?"/staff/dashboard":"/student/dashboard";s.sendRedirect(r.getContextPath()+dest);}catch(Exception e){r.setAttribute("error","Database error: "+e.getMessage());doGet(r,s);}}
}
