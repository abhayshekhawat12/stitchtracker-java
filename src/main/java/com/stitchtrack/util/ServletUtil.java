package com.stitchtrack.util;
import com.stitchtrack.model.User;
import jakarta.servlet.http.*;
public final class ServletUtil {
 private ServletUtil(){}
 public static User user(HttpServletRequest r){return (User)r.getSession(false).getAttribute("user");}
 public static long longParam(HttpServletRequest r,String n){return Long.parseLong(r.getParameter(n));}
 public static int intParam(HttpServletRequest r,String n){try{return Integer.parseInt(r.getParameter(n));}catch(Exception e){return 0;}}
 public static void flash(HttpServletRequest r,String type,String text){r.getSession().setAttribute("flashType",type);r.getSession().setAttribute("flash",text);}
}
