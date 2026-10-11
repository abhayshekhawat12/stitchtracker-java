<%@ page import="java.util.*,com.stitchtrack.model.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% 
List<User> students=(List<User>)request.getAttribute("students");
List<User> staffList=(List<User>)request.getAttribute("staffList");
List<LaundryOrder> orders=(List<LaundryOrder>)request.getAttribute("orders");
List<RenewalRequest> renewals=(List<RenewalRequest>)request.getAttribute("renewals");
List<Complaint> complaints=(List<Complaint>)request.getAttribute("complaints");
List<AuditLog> logs=(List<AuditLog>)request.getAttribute("auditLogs");
String flash=(String)session.getAttribute("flash"),ft=(String)session.getAttribute("flashType");
session.removeAttribute("flash");session.removeAttribute("flashType");

List<User> pendingStudentsList = new ArrayList<>();
if(students != null) {
    for(User st : students) {
        if(st.isPendingVerification()) {
            pendingStudentsList.add(st);
        }
    }
}

List<User> pendingStaffList = new ArrayList<>();
if(staffList != null) {
    for(User sf : staffList) {
        if(sf.isPendingVerification()) {
            pendingStaffList.add(sf);
        }
    }
}

List<LaundryOrder> pendingOrdersList = new ArrayList<>();
List<LaundryOrder> activeOrdersList = new ArrayList<>();
if(orders != null) {
    for(LaundryOrder o : orders) {
        if(o.isPendingApproval()) {
            pendingOrdersList.add(o);
        } else if(!Set.of("Delivered","Rejected","Cancelled").contains(o.getStatus())) {
            activeOrdersList.add(o);
        }
    }
}
long totalPending = pendingStudentsList.size() + pendingOrdersList.size() + pendingStaffList.size();
long active = activeOrdersList.size();
String tab = request.getParameter("tab");
if(tab == null) tab = "overview";
%>
<!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Admin - StitchTrack</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <style>
        .topbar nav a.active { background: #eff6ff; color: var(--blue); }
        .card.clickable:hover { transform: translateY(-2px); box-shadow: var(--shadow-md); }
    </style>
</head>
<body>
    <header class="topbar">
        <div class="brand compact">
            <h1>StitchTrack</h1>
            <span>Facility Command Center</span>
        </div>
        <nav>
            <a href="?tab=overview" class="<%= "overview".equals(tab) ? "active" : "" %>">Overview</a>
            <a href="?tab=analytics" class="<%= "analytics".equals(tab) ? "active" : "" %>">Analytics</a>
            <a href="?tab=requests" class="<%= "requests".equals(tab) ? "active" : "" %>">Requests<% if(totalPending > 0) { %><span class="badge" style="background:#ef4444;color:white;border-radius:999px;padding:2px 7px;font-size:0.75rem;margin-left:4px;font-weight:700;"><%=totalPending%></span><% } %></a>
            <a href="?tab=pipeline" class="<%= "pipeline".equals(tab) ? "active" : "" %>">Pipeline</a>
            <a href="?tab=history" class="<%= "history".equals(tab) ? "active" : "" %>">History</a>
            <a href="?tab=students" class="<%= "students".equals(tab) ? "active" : "" %>">Students<% if(!pendingStudentsList.isEmpty()) { %><span class="badge" style="background:#f59e0b;color:white;border-radius:999px;padding:2px 7px;font-size:0.75rem;margin-left:4px;font-weight:700;"><%=pendingStudentsList.size()%></span><% } %></a>
            <a href="?tab=staff" class="<%= "staff".equals(tab) ? "active" : "" %>">Staff</a>
            <a href="?tab=renewals" class="<%= "renewals".equals(tab) ? "active" : "" %>">Renewals</a>
            <a href="?tab=complaints" class="<%= "complaints".equals(tab) ? "active" : "" %>">Issues</a>
            <a href="${pageContext.request.contextPath}/admin/scanner">Pickup Scanner</a>
            <a href="${pageContext.request.contextPath}/admin/export.csv">CSV</a>
            <a href="${pageContext.request.contextPath}/logout">Logout</a>
        </nav>
    </header>
    <main class="container admin">
        <%if(flash!=null){%>
            <div class="alert <%=ft%>"><%=flash%></div>
        <%}%>

        <% if("overview".equals(tab)) { %>
        <section class="hero">
            <div>
                <p class="eyebrow">ADMIN DASHBOARD</p>
                <h2>Laundry Operations</h2>
                <p>Requests, student verification, quota renewals and audit trail.</p>
            </div>
            <a class="button primary" href="${pageContext.request.contextPath}/admin/scanner">Open Pickup Scanner</a>
        </section>
        <section class="cards">
            <article class="card clickable" onclick="location.href='?tab=requests'" style="cursor:pointer;" title="View all pending requests">
                <span>Pending Requests</span>
                <strong style="color: <%= totalPending > 0 ? "var(--blue)" : "inherit" %>;"><%=totalPending%></strong>
                <div style="font-size:0.75rem;color:var(--muted);margin-top:4px;">
                    <%=pendingStudentsList.size()%> Student Account<%=pendingStudentsList.size()==1?"":"s"%><% if(pendingStaffList.size()>0){ %>, <%=pendingStaffList.size()%> Staff<% } %>, <%=pendingOrdersList.size()%> Laundry
                </div>
            </article>
            <article class="card clickable" onclick="location.href='?tab=pipeline'" style="cursor:pointer;" title="View active pipeline">
                <span>Active Pipeline</span>
                <strong><%=active%></strong>
            </article>
            <article class="card clickable" onclick="location.href='?tab=students'" style="cursor:pointer;" title="View student list">
                <span>Total Students</span>
                <strong><%=students != null ? students.size() : 0%></strong>
            </article>
            <article class="card clickable" onclick="location.href='?tab=complaints'" style="cursor:pointer;" title="View open issues">
                <span>Open Issues</span>
                <strong><%=complaints != null ? complaints.stream().filter(c->"Unresolved".equals(c.getStatus())).count() : 0%></strong>
            </article>
        </section>

        <!-- Pending Requests Queue directly on Overview -->
        <section id="overview-requests">
            <div class="section-head">
                <h3>Pending Requests for Approval (<%=totalPending%>)</h3>
                <a href="?tab=requests" class="linkbtn">Open Requests Tab &rarr;</a>
            </div>

            <% if(totalPending == 0){ %>
                <div class="empty">
                    <p>🎉 No pending student requests waiting for approval. All caught up!</p>
                </div>
            <% } %>

            <% if(!pendingStudentsList.isEmpty()){ %>
            <div style="margin-top:1.5rem;">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
                    <h4 style="margin:0;color:var(--text);font-size:1.05rem;">🎓 New Student Account Registrations (<%=pendingStudentsList.size()%>)</h4>
                    <small class="muted">Approve new students to activate their access</small>
                </div>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Photo / ID</th>
                                <th>Student Name</th>
                                <th>Roll Number</th>
                                <th>Email &amp; Phone</th>
                                <th>Hostel / Room</th>
                                <th>Registered On</th>
                                <th>Status</th>
                                <th>Approval Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for(User st : pendingStudentsList){ %>
                            <tr>
                                <td>
                                    <% 
                                        String photoUrl = st.getResolvedProfilePhoto(request.getContextPath());
                                        String idCardUrl = st.getResolvedIdCard(request.getContextPath());
                                    %>
                                    <% if(photoUrl != null){ %>
                                        <a href="<%=photoUrl%>" target="_blank" title="Click to view full photo">
                                            <img src="<%=photoUrl%>" style="width:38px;height:38px;border-radius:50%;object-fit:cover;border:1px solid var(--line);" onerror="this.style.display='none'">
                                        </a>
                                    <% } else { %>
                                        <div style="width:38px;height:38px;border-radius:50%;background:#e0f2fe;color:#0369a1;display:inline-flex;align-items:center;justify-content:center;font-weight:bold;font-size:0.9rem;">
                                            <%= st.getName()!=null && !st.getName().isEmpty() ? st.getName().substring(0,1).toUpperCase() : "S" %>
                                        </div>
                                    <% } %>
                                    <% if(idCardUrl != null){ %>
                                        <br><a href="<%=idCardUrl%>" target="_blank" style="font-size:0.75rem;color:var(--blue);font-weight:600;text-decoration:underline;">👁 View ID</a>
                                    <% } %>
                                </td>
                                <td><strong><%=st.getName()%></strong></td>
                                <td><code><%=st.getRollNumber()!=null ? st.getRollNumber() : "N/A"%></code></td>
                                <td><%=st.getEmail()%><% if(st.getPhone()!=null && !st.getPhone().isBlank()){ %><br><small class="muted">&#128222; <%=st.getPhone()%></small><% } %></td>
                                <td><%=st.getHostel()!=null ? st.getHostel() : "N/A"%> / <%=st.getRoomNo()!=null ? st.getRoomNo() : "N/A"%></td>
                                <td><small><%=st.getCreatedAt()!=null ? st.getCreatedAt() : "Recently"%></small></td>
                                <td><span class="pill" style="background:#fef3c7;color:#92400e;">Pending Approval</span></td>
                                <td>
                                    <div style="display:flex;gap:6px;align-items:center;">
                                        <form method="post" action="${pageContext.request.contextPath}/admin/action" style="margin:0;">
                                            <input type="hidden" name="action" value="verify">
                                            <input type="hidden" name="studentId" value="<%=st.getId()%>">
                                            <input type="hidden" name="approve" value="true">
                                            <input type="hidden" name="tab" value="overview">
                                            <button class="primary small" type="submit">&#10003; Approve Account</button>
                                        </form>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/action" style="margin:0;" onsubmit="return confirm('Are you sure you want to reject student <%=st.getName()%>?');">
                                            <input type="hidden" name="action" value="verify">
                                            <input type="hidden" name="studentId" value="<%=st.getId()%>">
                                            <input type="hidden" name="approve" value="false">
                                            <input type="hidden" name="tab" value="overview">
                                            <button class="danger small" type="submit">&#10005; Reject</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <% } %>

            <% if(!pendingOrdersList.isEmpty()){ %>
            <div style="margin-top:1.5rem;">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
                    <h4 style="margin:0;color:var(--text);font-size:1.05rem;">🧺 Student Laundry Order Requests (<%=pendingOrdersList.size()%>)</h4>
                    <small class="muted">Assign bags and approve incoming laundry</small>
                </div>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Order #</th>
                                <th>Student</th>
                                <th>Request Type</th>
                                <th>Date Submitted</th>
                                <th>Garments / Details</th>
                                <th>Status</th>
                                <th>Assign Bag</th>
                                <th>Approval Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for(LaundryOrder o : pendingOrdersList){ %>
                            <tr>
                                <td><strong><%=o.getOrderNumber()%></strong></td>
                                <td><%=o.getStudentName()%><br><small class="muted"><%=o.getStudentRoll()%></small></td>
                                <td><span class="pill" style="background:#eff6ff;color:var(--blue);">Laundry Request</span></td>
                                <td><small><%=o.getCreatedAt()%></small></td>
                                <td>
                                    <strong><%=o.getTotalItems()%> items</strong>
                                    <% if(!o.getItems().isEmpty()){ %>
                                        <div style="font-size:0.75rem;color:var(--muted);margin-top:4px;">
                                            <% for(var e : o.getItems().entrySet()){ %>
                                                <span><%=e.getKey()%>: <b><%=e.getValue()%></b>&nbsp;</span>
                                            <% } %>
                                        </div>
                                    <% } %>
                                </td>
                                <td><span class="pill" style="background:#fef3c7;color:#92400e;"><%=o.getStatus()%></span></td>
                                <td>
                                    <input type="number" name="bag" form="ovApproveForm_<%=o.getId()%>" min="1" placeholder="e.g. 101" style="width:90px;padding:6px 8px;">
                                </td>
                                <td>
                                    <div style="display:flex;gap:6px;align-items:center;">
                                        <form id="ovApproveForm_<%=o.getId()%>" method="post" action="${pageContext.request.contextPath}/admin/action" style="margin:0;">
                                            <input type="hidden" name="action" value="accept">
                                            <input type="hidden" name="orderId" value="<%=o.getId()%>">
                                            <input type="hidden" name="tab" value="overview">
                                            <button class="primary small" type="submit">Approve + QR</button>
                                        </form>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/action" style="margin:0;" onsubmit="return confirm('Are you sure you want to reject request #<%=o.getOrderNumber()%>?');">
                                            <input type="hidden" name="action" value="reject">
                                            <input type="hidden" name="orderId" value="<%=o.getId()%>">
                                            <input type="hidden" name="tab" value="overview">
                                            <button class="danger small" type="submit">Reject</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            <% } %>
        </section>

        <section>
            <div class="section-head"><h3>Audit Logs</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Time</th><th>Role</th><th>Action</th><th>Details</th><th>IP</th></tr>
                    <%for(AuditLog a:logs){%>
                    <tr>
                        <td><%=a.getCreatedAt()%></td>
                        <td><%=a.getActorRole()%></td>
                        <td><%=a.getAction()%></td>
                        <td><%=a.getDetails()%></td>
                        <td><%=a.getIpAddress()%></td>
                    </tr>
                    <%}%>
                </table>
            </div>
        </section>
        <% } %>

        <% if("requests".equals(tab)) { %>
        <section id="requests">
            <div class="section-head" style="margin-bottom:1.5rem;">
                <div>
                    <h3>Pending Requests Queue (<%=totalPending%>)</h3>
                    <small class="muted">Review and approve incoming student account registrations and laundry service submissions</small>
                </div>
            </div>

            <!-- Part 1: Student Account Registrations -->
            <div class="card" style="margin-bottom:2rem;padding:1.25rem;">
                <div class="section-head" style="margin-bottom:1rem;display:flex;justify-content:space-between;align-items:center;">
                    <div>
                        <h4 style="margin:0;font-size:1.1rem;">🎓 Student Account Registration Requests (<%=pendingStudentsList.size()%>)</h4>
                        <small class="muted">New student accounts that require admin verification before login</small>
                    </div>
                    <% if(!pendingStudentsList.isEmpty()){ %>
                        <span class="pill" style="background:#fef3c7;color:#92400e;font-weight:600;"><%=pendingStudentsList.size()%> Awaiting Approval</span>
                    <% } %>
                </div>
                <% if(pendingStudentsList.isEmpty()){ %>
                    <div class="empty">
                        <p>🎉 No pending student account registration requests.</p>
                    </div>
                <% } else { %>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Photo / ID</th>
                                <th>Student Name</th>
                                <th>Roll Number</th>
                                <th>Email &amp; Phone</th>
                                <th>Hostel / Room</th>
                                <th>Registered Date</th>
                                <th>Status</th>
                                <th>Approval Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for(User st : pendingStudentsList){ %>
                            <tr>
                                <td>
                                    <% 
                                        String photoUrl = st.getResolvedProfilePhoto(request.getContextPath());
                                        String idCardUrl = st.getResolvedIdCard(request.getContextPath());
                                    %>
                                    <% if(photoUrl != null){ %>
                                        <a href="<%=photoUrl%>" target="_blank" title="Click to view full photo">
                                            <img src="<%=photoUrl%>" style="width:38px;height:38px;border-radius:50%;object-fit:cover;border:1px solid var(--line);" onerror="this.style.display='none'">
                                        </a>
                                    <% } else { %>
                                        <div style="width:38px;height:38px;border-radius:50%;background:#e0f2fe;color:#0369a1;display:inline-flex;align-items:center;justify-content:center;font-weight:bold;font-size:0.9rem;">
                                            <%= st.getName()!=null && !st.getName().isEmpty() ? st.getName().substring(0,1).toUpperCase() : "S" %>
                                        </div>
                                    <% } %>
                                    <% if(idCardUrl != null){ %>
                                        <br><a href="<%=idCardUrl%>" target="_blank" style="font-size:0.75rem;color:var(--blue);font-weight:600;text-decoration:underline;">👁 View ID</a>
                                    <% } %>
                                </td>
                                <td><strong><%=st.getName()%></strong></td>
                                <td><code><%=st.getRollNumber()!=null ? st.getRollNumber() : "N/A"%></code></td>
                                <td><%=st.getEmail()%><% if(st.getPhone()!=null && !st.getPhone().isBlank()){ %><br><small class="muted">&#128222; <%=st.getPhone()%></small><% } %></td>
                                <td><%=st.getHostel()!=null ? st.getHostel() : "N/A"%> / <%=st.getRoomNo()!=null ? st.getRoomNo() : "N/A"%></td>
                                <td><small><%=st.getCreatedAt()!=null ? st.getCreatedAt() : "Recently"%></small></td>
                                <td><span class="pill" style="background:#fef3c7;color:#92400e;">Pending Approval</span></td>
                                <td>
                                    <div style="display:flex;gap:6px;align-items:center;">
                                        <form method="post" action="${pageContext.request.contextPath}/admin/action" style="margin:0;">
                                            <input type="hidden" name="action" value="verify">
                                            <input type="hidden" name="studentId" value="<%=st.getId()%>">
                                            <input type="hidden" name="approve" value="true">
                                            <input type="hidden" name="tab" value="requests">
                                            <button class="primary small" type="submit">&#10003; Approve Account</button>
                                        </form>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/action" style="margin:0;" onsubmit="return confirm('Are you sure you want to reject registration for <%=st.getName()%>?');">
                                            <input type="hidden" name="action" value="verify">
                                            <input type="hidden" name="studentId" value="<%=st.getId()%>">
                                            <input type="hidden" name="approve" value="false">
                                            <input type="hidden" name="tab" value="requests">
                                            <button class="danger small" type="submit">&#10005; Reject</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                <% } %>
            </div>

            <!-- Part 2: Laundry Order Requests -->
            <div class="card" style="margin-bottom:2rem;padding:1.25rem;">
                <div class="section-head" style="margin-bottom:1rem;display:flex;justify-content:space-between;align-items:center;">
                    <div>
                        <h4 style="margin:0;font-size:1.1rem;">🧺 Laundry Order Requests (<%=pendingOrdersList.size()%>)</h4>
                        <small class="muted">Review student laundry submissions, assign bag numbers, and approve or reject</small>
                    </div>
                    <% if(!pendingOrdersList.isEmpty()){ %>
                        <span class="pill" style="background:#fef3c7;color:#92400e;font-weight:600;"><%=pendingOrdersList.size()%> Awaiting Bag &amp; Approval</span>
                    <% } %>
                </div>
                <% if(pendingOrdersList.isEmpty()){ %>
                    <div class="empty">
                        <p>🎉 No pending laundry requests waiting for approval.</p>
                    </div>
                <% } else { %>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Order #</th>
                                <th>Student</th>
                                <th>Request Type</th>
                                <th>Date Submitted</th>
                                <th>Garments / Details</th>
                                <th>Status</th>
                                <th>Assign Bag</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for(LaundryOrder o : pendingOrdersList){ %>
                            <tr>
                                <td><strong><%=o.getOrderNumber()%></strong></td>
                                <td><%=o.getStudentName()%><br><small class="muted"><%=o.getStudentRoll()%></small></td>
                                <td><span class="pill" style="background:#eff6ff;color:var(--blue);">Laundry Request</span></td>
                                <td><small><%=o.getCreatedAt()%></small></td>
                                <td>
                                    <strong><%=o.getTotalItems()%> items</strong>
                                    <% if(!o.getItems().isEmpty()){ %>
                                        <div style="font-size:0.75rem;color:var(--muted);margin-top:4px;">
                                            <% for(var e : o.getItems().entrySet()){ %>
                                                <span><%=e.getKey()%>: <b><%=e.getValue()%></b>&nbsp;</span>
                                            <% } %>
                                        </div>
                                    <% } %>
                                </td>
                                <td><span class="pill" style="background:#fef3c7;color:#92400e;"><%=o.getStatus()%></span></td>
                                <td>
                                    <input type="number" name="bag" form="reqApproveForm_<%=o.getId()%>" min="1" placeholder="e.g. 101" style="width:90px;padding:6px 8px;">
                                </td>
                                <td>
                                    <div style="display:flex;gap:6px;align-items:center;">
                                        <form id="reqApproveForm_<%=o.getId()%>" method="post" action="${pageContext.request.contextPath}/admin/action" style="margin:0;">
                                            <input type="hidden" name="action" value="accept">
                                            <input type="hidden" name="orderId" value="<%=o.getId()%>">
                                            <input type="hidden" name="tab" value="requests">
                                            <button class="primary small" type="submit">Approve + QR</button>
                                        </form>
                                        <form method="post" action="${pageContext.request.contextPath}/admin/action" style="margin:0;" onsubmit="return confirm('Are you sure you want to reject request #<%=o.getOrderNumber()%>?');">
                                            <input type="hidden" name="action" value="reject">
                                            <input type="hidden" name="orderId" value="<%=o.getId()%>">
                                            <input type="hidden" name="tab" value="requests">
                                            <button class="danger small" type="submit">Reject</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                <% } %>
            </div>
        </section>
        <% } %>

        <% if("pipeline".equals(tab)) { %>
        <section id="pipeline">
            <div class="section-head"><h3>Active Pipeline</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Order / Bag</th><th>Student</th><th>Status</th><th>Stage</th><th>Update &amp; Alert</th></tr>
                    <%for(LaundryOrder o:orders)if(!Set.of("Pending Approval","Delivered","Rejected","Cancelled").contains(o.getStatus())){%>
                    <tr>
                        <td><%=o.getOrderNumber()%><small>Bag <%=o.getBagNumber()%></small></td>
                        <td><%=o.getStudentName()%></td>
                        <td><span class="pill"><%=o.getStatus()%></span></td>
                        <td><%=o.getCurrentStage()%></td>
                        <td>
                            <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap;">
                                <form method="post" action="${pageContext.request.contextPath}/admin/action" class="inline" style="display:flex;gap:5px;align-items:center;margin:0;">
                                    <input type="hidden" name="action" value="stage">
                                    <input type="hidden" name="orderId" value="<%=o.getId()%>">
                                    <input type="hidden" name="tab" value="pipeline">
                                    <select name="stage" style="padding:4px;font-size:0.8rem;border:1px solid var(--line);border-radius:4px;">
                                        <option <%= "Received".equals(o.getCurrentStage()) ? "selected" : "" %>>Received</option>
                                        <option <%= "Sorting".equals(o.getCurrentStage()) ? "selected" : "" %>>Sorting</option>
                                        <option <%= "Washing".equals(o.getCurrentStage()) ? "selected" : "" %>>Washing</option>
                                        <option <%= "Drying".equals(o.getCurrentStage()) ? "selected" : "" %>>Drying</option>
                                        <option <%= "Ironing".equals(o.getCurrentStage()) ? "selected" : "" %>>Ironing</option>
                                        <option <%= "Ready for Pickup".equals(o.getCurrentStage()) ? "selected" : "" %>>Ready for Pickup</option>
                                    </select>
                                    <button class="secondary small">Update</button>
                                </form>
                                <% if("Ready for Pickup".equals(o.getCurrentStage())) { %>
                                    <a href="<%= o.getWhatsAppReadyUrl() %>" target="_blank" rel="noopener noreferrer"
                                       title="Send WhatsApp Ready for Pickup alert to <%= o.getStudentName() %>"
                                       style="display:inline-flex;align-items:center;gap:4px;padding:4px 9px;font-size:0.8rem;font-weight:700;background:#25D366;color:white;border-radius:4px;text-decoration:none;box-shadow:0 1px 4px rgba(37,211,102,0.4);white-space:nowrap;">
                                        💬 WhatsApp Ready
                                    </a>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <%}%>
                </table>
            </div>
        </section>
        <% } %>

        <% if("students".equals(tab)) { %>
        <section id="students">
            <div class="section-head"><h3>Student Verification</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Photo</th><th>Name</th><th>Roll</th><th>Hostel</th><th>Quota</th><th>Verification</th><th>Action</th></tr>
                    <%for(User st:students){%>
                    <tr>
                        <td>
                            <% 
                                String photoUrl = st.getResolvedProfilePhoto(request.getContextPath());
                                String idCardUrl = st.getResolvedIdCard(request.getContextPath());
                            %>
                            <% if(photoUrl != null){ %>
                                <a href="<%=photoUrl%>" target="_blank" title="Click to view full photo">
                                    <img src="<%=photoUrl%>" style="width:40px;height:40px;border-radius:50%;object-fit:cover;border:1px solid var(--line);" onerror="this.style.display='none'">
                                </a>
                            <% } %>
                            <% if(idCardUrl != null){ %>
                                <br><a href="<%=idCardUrl%>" target="_blank" style="font-size:0.75rem;color:var(--blue);font-weight:600;text-decoration:underline;">👁 View ID</a>
                            <% } %>
                        </td>
                        <td><%=st.getName()%><small><%=st.getEmail()%></small></td>
                        <td><%=st.getRollNumber()%></td>
                        <td><%=st.getHostel()%> / <%=st.getRoomNo()%></td>
                        <td><%=st.getMembershipUsed()%>/<%=st.getMembershipLimit()%></td>
                        <td>
                            <% if("Approved".equals(st.getVerificationStatus())) { %>
                                <span class="pill" style="background:#e5f5e9;color:#0d652d;">&#10003; Approved</span>
                            <% } else if("Rejected".equals(st.getVerificationStatus())) { %>
                                <span class="pill" style="background:#fde8e7;color:#b3261e;">&#10005; Rejected</span>
                            <% } else { %>
                                <span class="pill">Pending</span>
                            <% } %>
                        </td>
                        <td>
                            <% if(st.getVerificationStatus() == null || "Pending".equals(st.getVerificationStatus())) { %>
                            <form method="post" action="${pageContext.request.contextPath}/admin/action" class="inline">
                                <input type="hidden" name="action" value="verify">
                                <input type="hidden" name="studentId" value="<%=st.getId()%>">
                                <button name="approve" value="true" class="primary small">Approve</button>
                                <button name="approve" value="false" class="danger small">Reject</button>
                            </form>
                            <% } else { %>
                                &mdash;
                            <% } %>
                        </td>
                    </tr>
                    <%}%>
                </table>
            </div>
        </section>
        <% } %>

        <% if("staff".equals(tab)) { %>
        <section id="staff">
            <div class="section-head"><h3>Staff Verification</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Photo</th><th>Name</th><th>Staff ID</th><th>Area</th><th>Verification</th><th>Action</th></tr>
                    <%if(staffList!=null) for(User st:staffList){%>
                    <tr>
                        <td>
                            <% 
                                String photoUrl = st.getResolvedProfilePhoto(request.getContextPath());
                                String idCardUrl = st.getResolvedIdCard(request.getContextPath());
                            %>
                            <% if(photoUrl != null){ %>
                                <a href="<%=photoUrl%>" target="_blank" title="Click to view full photo">
                                    <img src="<%=photoUrl%>" style="width:40px;height:40px;border-radius:50%;object-fit:cover;border:1px solid var(--line);" onerror="this.style.display='none'">
                                </a>
                            <% } %>
                            <% if(idCardUrl != null){ %>
                                <br><a href="<%=idCardUrl%>" target="_blank" style="font-size:0.75rem;color:var(--blue);font-weight:600;text-decoration:underline;">👁 View ID</a>
                            <% } %>
                        </td>
                        <td><%=st.getName()%><small><%=st.getEmail()%></small></td>
                        <td><%=st.getRollNumber()%></td>
                        <td><%=st.getHostel()%> / <%=st.getRoomNo()%></td>
                        <td>
                            <% if("Approved".equals(st.getVerificationStatus())) { %>
                                <span class="pill" style="background:#e5f5e9;color:#0d652d;">&#10003; Approved</span>
                            <% } else if("Rejected".equals(st.getVerificationStatus())) { %>
                                <span class="pill" style="background:#fde8e7;color:#b3261e;">&#10005; Rejected</span>
                            <% } else { %>
                                <span class="pill">Pending</span>
                            <% } %>
                        </td>
                        <td>
                            <% if(st.getVerificationStatus() == null || "Pending".equals(st.getVerificationStatus())) { %>
                            <form method="post" action="${pageContext.request.contextPath}/admin/action" class="inline">
                                <input type="hidden" name="action" value="verify">
                                <input type="hidden" name="studentId" value="<%=st.getId()%>">
                                <button name="approve" value="true" class="primary small">Approve</button>
                                <button name="approve" value="false" class="danger small">Reject</button>
                            </form>
                            <% } else { %>
                                &mdash;
                            <% } %>
                        </td>
                    </tr>
                    <%}%>
                </table>
            </div>
        </section>
        <% } %>

        <% if("renewals".equals(tab)) { %>
        <section id="renewals">
            <div class="section-head"><h3>Quota Renewal Requests</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Student</th><th>Current</th><th>Requested</th><th>Status</th><th>Action</th></tr>
                    <%for(RenewalRequest rr:renewals){%>
                    <tr>
                        <td><%=rr.getStudentName()%><small><%=rr.getStudentRoll()%></small></td>
                        <td><%=rr.getMembershipUsed()%>/<%=rr.getMembershipLimit()%></td>
                        <td>+<%=rr.getRequestedCredits()%></td>
                        <td><%=rr.getStatus()%></td>
                        <td>
                            <%if("Pending".equals(rr.getStatus())){%>
                            <form method="post" action="${pageContext.request.contextPath}/admin/action" class="inline">
                                <input type="hidden" name="action" value="renewal">
                                <input type="hidden" name="requestId" value="<%=rr.getId()%>">
                                <input name="notes" placeholder="Optional note">
                                <button name="approve" value="true" class="primary small">Approve</button>
                                <button name="approve" value="false" class="danger small">Reject</button>
                            </form>
                            <%}%>
                        </td>
                    </tr>
                    <%}%>
                </table>
            </div>
        </section>
        <% } %>

        <% if("complaints".equals(tab)) { %>
        <section id="complaints">
            <div class="section-head"><h3>Mismatch & Complaint Queue</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Student</th><th>Bag</th><th>Issue</th><th>Description</th><th>Status</th><th>Resolve</th></tr>
                    <%for(Complaint c:complaints){%>
                    <tr>
                        <td><%=c.getStudentName()%></td>
                        <td><%=c.getBagNumber()%></td>
                        <td><%=c.getCategory()%>: <%=c.getIssueType()%></td>
                        <td><%=c.getDescription()%></td>
                        <td><%=c.getStatus()%></td>
                        <td>
                            <%if("Unresolved".equals(c.getStatus())){%>
                            <form method="post" action="${pageContext.request.contextPath}/admin/action" class="inline">
                                <input type="hidden" name="action" value="complaint">
                                <input type="hidden" name="complaintId" value="<%=c.getId()%>">
                                <input name="notes" required placeholder="Resolution note">
                                <button class="primary small">Resolve</button>
                            </form>
                            <%}%>
                        </td>
                    </tr>
                    <%}%>
                </table>
            </div>
        </section>
        <% } %>
        <% if("history".equals(tab)) { %>
        <section id="history">
            <div class="section-head" style="display:flex; justify-content:space-between; align-items:center;">
                <div>
                    <h3>Order History Archive</h3>
                    <small class="muted">Permanent log of all orders including delivered and cancelled.</small>
                </div>
                <input type="text" id="histSearch" placeholder="🔍 Search History..." style="padding:8px 12px; border:1px solid var(--line); border-radius:var(--radius-sm); width:220px;">
            </div>
            <div class="table-wrap">
                <table id="histTable">
                    <tr><th>Order / Bag</th><th>Student</th><th>Items</th><th>Status</th><th>Stage</th><th>Date</th><th>Action</th></tr>
                    <%for(LaundryOrder o:orders){%>
                    <tr class="hist-row">
                        <td>
                            <strong class="hist-text"><%=o.getOrderNumber()%></strong>
                            <% if(o.getBagNumber()!=null){ %><br><small class="hist-text">Bag: <%=o.getBagNumber()%></small><%}%>
                        </td>
                        <td>
                            <strong class="hist-text"><%=o.getStudentName()%></strong>
                            <br><small><%=o.getStudentRoll()%></small>
                        </td>
                        <td><%=o.getTotalItems()%></td>
                        <td>
                            <span class="pill" style="<%= "Delivered".equals(o.getStatus()) ? "background:#e5f5e9;color:#0d652d;" : ("Cancelled".equals(o.getStatus()) || "Rejected".equals(o.getStatus()) ? "background:#fde8e7;color:#b3261e;" : "") %>"><%=o.getStatus()%></span>
                        </td>
                        <td><%=o.getCurrentStage()%></td>
                        <td><small><%=o.getCreatedAt()%></small></td>
                        <td>
                            <% if("Ready for Pickup".equals(o.getCurrentStage())) { %>
                                <a href="<%= o.getWhatsAppReadyUrl() %>" target="_blank" rel="noopener noreferrer"
                                   title="Send WhatsApp Ready for Pickup alert to <%= o.getStudentName() %>"
                                   style="display:inline-flex;align-items:center;gap:4px;padding:3px 8px;font-size:0.75rem;font-weight:700;background:#25D366;color:white;border-radius:4px;text-decoration:none;box-shadow:0 1px 4px rgba(37,211,102,0.4);white-space:nowrap;">
                                    💬 WA Ready
                                </a>
                            <% } else if("Delivered".equals(o.getStatus())) { %>
                                <a href="<%= o.getWhatsAppDeliveredUrl() %>" target="_blank" rel="noopener noreferrer"
                                   title="Send WhatsApp Delivery Invoice to <%= o.getStudentName() %>"
                                   style="display:inline-flex;align-items:center;gap:4px;padding:3px 8px;font-size:0.75rem;font-weight:700;background:#25D366;color:white;border-radius:4px;text-decoration:none;box-shadow:0 1px 4px rgba(37,211,102,0.4);white-space:nowrap;">
                                    💬 Invoice WA
                                </a>
                            <% } else { %>
                                <span style="color:var(--muted);">&mdash;</span>
                            <% } %>
                        </td>
                    </tr>
                    <%}%>
                </table>
            </div>
            <script>
                document.getElementById('histSearch')?.addEventListener('input', function(e) {
                    const q = e.target.value.toLowerCase();
                    document.querySelectorAll('.hist-row').forEach(r => {
                        r.style.display = Array.from(r.querySelectorAll('.hist-text')).some(el => el.textContent.toLowerCase().includes(q)) ? '' : 'none';
                    });
                });
            </script>
        </section>
        <% } %>

        <% if("analytics".equals(tab)) { 
            int cRec=0, cSort=0, cWash=0, cDry=0, cIron=0, cReady=0;
            int sPend=0, sAct=0, sDel=0, sRej=0;
            Map<Long, User> studentMap = new HashMap<>();
            for(User s : students) studentMap.put(s.getId(), s);
            
            Map<String, Integer> hostelItemCount = new HashMap<>();
            
            for(LaundryOrder o : orders) {
                if("Received".equals(o.getCurrentStage())) cRec++;
                if("Sorting".equals(o.getCurrentStage())) cSort++;
                if("Washing".equals(o.getCurrentStage())) cWash++;
                if("Drying".equals(o.getCurrentStage())) cDry++;
                if("Ironing".equals(o.getCurrentStage())) cIron++;
                if("Ready for Pickup".equals(o.getCurrentStage())) cReady++;
                
                if(o.isPendingApproval()) sPend++;
                else if("Delivered".equals(o.getStatus())) sDel++;
                else if("Rejected".equals(o.getStatus()) || "Cancelled".equals(o.getStatus())) sRej++;
                else sAct++;
                
                // Hostel logic
                User st = studentMap.get(o.getStudentId());
                if (st != null && st.getHostel() != null) {
                    hostelItemCount.put(st.getHostel(), hostelItemCount.getOrDefault(st.getHostel(), 0) + o.getTotalItems());
                }
            }
            
            // Build JS arrays for hostel chart
            StringBuilder hLabels = new StringBuilder();
            StringBuilder hData = new StringBuilder();
            for(Map.Entry<String,Integer> entry : hostelItemCount.entrySet()) {
                hLabels.append("'").append(entry.getKey()).append("',");
                hData.append(entry.getValue()).append(",");
            }
        %>
        <section id="analytics">
            <div class="section-head">
                <div>
                    <h3>Data Analytics &amp; Visuals</h3>
                    <small class="muted">Interactive overview of system usage and load.</small>
                </div>
            </div>
            <div class="grid2">
                <div class="card">
                    <h4>Current Pipeline Load</h4>
                    <canvas id="stageChart"></canvas>
                </div>
                <div class="card">
                    <h4>Overall Order Status</h4>
                    <canvas id="statusChart"></canvas>
                </div>
                <div class="card span2">
                    <h4>Top Hostels by Clothes Volume</h4>
                    <canvas id="hostelChart" style="max-height: 300px;"></canvas>
                </div>
            </div>
            
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <script>
                new Chart(document.getElementById('stageChart'), {
                    type: 'doughnut',
                    data: {
                        labels: ['Received', 'Sorting', 'Washing', 'Drying', 'Ironing', 'Ready'],
                        datasets: [{
                            data: [<%=cRec%>, <%=cSort%>, <%=cWash%>, <%=cDry%>, <%=cIron%>, <%=cReady%>],
                            backgroundColor: ['#e0f2fe', '#fef3c7', '#ede9fe', '#fce7f3', '#ecfdf5', '#d1fae5'],
                            borderColor: ['#0369a1', '#92400e', '#6d28d9', '#9d174d', '#065f46', '#065f46'],
                            borderWidth: 1
                        }]
                    }
                });
                new Chart(document.getElementById('statusChart'), {
                    type: 'bar',
                    data: {
                        labels: ['Pending', 'Active (In-Pipeline)', 'Delivered', 'Rejected/Cancelled'],
                        datasets: [{
                            label: 'Number of Orders',
                            data: [<%=sPend%>, <%=sAct%>, <%=sDel%>, <%=sRej%>],
                            backgroundColor: ['#fef3c7', '#eff6ff', '#e5f5e9', '#fde8e7'],
                            borderColor: ['#d97706', '#3b82f6', '#10b981', '#ef4444'],
                            borderWidth: 1
                        }]
                    },
                    options: { scales: { y: { beginAtZero: true } } }
                });
                new Chart(document.getElementById('hostelChart'), {
                    type: 'bar',
                    data: {
                        labels: [<%=hLabels.toString()%>],
                        datasets: [{
                            label: 'Total Clothes Processed',
                            data: [<%=hData.toString()%>],
                            backgroundColor: '#8b5cf6',
                            borderRadius: 6
                        }]
                    },
                    options: { 
                        scales: { y: { beginAtZero: true } },
                        plugins: { legend: { display: false } }
                    }
                });
            </script>
        </section>
        <% } %>

    </main>
</body>
</html>