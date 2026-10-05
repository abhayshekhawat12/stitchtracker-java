package com.stitchtrack.util;

public class HTMLEscape {
    public static String escape(String input) {
        if (input == null) return "";
        StringBuilder escaped = new StringBuilder();
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            switch (c) {
                case '<': escaped.append("&lt;"); break;
                case '>': escaped.append("&gt;"); break;
                case '&': escaped.append("&amp;"); break;
                case '"': escaped.append("&quot;"); break;
                case '\'': escaped.append("&#x27;"); break;
                case '/': escaped.append("&#x2F;"); break;
                default: escaped.append(c); break;
            }
        }
        return escaped.toString();
    }
}
