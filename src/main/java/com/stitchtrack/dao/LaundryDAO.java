package com.stitchtrack.dao;

import com.stitchtrack.config.DBConnection;
import com.stitchtrack.model.LaundryOrder;
import java.sql.*;
import java.util.*;

public class LaundryDAO {
    private static final String SELECT="SELECT o.*,u.name student_name,u.roll_number student_roll,u.phone student_phone FROM laundry_orders o JOIN users u ON u.id=o.student_id";

    public long create(long studentId, Map<String,Integer> items) throws SQLException {
        int total=items.values().stream().mapToInt(Integer::intValue).sum();
        if(total<=0) throw new SQLException("At least one garment is required.");
        try(Connection c=DBConnection.getConnection()){
            c.setAutoCommit(false);
            try{
                int limit,used; try(PreparedStatement q=c.prepareStatement("SELECT membership_limit,membership_used FROM users WHERE id=? FOR UPDATE")){q.setLong(1,studentId);try(ResultSet r=q.executeQuery()){if(!r.next())throw new SQLException("Student not found");limit=r.getInt(1);used=r.getInt(2);}}
                if(used+total>limit) throw new SQLException("Quota exceeded. Remaining items: "+Math.max(0,limit-used));
                String orderNo="ST-ORD-"+System.currentTimeMillis(); long orderId;
                try(PreparedStatement p=c.prepareStatement("INSERT INTO laundry_orders(order_number,student_id,total_items,status,current_stage) VALUES(?,?,?,'Pending Approval','Pending Approval')",Statement.RETURN_GENERATED_KEYS)){p.setString(1,orderNo);p.setLong(2,studentId);p.setInt(3,total);p.executeUpdate();try(ResultSet k=p.getGeneratedKeys()){k.next();orderId=k.getLong(1);}}
                try(PreparedStatement p=c.prepareStatement("INSERT INTO laundry_items(order_id,category,item_count) VALUES(?,?,?)")){for(var e:items.entrySet()){if(e.getValue()>0){p.setLong(1,orderId);p.setString(2,e.getKey());p.setInt(3,e.getValue());p.addBatch();}}p.executeBatch();}
                c.commit(); return orderId;
            }catch(Exception e){c.rollback(); if(e instanceof SQLException se) throw se; throw new SQLException(e);} finally {c.setAutoCommit(true);}
        }
    }

    public List<LaundryOrder> findByStudent(long studentId) throws SQLException {return query(SELECT+" WHERE o.student_id=? ORDER BY o.created_at DESC", studentId);}
    public List<LaundryOrder> findAll() throws SQLException {return query(SELECT+" ORDER BY o.created_at DESC");}
    public LaundryOrder findById(long id) throws SQLException {List<LaundryOrder> x=query(SELECT+" WHERE o.id=?",id);return x.isEmpty()?null:x.get(0);}

    public void accept(long orderId,long staffId,String bagNumber,String qrToken) throws SQLException {
        if(!bagNumber.matches("ST-\\d{3,4}")) throw new SQLException("Bag number must match ST-101 or ST-4920 format.");
        try(Connection c=DBConnection.getConnection()){
            try(PreparedStatement chk=c.prepareStatement("SELECT COUNT(*) FROM laundry_orders WHERE UPPER(bag_number)=UPPER(?) AND status NOT IN ('Delivered','Cancelled','Rejected')")){chk.setString(1,bagNumber);try(ResultSet r=chk.executeQuery()){r.next();if(r.getInt(1)>0)throw new SQLException("This bag is already in use.");}}
            try(PreparedStatement p=c.prepareStatement("UPDATE laundry_orders SET bag_number=?,qr_token=?,qr_status='unused',status='Received',current_stage='Received',accepted_by=?,accepted_at=NOW(),estimated_completion=DATE_ADD(NOW(),INTERVAL 2 DAY) WHERE id=? AND status='Pending Approval'")){p.setString(1,bagNumber.toUpperCase());p.setString(2,qrToken);p.setLong(3,staffId);p.setLong(4,orderId);if(p.executeUpdate()==0)throw new SQLException("Order is no longer pending approval.");}
        }
    }

