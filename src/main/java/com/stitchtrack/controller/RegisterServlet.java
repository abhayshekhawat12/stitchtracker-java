package com.stitchtrack.controller;
import com.stitchtrack.dao.*;import com.stitchtrack.model.User;import jakarta.servlet.*;import jakarta.servlet.annotation.WebServlet;import jakarta.servlet.http.*;import java.io.IOException;
@WebServlet("/register")
@jakarta.servlet.annotation.MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 1024 * 1024 * 10,
    maxRequestSize = 1024 * 1024 * 50
)
public class RegisterServlet extends HttpServlet {
    private final UserDAO dao = new UserDAO();
    private final SupportDAO support = new SupportDAO();
    private static final String UPLOAD_DIR = "uploads";

    protected void doGet(HttpServletRequest r, HttpServletResponse s) throws ServletException, IOException {
        r.getRequestDispatcher("/WEB-INF/views/register.jsp").forward(r, s);
    }

    protected void doPost(HttpServletRequest r, HttpServletResponse s) throws ServletException, IOException {
        try {
            String appPath = r.getServletContext().getRealPath("");
            String uploadPath = appPath + java.io.File.separator + UPLOAD_DIR;
            java.io.File uploadDir = new java.io.File(uploadPath);
            if (!uploadDir.exists()) uploadDir.mkdir();

            User u = new User();
            u.setName(r.getParameter("name"));
            u.setRollNumber(r.getParameter("roll")); // might be empty for staff
            u.setEmail(r.getParameter("email"));
            u.setPhone(r.getParameter("phone"));
            u.setHostel(r.getParameter("hostel"));
            u.setRoomNo(r.getParameter("room"));
            u.setGender(r.getParameter("gender"));
            String type = r.getParameter("type");

            // Handle file uploads
            Part profilePart = r.getPart("profile_photo");
            Part idCardPart = r.getPart("id_card");
            
            if (profilePart != null && profilePart.getSize() > 0) {
                String fileName = java.util.UUID.randomUUID().toString() + "_" + getFileName(profilePart);
                profilePart.write(uploadPath + java.io.File.separator + fileName);
                u.setProfilePhoto(UPLOAD_DIR + "/" + fileName);
            }
            if (idCardPart != null && idCardPart.getSize() > 0) {
                String fileName = java.util.UUID.randomUUID().toString() + "_" + getFileName(idCardPart);
                idCardPart.write(uploadPath + java.io.File.separator + fileName);
                u.setIdCard(UPLOAD_DIR + "/" + fileName);
            }

            String pw = r.getParameter("password");
            if (pw == null || pw.length() < 6) throw new IllegalArgumentException("Password must be at least 6 characters.");
            
            long id;
            if ("STAFF".equals(type)) {
                id = dao.registerStaff(u, pw);
                support.audit(id, "STAFF", "Registration", "New staff registration: " + u.getEmail(), r.getRemoteAddr());
            } else {
                id = dao.registerStudent(u, pw);
                support.audit(id, "STUDENT", "Registration", "New student registration: " + u.getEmail(), r.getRemoteAddr());
            }
            
            r.setAttribute("success", "Registration submitted. Admin approval is required before login.");
            doGet(r, s);
        } catch (Exception e) {
            r.setAttribute("error", e.getMessage());
            doGet(r, s);
        }
    }
    
    private String getFileName(Part part) {
        for (String content : part.getHeader("content-disposition").split(";")) {
            if (content.trim().startsWith("filename")) {
                return content.substring(content.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return "unknown";
    }
}
