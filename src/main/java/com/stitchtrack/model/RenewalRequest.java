package com.stitchtrack.model;
import java.sql.Timestamp;
public class RenewalRequest {
    private long id, studentId; private String studentName, studentRoll, status, staffNotes; private int requestedCredits, membershipUsed, membershipLimit; private Timestamp requestedAt;
    public long getId(){return id;} public void setId(long v){id=v;} public long getStudentId(){return studentId;} public void setStudentId(long v){studentId=v;}
    public String getStudentName(){return studentName;} public void setStudentName(String v){studentName=v;} public String getStudentRoll(){return studentRoll;} public void setStudentRoll(String v){studentRoll=v;}
    public String getStatus(){return status;} public void setStatus(String v){status=v;} public String getStaffNotes(){return staffNotes;} public void setStaffNotes(String v){staffNotes=v;}
    public int getRequestedCredits(){return requestedCredits;} public void setRequestedCredits(int v){requestedCredits=v;} public int getMembershipUsed(){return membershipUsed;} public void setMembershipUsed(int v){membershipUsed=v;} public int getMembershipLimit(){return membershipLimit;} public void setMembershipLimit(int v){membershipLimit=v;}
    public Timestamp getRequestedAt(){return requestedAt;} public void setRequestedAt(Timestamp v){requestedAt=v;}
}
