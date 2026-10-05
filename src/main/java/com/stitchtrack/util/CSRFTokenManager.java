package com.stitchtrack.util;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.security.SecureRandom;
import java.util.Base64;

public class CSRFTokenManager {
    private static final String CSRF_TOKEN_SESSION_ATTR = "CSRF_TOKEN";
    private static final SecureRandom secureRandom = new SecureRandom();

    public static String getToken(HttpServletRequest request) {
        HttpSession session = request.getSession();
        String token = (String) session.getAttribute(CSRF_TOKEN_SESSION_ATTR);
        if (token == null) {
            byte[] tokenBytes = new byte[32];
            secureRandom.nextBytes(tokenBytes);
            token = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
            session.setAttribute(CSRF_TOKEN_SESSION_ATTR, token);
        }
        return token;
    }

    public static boolean validateToken(HttpServletRequest request) {
        String sessionToken = (String) request.getSession().getAttribute(CSRF_TOKEN_SESSION_ATTR);
        String requestToken = request.getParameter("csrf_token");
        return sessionToken != null && sessionToken.equals(requestToken);
    }
}
