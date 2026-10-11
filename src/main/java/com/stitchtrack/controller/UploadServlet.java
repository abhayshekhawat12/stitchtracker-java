package com.stitchtrack.controller;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;

@WebServlet("/uploads/*")
public class UploadServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String pathInfo = req.getPathInfo();
        if (pathInfo == null || pathInfo.equals("/")) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String fileName = pathInfo.startsWith("/") ? pathInfo.substring(1) : pathInfo;

        // Security check against path traversal
        if (fileName.contains("..") || fileName.contains("/") || fileName.contains("\\")) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        // 1. Check in webapp /uploads/
        String appPath = req.getServletContext().getRealPath("");
        File file = null;
        if (appPath != null) {
            file = new File(appPath + File.separator + "uploads", fileName);
        }

        // 2. Check in temp /uploads/
        if (file == null || !file.exists()) {
            file = new File(System.getProperty("java.io.tmpdir") + File.separator + "uploads", fileName);
        }

        // 3. Check in current directory uploads/
        if (!file.exists()) {
            file = new File("uploads", fileName);
        }

        if (!file.exists() || !file.isFile()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String mimeType = req.getServletContext().getMimeType(file.getName());
        if (mimeType == null) {
            mimeType = Files.probeContentType(file.toPath());
        }
        if (mimeType == null) {
            mimeType = "application/octet-stream";
        }

        resp.setContentType(mimeType);
        resp.setContentLengthLong(file.length());
        resp.setHeader("Cache-Control", "public, max-age=86400");

        try (FileInputStream in = new FileInputStream(file); OutputStream out = resp.getOutputStream()) {
            in.transferTo(out);
        }
    }
}
