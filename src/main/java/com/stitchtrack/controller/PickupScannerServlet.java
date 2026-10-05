package com.stitchtrack.controller;
import com.stitchtrack.dao.*;import com.stitchtrack.model.User;import com.stitchtrack.util.ServletUtil;import jakarta.servlet.*;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;
@WebServlet("/admin/scanner") public class PickupScannerServlet extends HttpServlet{
 private final LaundryDAO dao=new LaundryDAO();private final SupportDAO support=new SupportDAO();
 protected void doGet(HttpServletRequest r,HttpServletResponse s)throws ServletException,IOException{r.getRequestDispatcher("/WEB-INF/views/scanner.jsp").forward(r,s);}
 protected void doPost(HttpServletRequest r,HttpServletResponse s)throws ServletException,IOException{String token=r.getParameter("token");try{boolean ok=dao.deliverByQr(token);if(ok){User u=ServletUtil.user(r);support.audit(u.getId(),u.getRole(),"Pickup QR Used","Delivered order via token",r.getRemoteAddr());r.setAttribute("success","QR verified. Laundry delivered and token marked USED.");}else r.setAttribute("error","Invalid, already-used, or not-ready QR token.");}catch(Exception e){r.setAttribute("error",e.getMessage());}doGet(r,s);}
}
