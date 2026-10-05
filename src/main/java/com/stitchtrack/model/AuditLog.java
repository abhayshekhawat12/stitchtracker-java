package com.stitchtrack.model;
import java.sql.Timestamp;
public class AuditLog {
    private long id; private String actorRole, action, details, ipAddress; private Timestamp createdAt;
    public long getId(){return id;} public void setId(long v){id=v;} public String getActorRole(){return actorRole;} public void setActorRole(String v){actorRole=v;} public String getAction(){return action;} public void setAction(String v){action=v;} public String getDetails(){return details;} public void setDetails(String v){details=v;} public String getIpAddress(){return ipAddress;} public void setIpAddress(String v){ipAddress=v;} public Timestamp getCreatedAt(){return createdAt;} public void setCreatedAt(Timestamp v){createdAt=v;}
}
