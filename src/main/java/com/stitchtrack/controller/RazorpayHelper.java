package com.stitchtrack.controller;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Minimal Razorpay integration helper.
 * Uses only Java standard library (no external Razorpay SDK needed).
 *
 * Razorpay API docs: https://razorpay.com/docs/api/orders/
 */
public final class RazorpayHelper {

    private static final String RAZORPAY_ORDERS_URL = "https://api.razorpay.com/v1/orders";

    private RazorpayHelper() {}

    /**
     * Creates a Razorpay order and returns the order ID.
     *
     * @param keyId     Razorpay Key ID  (RAZORPAY_KEY_ID env var)
     * @param keySecret Razorpay Secret  (RAZORPAY_KEY_SECRET env var)
     * @param amountPaise Amount in paise (e.g. 20000 for ₹200)
     * @return Razorpay order ID string (e.g. "order_XXXXXXXX") or null on failure
     */
    public static String createOrder(String keyId, String keySecret, int amountPaise) {
        try {
            String credentials = Base64.getEncoder()
                    .encodeToString((keyId + ":" + keySecret).getBytes(StandardCharsets.UTF_8));

            String body = "{\"amount\":" + amountPaise +
                          ",\"currency\":\"INR\"" +
                          ",\"receipt\":\"ST-" + System.currentTimeMillis() + "\"" +
                          ",\"payment_capture\":1}";

            URL url = new URL(RAZORPAY_ORDERS_URL);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Authorization", "Basic " + credentials);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(15000);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(body.getBytes(StandardCharsets.UTF_8));
            }

            int responseCode = conn.getResponseCode();
            InputStream is = (responseCode >= 200 && responseCode < 300)
                    ? conn.getInputStream() : conn.getErrorStream();

            StringBuilder sb = new StringBuilder();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) sb.append(line);
            }

            String response = sb.toString();
            if (responseCode < 200 || responseCode >= 300) {
                System.err.println("[RazorpayHelper] Order creation failed (" + responseCode + "): " + response);
                return null;
            }

            // Simple JSON parse to extract "id" field
            return extractJsonField(response, "id");

        } catch (Exception e) {
            System.err.println("[RazorpayHelper] Exception creating order: " + e.getMessage());
            return null;
        }
    }

    /**
     * Verifies the Razorpay payment signature using HMAC-SHA256.
     *
     * Expected signature = HMAC_SHA256(razorpayOrderId + "|" + razorpayPaymentId, keySecret)
     *
     * @param razorpayOrderId   Order ID from Razorpay
     * @param razorpayPaymentId Payment ID returned on success
     * @param razorpaySignature Signature sent in the callback
     * @param keySecret         Razorpay Key Secret
     * @return true if signature is valid
     */
    public static boolean verifySignature(String razorpayOrderId,
                                          String razorpayPaymentId,
                                          String razorpaySignature,
                                          String keySecret) {
        try {
            String message = razorpayOrderId + "|" + razorpayPaymentId;
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(keySecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] hmac = mac.doFinal(message.getBytes(StandardCharsets.UTF_8));
            String computed = bytesToHex(hmac);
            return computed.equalsIgnoreCase(razorpaySignature);
        } catch (Exception e) {
            System.err.println("[RazorpayHelper] Signature verification error: " + e.getMessage());
            return false;
        }
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    /** Minimal JSON field extractor for a string value: "key":"value" */
    private static String extractJsonField(String json, String key) {
        String search = "\"" + key + "\"";
        int idx = json.indexOf(search);
        if (idx < 0) return null;
        int colon = json.indexOf(':', idx + search.length());
        if (colon < 0) return null;
        int start = json.indexOf('"', colon + 1);
        if (start < 0) return null;
        int end = json.indexOf('"', start + 1);
        if (end < 0) return null;
        return json.substring(start + 1, end);
    }
}
