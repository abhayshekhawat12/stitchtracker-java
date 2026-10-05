package com.stitchtrack.dao;

import com.stitchtrack.config.DBConnection;
import com.stitchtrack.model.*;
import java.sql.*;
import java.util.*;

public class SupportDAO {
    public void audit(Long actorId,String role,String action,String details,String ip){try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement("INSERT INTO audit_logs(actor_id,actor_role,action,details,ip_address) VALUES(?,?,?,?,?)")){if(actorId==null)p.setNull(1,Types.BIGINT);else p.setLong(1,actorId);p.setString(2,role);p.setString(3,action);p.setString(4,details);p.setString(5,ip);p.executeUpdate();}catch(SQLException ignored){}}
    public List<AuditLog> auditLogs()throws SQLException{List<AuditLog>x=new ArrayList<>();try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement("SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 250");ResultSet r=p.executeQuery()){while(r.next()){AuditLog a=new AuditLog();a.setId(r.getLong("id"));a.setActorRole(r.getString("actor_role"));a.setAction(r.getString("action"));a.setDetails(r.getString("details"));a.setIpAddress(r.getString("ip_address"));a.setCreatedAt(r.getTimestamp("created_at"));x.add(a);}}return x;}
    public void requestRenewal(long studentId)throws SQLException{try(Connection c=DBConnection.getConnection()){try(PreparedStatement q=c.prepareStatement("SELECT COUNT(*) FROM renewal_requests WHERE student_id=? AND status='Pending'")){q.setLong(1,studentId);try(ResultSet r=q.executeQuery()){r.next();if(r.getInt(1)>0)return;}}try(PreparedStatement p=c.prepareStatement("INSERT INTO renewal_requests(student_id,requested_credits) VALUES(?,200)")){p.setLong(1,studentId);p.executeUpdate();}try(PreparedStatement p=c.prepareStatement("UPDATE users SET renewal_status='Pending' WHERE id=?")){p.setLong(1,studentId);p.executeUpdate();}}}
    public List<RenewalRequest> renewals()throws SQLException{List<RenewalRequest>x=new ArrayList<>();String sql="SELECT r.*,u.name,u.roll_number,u.membership_used,u.membership_limit FROM renewal_requests r JOIN users u ON u.id=r.student_id ORDER BY r.requested_at DESC";try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement(sql);ResultSet rs=p.executeQuery()){while(rs.next()){RenewalRequest r=new RenewalRequest();r.setId(rs.getLong("id"));r.setStudentId(rs.getLong("student_id"));r.setStudentName(rs.getString("name"));r.setStudentRoll(rs.getString("roll_number"));r.setRequestedCredits(rs.getInt("requested_credits"));r.setStatus(rs.getString("status"));r.setStaffNotes(rs.getString("staff_notes"));r.setMembershipUsed(rs.getInt("membership_used"));r.setMembershipLimit(rs.getInt("membership_limit"));r.setRequestedAt(rs.getTimestamp("requested_at"));x.add(r);}}return x;}
    public void resolveRenewal(long id,boolean approve,String notes)throws SQLException{try(Connection c=DBConnection.getConnection()){c.setAutoCommit(false);try{long sid;int credits;try(PreparedStatement q=c.prepareStatement("SELECT student_id,requested_credits FROM renewal_requests WHERE id=? AND status='Pending' FOR UPDATE")){q.setLong(1,id);try(ResultSet r=q.executeQuery()){if(!r.next())return;sid=r.getLong(1);credits=r.getInt(2);}}try(PreparedStatement p=c.prepareStatement("UPDATE renewal_requests SET status=?,staff_notes=?,resolved_at=NOW() WHERE id=?")){p.setString(1,approve?"Approved":"Rejected");p.setString(2,notes);p.setLong(3,id);p.executeUpdate();}if(approve){try(PreparedStatement p=c.prepareStatement("UPDATE users SET membership_limit=membership_limit+?,renewal_status='Approved',account_status='Active' WHERE id=?")){p.setInt(1,credits);p.setLong(2,sid);p.executeUpdate();}}else{try(PreparedStatement p=c.prepareStatement("UPDATE users SET renewal_status='None' WHERE id=?")){p.setLong(1,sid);p.executeUpdate();}}c.commit();}catch(Exception e){c.rollback();throw e instanceof SQLException?(SQLException)e:new SQLException(e);}finally{c.setAutoCommit(true);}}}
    public void createComplaint(long studentId,Long orderId,String bag,String category,String type,String desc)throws SQLException{try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement("INSERT INTO complaints(student_id,order_id,bag_number,category,issue_type,description) VALUES(?,?,?,?,?,?)")){p.setLong(1,studentId);if(orderId==null)p.setNull(2,Types.BIGINT);else p.setLong(2,orderId);p.setString(3,bag);p.setString(4,category);p.setString(5,type);p.setString(6,desc);p.executeUpdate();}}
    public List<Complaint> complaints()throws SQLException{List<Complaint>x=new ArrayList<>();String sql="SELECT c.*,u.name FROM complaints c JOIN users u ON u.id=c.student_id ORDER BY c.created_at DESC";try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement(sql);ResultSet r=p.executeQuery()){while(r.next()){Complaint a=new Complaint();a.setId(r.getLong("id"));a.setStudentId(r.getLong("student_id"));long oid=r.getLong("order_id");a.setOrderId(r.wasNull()?null:oid);a.setStudentName(r.getString("name"));a.setBagNumber(r.getString("bag_number"));a.setCategory(r.getString("category"));a.setIssueType(r.getString("issue_type"));a.setDescription(r.getString("description"));a.setStatus(r.getString("status"));a.setResolutionNotes(r.getString("resolution_notes"));a.setCreatedAt(r.getTimestamp("created_at"));x.add(a);}}return x;}
    public void resolveComplaint(long id,String notes)throws SQLException{try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement("UPDATE complaints SET status='Resolved',resolution_notes=?,resolved_at=NOW() WHERE id=?")){p.setString(1,notes);p.setLong(2,id);p.executeUpdate();}}
    
    public void notify(long userId, String title, String message) {
        try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement("INSERT INTO notifications(user_id,title,message) VALUES(?,?,?)")){
            p.setLong(1,userId); p.setString(2,title); p.setString(3,message); p.executeUpdate();
        } catch(SQLException ignored){}
    }
    
    public List<Map<String,Object>> getNotifications(long userId) throws SQLException {
        List<Map<String,Object>> list = new ArrayList<>();
        try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement("SELECT * FROM notifications WHERE user_id=? ORDER BY created_at DESC LIMIT 50")){
            p.setLong(1,userId);
            try(ResultSet r=p.executeQuery()){
                while(r.next()){
                    Map<String,Object> n = new HashMap<>();
                    n.put("id", r.getLong("id"));
                    n.put("title", r.getString("title"));
                    n.put("message", r.getString("message"));
                    n.put("isRead", r.getBoolean("is_read"));
                    n.put("createdAt", r.getTimestamp("created_at"));
                    list.add(n);
                }
            }
        }
        return list;
    }
    
    public void markNotificationsRead(long userId) {
        try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement("UPDATE notifications SET is_read=1 WHERE user_id=?")){
            p.setLong(1,userId); p.executeUpdate();
        } catch(SQLException ignored){}
    }
}
