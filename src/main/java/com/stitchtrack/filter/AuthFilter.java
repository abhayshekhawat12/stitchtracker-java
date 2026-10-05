package com.stitchtrack.filter;
import com.stitchtrack.model.User;
import jakarta.servlet.*;import jakarta.servlet.annotation.WebFilter;import jakarta.servlet.http.*;import java.io.IOException;
@WebFilter(urlPatterns={"/student/*","/admin/*","/staff/*","/qr"})
public class AuthFilter implements Filter{
 public void doFilter(ServletRequest req,ServletResponse res,FilterChain chain)throws IOException,ServletException{
  HttpServletRequest r=(HttpServletRequest)req;HttpServletResponse s=(HttpServletResponse)res;HttpSession session=r.getSession(false);User u=session==null?null:(User)session.getAttribute("user");
  if(u==null){s.sendRedirect(r.getContextPath()+"/login");return;}
  if(r.getRequestURI().contains("/admin/")&&!u.isAdmin()){s.sendRedirect(r.getContextPath()+"/student/dashboard");return;}
  if(r.getRequestURI().contains("/staff/")&&!"STAFF".equalsIgnoreCase(u.getRole())&&!"ADMIN".equalsIgnoreCase(u.getRole())){s.sendRedirect(r.getContextPath()+"/student/dashboard");return;}
  chain.doFilter(req,res);
 }
}
