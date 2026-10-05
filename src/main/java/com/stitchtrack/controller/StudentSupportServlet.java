package com.stitchtrack.controller;
import com.stitchtrack.dao.SupportDAO;import com.stitchtrack.model.User;import com.stitchtrack.util.ServletUtil;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;
@WebServlet("/student/support") public class StudentSupportServlet extends HttpServlet{
 private final SupportDAO dao=new SupportDAO();
 protected void doPost(HttpServletRequest r,HttpServletResponse s)throws IOException{User u=ServletUtil.user(r);String action=r.getParameter("action");try{if("renewal".equals(action)){dao.requestRenewal(u.getId());ServletUtil.flash(r,"success","Quota renewal request sent to admin.");}else if("complaint".equals(action)){String oid=r.getParameter("orderId");Long orderId=(oid==null||oid.isBlank())?null:Long.valueOf(oid);dao.createComplaint(u.getId(),orderId,r.getParameter("bag"),r.getParameter("category"),r.getParameter("issue"),r.getParameter("description"));ServletUtil.flash(r,"success","Complaint/mismatch report submitted.");}}catch(Exception e){ServletUtil.flash(r,"error",e.getMessage());}s.sendRedirect(r.getContextPath()+"/student/dashboard");}
}
