package com.stitchtrack.model;

import java.sql.Timestamp;
import java.util.LinkedHashMap;
import java.util.Map;

public class LaundryOrder {
    private long id, studentId;
    private String orderNumber, studentName, studentRoll, studentPhone, bagNumber, qrToken, qrStatus, status, currentStage;
    private int totalItems;
    private int totalCredits;
    private Timestamp createdAt, estimatedCompletion, deliveredAt;
    private final Map<String,Integer> items = new LinkedHashMap<>();
    public long getId(){return id;} public void setId(long v){id=v;}
    public long getStudentId(){return studentId;} public void setStudentId(long v){studentId=v;}
    public String getOrderNumber(){return orderNumber;} public void setOrderNumber(String v){orderNumber=v;}
    public String getStudentName(){return studentName;} public void setStudentName(String v){studentName=v;}
    public String getStudentRoll(){return studentRoll;} public void setStudentRoll(String v){studentRoll=v;}
    public String getStudentPhone(){return studentPhone;} public void setStudentPhone(String v){studentPhone=v;}
    public String getBagNumber(){return bagNumber;} public void setBagNumber(String v){bagNumber=v;}
    public String getQrToken(){return qrToken;} public void setQrToken(String v){qrToken=v;}
    public String getQrStatus(){return qrStatus;} public void setQrStatus(String v){qrStatus=v;}
    public String getStatus(){return status;} public void setStatus(String v){status=v;}
    public String getCurrentStage(){return currentStage;} public void setCurrentStage(String v){currentStage=v;}
    public int getTotalItems(){return totalItems;} public void setTotalItems(int v){totalItems=v;}
    public int getTotalCredits(){return totalCredits;} public void setTotalCredits(int v){totalCredits=v;}
    public Timestamp getCreatedAt(){return createdAt;} public void setCreatedAt(Timestamp v){createdAt=v;}
    public Timestamp getEstimatedCompletion(){return estimatedCompletion;} public void setEstimatedCompletion(Timestamp v){estimatedCompletion=v;}
    public Timestamp getDeliveredAt(){return deliveredAt;} public void setDeliveredAt(Timestamp v){deliveredAt=v;}
    public Map<String,Integer> getItems(){return items;}
    public boolean isPendingApproval(){
        if(status==null) return false;
        String s=status.trim().toUpperCase();
        return s.equals("PENDING APPROVAL") || s.equals("PENDING");
    }

    public String getCleanPhone() {
        if (studentPhone == null) return "";
        String p = studentPhone.replaceAll("[^0-9]", "");
        if (p.startsWith("0")) {
            p = p.replaceFirst("^0+", "");
        }
        if (p.length() == 10) {
            p = "91" + p;
        }
        return p;
    }

    public String getWhatsAppReadyMessage() {
        String name = (studentName != null && !studentName.isBlank()) ? studentName : "Student";
        String ord = (orderNumber != null && !orderNumber.isBlank()) ? orderNumber : ("#" + id);
        StringBuilder sb = new StringBuilder();
        sb.append("🧺 *StitchTrack Laundry Notification* 🧺\n\n");
        sb.append("Hello *").append(name).append("*, 👋\n\n");
        sb.append("Great news! Your laundry order is washed, ironed & *READY FOR PICKUP*! ✅\n\n");
        sb.append("📋 *Order Details:*\n");
        sb.append("• *Order ID:* ").append(ord).append("\n");
        if (bagNumber != null && !bagNumber.isBlank()) {
            sb.append("• *Bag Number:* ").append(bagNumber).append("\n");
        }
        if (totalItems > 0) {
            sb.append("• *Total Items:* ").append(totalItems).append(" garments\n");
        }
        sb.append("• *Status:* Ready for Pickup\n\n");
        sb.append("📍 *Pickup Instructions:*\n");
        sb.append("Please visit the laundry counter and show your *Pickup QR Code* from your StitchTrack dashboard to collect your clothes.\n\n");
        sb.append("Thank you!\nStitchTrack Facility Team");
        return sb.toString();
    }

    public String getWhatsAppReadyUrl() {
        String phone = getCleanPhone();
        String msg = getWhatsAppReadyMessage();
        String encoded = java.net.URLEncoder.encode(msg, java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
        if (!phone.isBlank()) {
            return "https://api.whatsapp.com/send?phone=" + phone + "&text=" + encoded;
        } else {
            return "https://api.whatsapp.com/send?text=" + encoded;
        }
    }

    public String getWhatsAppDeliveredMessage() {
        String name = (studentName != null && !studentName.isBlank()) ? studentName : "Student";
        String ord = (orderNumber != null && !orderNumber.isBlank()) ? orderNumber : ("#" + id);
        StringBuilder sb = new StringBuilder();
        sb.append("🧺 *StitchTrack Laundry - Delivery Invoice* 🧺\n\n");
        sb.append("Hello *").append(name).append("*, 👋\n\n");
        sb.append("Your laundry order *").append(ord).append("* has been *SUCCESSFULLY DELIVERED*! ✅\n\n");
        if (totalItems > 0) {
            sb.append("• *Total Items:* ").append(totalItems).append(" garments\n");
        }
        if (bagNumber != null && !bagNumber.isBlank()) {
            sb.append("• *Bag Number:* ").append(bagNumber).append("\n");
        }
        sb.append("\nThank you for choosing StitchTrack! Have a great day.");
        return sb.toString();
    }

    public String getWhatsAppDeliveredUrl() {
        String phone = getCleanPhone();
        String msg = getWhatsAppDeliveredMessage();
        String encoded = java.net.URLEncoder.encode(msg, java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
        if (!phone.isBlank()) {
            return "https://api.whatsapp.com/send?phone=" + phone + "&text=" + encoded;
        } else {
            return "https://api.whatsapp.com/send?text=" + encoded;
        }
    }
}
