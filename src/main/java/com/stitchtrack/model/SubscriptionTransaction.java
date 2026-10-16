package com.stitchtrack.model;

import java.sql.Timestamp;

public class SubscriptionTransaction {
    private long id;
    private long studentId;
    private int planId;
    private String planName;
    private String studentName;
    private String studentRoll;
    private String razorpayOrderId;
    private String razorpayPaymentId;
    private String razorpaySignature;
    private int amountInr;
    private int clothesCredited;
    private String paymentStatus;   // PENDING | SUCCESS | FAILED | FREE
    private boolean credited;
    private String transactionRef;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public long getStudentId() { return studentId; }
    public void setStudentId(long v) { this.studentId = v; }

    public int getPlanId() { return planId; }
    public void setPlanId(int v) { this.planId = v; }

    public String getPlanName() { return planName; }
    public void setPlanName(String v) { this.planName = v; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String v) { this.studentName = v; }

    public String getStudentRoll() { return studentRoll; }
    public void setStudentRoll(String v) { this.studentRoll = v; }

    public String getRazorpayOrderId() { return razorpayOrderId; }
    public void setRazorpayOrderId(String v) { this.razorpayOrderId = v; }

    public String getRazorpayPaymentId() { return razorpayPaymentId; }
    public void setRazorpayPaymentId(String v) { this.razorpayPaymentId = v; }

    public String getRazorpaySignature() { return razorpaySignature; }
    public void setRazorpaySignature(String v) { this.razorpaySignature = v; }

    public int getAmountInr() { return amountInr; }
    public void setAmountInr(int v) { this.amountInr = v; }

    public int getClothesCredited() { return clothesCredited; }
    public void setClothesCredited(int v) { this.clothesCredited = v; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String v) { this.paymentStatus = v; }

    public boolean isCredited() { return credited; }
    public void setCredited(boolean v) { this.credited = v; }

    public String getTransactionRef() { return transactionRef; }
    public void setTransactionRef(String v) { this.transactionRef = v; }

    private String paymentScreenshot;
    private String utrNumber;

    public String getPaymentScreenshot() { return paymentScreenshot; }
    public void setPaymentScreenshot(String v) { this.paymentScreenshot = v; }

    public String getUtrNumber() { return utrNumber; }
    public void setUtrNumber(String v) { this.utrNumber = v; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp v) { this.createdAt = v; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp v) { this.updatedAt = v; }
}
