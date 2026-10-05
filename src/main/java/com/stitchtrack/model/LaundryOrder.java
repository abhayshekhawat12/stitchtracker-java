package com.stitchtrack.model;

import java.sql.Timestamp;
import java.util.LinkedHashMap;
import java.util.Map;

public class LaundryOrder {
    private long id, studentId;
    private String orderNumber, studentName, studentRoll, studentPhone, bagNumber, qrToken, qrStatus, status, currentStage;
    private int totalItems;
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
    public Timestamp getCreatedAt(){return createdAt;} public void setCreatedAt(Timestamp v){createdAt=v;}
    public Timestamp getEstimatedCompletion(){return estimatedCompletion;} public void setEstimatedCompletion(Timestamp v){estimatedCompletion=v;}
    public Timestamp getDeliveredAt(){return deliveredAt;} public void setDeliveredAt(Timestamp v){deliveredAt=v;}
    public Map<String,Integer> getItems(){return items;}
}
