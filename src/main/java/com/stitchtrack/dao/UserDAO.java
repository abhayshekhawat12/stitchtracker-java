package com.stitchtrack.dao;

import com.stitchtrack.config.DBConnection;
import com.stitchtrack.model.User;
import org.mindrot.jbcrypt.BCrypt;
import java.sql.*;
import java.util.*;

public class UserDAO {
    private static final String BASE = "SELECT id,name,roll_number,email,phone,hostel,room_no,gender,membership_limit,membership_used,quota_reset_date,account_status,verification_status,renewal_status,role,profile_photo,id_card FROM users";

    public User authenticate(String identifier, String password) throws SQLException {
        String sql = BASE + " WHERE (LOWER(email)=LOWER(?) OR LOWER(roll_number)=LOWER(?)) LIMIT 1";
        try(Connection c=DBConnection.getConnection(); PreparedStatement p=c.prepareStatement(sql)){
            p.setString(1,identifier); p.setString(2,identifier);
            try(ResultSet r=p.executeQuery()){
                if(!r.next()) return null;
                long id=r.getLong("id");
                String hash;
                try(PreparedStatement hp=c.prepareStatement("SELECT password_hash FROM users WHERE id=?")){hp.setLong(1,id);try(ResultSet hr=hp.executeQuery()){hr.next();hash=hr.getString(1);}}
                if(!BCrypt.checkpw(password,hash)) return null;
                return map(r);
            }
        }
    }

    public User findById(long id) throws SQLException {
        try(Connection c=DBConnection.getConnection(); PreparedStatement p=c.prepareStatement(BASE+" WHERE id=?")){p.setLong(1,id);try(ResultSet r=p.executeQuery()){return r.next()?map(r):null;}}
    }

    public List<User> findAllStudents() throws SQLException {
        List<User> list=new ArrayList<>();
        try(Connection c=DBConnection.getConnection(); PreparedStatement p=c.prepareStatement(BASE+" WHERE role='STUDENT' ORDER BY created_at DESC"); ResultSet r=p.executeQuery()){while(r.next())list.add(map(r));}
        return list;
    }

    public List<User> findAllStaff() throws SQLException {
        List<User> list=new ArrayList<>();
        try(Connection c=DBConnection.getConnection(); PreparedStatement p=c.prepareStatement(BASE+" WHERE role='STAFF' ORDER BY created_at DESC"); ResultSet r=p.executeQuery()){while(r.next())list.add(map(r));}
        return list;
    }

    public long registerStudent(User u, String rawPassword) throws SQLException {
        String sql="INSERT INTO users(name,roll_number,email,phone,hostel,room_no,password_hash,gender,membership_limit,membership_used,quota_reset_date,account_status,verification_status,role,profile_photo,id_card) VALUES(?,?,?,?,?,?,?,?,200,0,DATE_ADD(CURDATE(),INTERVAL 120 DAY),'Pending Verification','Pending','STUDENT',?,?)";
        try(Connection c=DBConnection.getConnection(); PreparedStatement p=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){
            p.setString(1,u.getName());p.setString(2,u.getRollNumber());p.setString(3,u.getEmail());p.setString(4,u.getPhone());p.setString(5,u.getHostel());p.setString(6,u.getRoomNo());p.setString(7,BCrypt.hashpw(rawPassword,BCrypt.gensalt(10)));p.setString(8,u.getGender());
            p.setString(9,u.getProfilePhoto()); p.setString(10,u.getIdCard());
            p.executeUpdate();
            try(ResultSet k=p.getGeneratedKeys()){return k.next()?k.getLong(1):0;}
        }
    }

    public long registerStaff(User u, String rawPassword) throws SQLException {
        String sql="INSERT INTO users(name,roll_number,email,phone,hostel,room_no,password_hash,gender,membership_limit,membership_used,quota_reset_date,account_status,verification_status,role,profile_photo,id_card) VALUES(?,?,?,?,?,?,?,?,0,0,NULL,'Pending Verification','Pending','STAFF',?,?)";
        try(Connection c=DBConnection.getConnection(); PreparedStatement p=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){
            p.setString(1,u.getName());p.setString(2,u.getRollNumber());p.setString(3,u.getEmail());p.setString(4,u.getPhone());p.setString(5,u.getHostel());p.setString(6,u.getRoomNo());p.setString(7,BCrypt.hashpw(rawPassword,BCrypt.gensalt(10)));p.setString(8,u.getGender());
            p.setString(9,u.getProfilePhoto()); p.setString(10,u.getIdCard());
            p.executeUpdate();
            try(ResultSet k=p.getGeneratedKeys()){return k.next()?k.getLong(1):0;}
        }
    }

    public void setVerification(long id, boolean approve) throws SQLException {
        String sql="UPDATE users SET account_status=?, verification_status=? WHERE id=? AND role IN ('STUDENT','STAFF')";
        try(Connection c=DBConnection.getConnection(); PreparedStatement p=c.prepareStatement(sql)){p.setString(1,approve?"Active":"Inactive");p.setString(2,approve?"Approved":"Rejected");p.setLong(3,id);p.executeUpdate();}
    }

    private User map(ResultSet r) throws SQLException {
        User u=new User();u.setId(r.getLong("id"));u.setName(r.getString("name"));u.setRollNumber(r.getString("roll_number"));u.setEmail(r.getString("email"));u.setPhone(r.getString("phone"));u.setHostel(r.getString("hostel"));u.setRoomNo(r.getString("room_no"));u.setGender(r.getString("gender"));u.setMembershipLimit(r.getInt("membership_limit"));u.setMembershipUsed(r.getInt("membership_used"));java.sql.Date d=r.getDate("quota_reset_date");if(d!=null)u.setQuotaResetDate(d.toLocalDate());u.setAccountStatus(r.getString("account_status"));u.setVerificationStatus(r.getString("verification_status"));u.setRenewalStatus(r.getString("renewal_status"));u.setRole(r.getString("role"));u.setProfilePhoto(r.getString("profile_photo"));u.setIdCard(r.getString("id_card"));return u;
    }
}
