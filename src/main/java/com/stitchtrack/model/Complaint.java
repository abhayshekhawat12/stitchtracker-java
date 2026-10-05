package com.stitchtrack.model;
import java.sql.Timestamp;
public class Complaint {
    private long id, studentId; private Long orderId; private String studentName, bagNumber, category, issueType, description, status, resolutionNotes; private Timestamp createdAt;
    public long getId(){return id;} public void setId(long v){id=v;} public long getStudentId(){return studentId;} public void setStudentId(long v){studentId=v;} public Long getOrderId(){return orderId;} public void setOrderId(Long v){orderId=v;}
    public String getStudentName(){return studentName;} public void setStudentName(String v){studentName=v;} public String getBagNumber(){return bagNumber;} public void setBagNumber(String v){bagNumber=v;} public String getCategory(){return category;} public void setCategory(String v){category=v;} public String getIssueType(){return issueType;} public void setIssueType(String v){issueType=v;} public String getDescription(){return description;} public void setDescription(String v){description=v;} public String getStatus(){return status;} public void setStatus(String v){status=v;} public String getResolutionNotes(){return resolutionNotes;} public void setResolutionNotes(String v){resolutionNotes=v;} public Timestamp getCreatedAt(){return createdAt;} public void setCreatedAt(Timestamp v){createdAt=v;}
}
