package com.stitchtrack.model;

import java.time.LocalDate;

public class User {
    private long id;
    private String name, rollNumber, email, phone, hostel, roomNo, gender;
    private String profilePhoto, idCard;
    private int membershipLimit, membershipUsed;
    private LocalDate quotaResetDate;
    private String accountStatus, verificationStatus, renewalStatus, role;

    public long getId(){return id;} public void setId(long id){this.id=id;}
    public String getName(){return name;} public void setName(String v){name=v;}
    public String getRollNumber(){return rollNumber;} public void setRollNumber(String v){rollNumber=v;}
    public String getEmail(){return email;} public void setEmail(String v){email=v;}
    public String getPhone(){return phone;} public void setPhone(String v){phone=v;}
    public String getHostel(){return hostel;} public void setHostel(String v){hostel=v;}
    public String getRoomNo(){return roomNo;} public void setRoomNo(String v){roomNo=v;}
    public String getGender(){return gender;} public void setGender(String v){gender=v;}
    public int getMembershipLimit(){return membershipLimit;} public void setMembershipLimit(int v){membershipLimit=v;}
    public int getMembershipUsed(){return membershipUsed;} public void setMembershipUsed(int v){membershipUsed=v;}
    public int getCreditsLeft(){return Math.max(0,membershipLimit-membershipUsed);}
    public LocalDate getQuotaResetDate(){return quotaResetDate;} public void setQuotaResetDate(LocalDate v){quotaResetDate=v;}
    public String getAccountStatus(){return accountStatus;} public void setAccountStatus(String v){accountStatus=v;}
    public String getVerificationStatus(){return verificationStatus;} public void setVerificationStatus(String v){verificationStatus=v;}
    public String getRenewalStatus(){return renewalStatus;} public void setRenewalStatus(String v){renewalStatus=v;}
    public String getRole(){return role;} public void setRole(String v){role=v;}
    public String getProfilePhoto(){return profilePhoto;} public void setProfilePhoto(String v){profilePhoto=v;}
    public String getIdCard(){return idCard;} public void setIdCard(String v){idCard=v;}
    public boolean isAdmin(){return "ADMIN".equalsIgnoreCase(role)||"STAFF".equalsIgnoreCase(role);}
}
