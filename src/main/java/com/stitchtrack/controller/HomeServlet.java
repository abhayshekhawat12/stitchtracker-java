package com.stitchtrack.controller;
import com.stitchtrack.model.User;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;
@WebServlet("") public class HomeServlet extends HttpServlet{protected void doGet(HttpServletRequest r,HttpServletResponse s)throws IOException{HttpSession x=r.getSession(false);User u=x==null?null:(User)x.getAttribute("user");s.sendRedirect(r.getContextPath()+(u==null?"/login":u.isAdmin()?"/admin/dashboard":"/student/dashboard"));}}