    public void reject(long orderId) throws SQLException {updateStage(orderId,"Rejected");}
    public void updateStage(long orderId,String stage) throws SQLException {
        Set<String> allowed=Set.of("Received","Sorting","Washing","Drying","Ironing","Ready for Pickup","Delivered","Rejected","Cancelled");
        if(!allowed.contains(stage)) throw new SQLException("Invalid stage");
        String status=switch(stage){case "Received"->"Received";case "Ready for Pickup"->"Ready";case "Delivered"->"Delivered";case "Rejected"->"Rejected";case "Cancelled"->"Cancelled";default->"In Progress";};
        String sql="UPDATE laundry_orders SET current_stage=?,status=?"+("Delivered".equals(stage)?",delivered_at=NOW()":"")+" WHERE id=?";
        try(Connection c=DBConnection.getConnection(); PreparedStatement p=c.prepareStatement(sql)){p.setString(1,stage);p.setString(2,status);p.setLong(3,orderId);p.executeUpdate();}
        
        LaundryOrder o = findById(orderId);
        if (o != null) {
            new SupportDAO().notify(o.getStudentId(), "Order Update", "Your order #" + o.getOrderNumber() + " is now: " + stage);
        }
    }

    public LaundryOrder findByQr(String token) throws SQLException {List<LaundryOrder>x=query(SELECT+" WHERE o.qr_token=?",token);return x.isEmpty()?null:x.get(0);}

    public boolean deliverByQr(String token) throws SQLException {
        try(Connection c=DBConnection.getConnection()){
            c.setAutoCommit(false);
            try{
                long id,studentId;int items;String status,qrStatus;
                try(PreparedStatement q=c.prepareStatement("SELECT id,student_id,total_items,status,qr_status FROM laundry_orders WHERE qr_token=? FOR UPDATE")){q.setString(1,token);try(ResultSet r=q.executeQuery()){if(!r.next())return false;id=r.getLong(1);studentId=r.getLong(2);items=r.getInt(3);status=r.getString(4);qrStatus=r.getString(5);}}
                if(!"unused".equalsIgnoreCase(qrStatus)||!"Ready".equals(status)) return false;
                try(PreparedStatement p=c.prepareStatement("UPDATE laundry_orders SET qr_status='used',status='Delivered',current_stage='Delivered',delivered_at=NOW() WHERE id=?")){p.setLong(1,id);p.executeUpdate();}
                try(PreparedStatement p=c.prepareStatement("UPDATE users SET membership_used=LEAST(membership_limit,membership_used+?) WHERE id=?")){p.setInt(1,items);p.setLong(2,studentId);p.executeUpdate();}
                c.commit();return true;
            }catch(Exception e){c.rollback();throw e instanceof SQLException?(SQLException)e:new SQLException(e);}finally{c.setAutoCommit(true);}
        }
    }

    private List<LaundryOrder> query(String sql,Object...params)throws SQLException{
        List<LaundryOrder> list=new ArrayList<>();
        try(Connection c=DBConnection.getConnection();PreparedStatement p=c.prepareStatement(sql)){for(int i=0;i<params.length;i++)p.setObject(i+1,params[i]);try(ResultSet r=p.executeQuery()){while(r.next()){LaundryOrder o=map(r);loadItems(c,o);list.add(o);}}}return list;
    }
    private void loadItems(Connection c,LaundryOrder o)throws SQLException{try(PreparedStatement p=c.prepareStatement("SELECT category,item_count FROM laundry_items WHERE order_id=? ORDER BY category")){p.setLong(1,o.getId());try(ResultSet r=p.executeQuery()){while(r.next())o.getItems().put(r.getString(1),r.getInt(2));}}}
    private LaundryOrder map(ResultSet r)throws SQLException{LaundryOrder o=new LaundryOrder();o.setId(r.getLong("id"));o.setStudentId(r.getLong("student_id"));o.setOrderNumber(r.getString("order_number"));o.setStudentName(r.getString("student_name"));o.setStudentRoll(r.getString("student_roll"));o.setStudentPhone(r.getString("student_phone"));o.setBagNumber(r.getString("bag_number"));o.setQrToken(r.getString("qr_token"));o.setQrStatus(r.getString("qr_status"));o.setStatus(r.getString("status"));o.setCurrentStage(r.getString("current_stage"));o.setTotalItems(r.getInt("total_items"));o.setCreatedAt(r.getTimestamp("created_at"));o.setEstimatedCompletion(r.getTimestamp("estimated_completion"));o.setDeliveredAt(r.getTimestamp("delivered_at"));return o;}
}
