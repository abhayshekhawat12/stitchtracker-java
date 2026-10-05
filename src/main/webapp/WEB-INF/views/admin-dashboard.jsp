<%@ page import="java.util.*,com.stitchtrack.model.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% 
List<User> students=(List<User>)request.getAttribute("students");
List<LaundryOrder> orders=(List<LaundryOrder>)request.getAttribute("orders");
List<RenewalRequest> renewals=(List<RenewalRequest>)request.getAttribute("renewals");
List<Complaint> complaints=(List<Complaint>)request.getAttribute("complaints");
List<AuditLog> logs=(List<AuditLog>)request.getAttribute("auditLogs");
String flash=(String)session.getAttribute("flash"),ft=(String)session.getAttribute("flashType");
session.removeAttribute("flash");session.removeAttribute("flashType");
long pending=orders.stream().filter(o->"Pending Approval".equals(o.getStatus())).count(), 
     active=orders.stream().filter(o->!Set.of("Pending Approval","Delivered","Rejected","Cancelled").contains(o.getStatus())).count();
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
            <a href="?tab=requests" class="<%= "requests".equals(tab) ? "active" : "" %>">Requests</a>
            <a href="?tab=pipeline" class="<%= "pipeline".equals(tab) ? "active" : "" %>">Pipeline</a>
            <a href="?tab=history" class="<%= "history".equals(tab) ? "active" : "" %>">History</a>
            <a href="?tab=students" class="<%= "students".equals(tab) ? "active" : "" %>">Students</a>
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
            <article class="card"><span>Pending Requests</span><strong><%=pending%></strong></article>
            <article class="card"><span>Active Pipeline</span><strong><%=active%></strong></article>
            <article class="card"><span>Students</span><strong><%=students.size()%></strong></article>
            <article class="card"><span>Open Issues</span><strong><%=complaints.stream().filter(c->"Unresolved".equals(c.getStatus())).count()%></strong></article>
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
            <div class="section-head"><h3>Pending Laundry Requests</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Order</th><th>Student</th><th>Items</th><th>Assign Bag</th><th>Action</th></tr>
                    <%for(LaundryOrder o:orders)if("Pending Approval".equals(o.getStatus())){%>
                    <tr>
                        <td><%=o.getOrderNumber()%></td>
                        <td><%=o.getStudentName()%><small><%=o.getStudentRoll()%></small></td>
                        <td><%=o.getTotalItems()%></td>
                        <td colspan="2">
                            <form method="post" action="${pageContext.request.contextPath}/admin/action" class="inline">
                                <input type="hidden" name="action" value="accept">
                                <input type="hidden" name="orderId" value="<%=o.getId()%>">
                                <input type="number" name="bag" required min="1" placeholder="905">
                                <button class="primary small">Accept + Generate QR</button>
                            </form>
                        </td>
                    </tr>
                    <%}%>
                </table>
            </div>
        </section>
        <% } %>

        <% if("pipeline".equals(tab)) { %>
        <section id="pipeline">
            <div class="section-head"><h3>Active Pipeline</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Order / Bag</th><th>Student</th><th>Status</th><th>Stage</th><th>Update</th></tr>
                    <%for(LaundryOrder o:orders)if(!Set.of("Pending Approval","Delivered","Rejected","Cancelled").contains(o.getStatus())){%>
                    <tr>
                        <td><%=o.getOrderNumber()%><small>Bag <%=o.getBagNumber()%></small></td>
                        <td><%=o.getStudentName()%></td>
                        <td><span class="pill"><%=o.getStatus()%></span></td>
                        <td><%=o.getCurrentStage()%></td>
                        <td>
                            <form method="post" action="${pageContext.request.contextPath}/admin/action" class="inline">
                                <input type="hidden" name="action" value="stage">
                                <input type="hidden" name="orderId" value="<%=o.getId()%>">
                                <select name="stage">
                                    <option>Received</option>
                                    <option>Sorting</option>
                                    <option>Washing</option>
                                    <option>Drying</option>
                                    <option>Ironing</option>
                                    <option>Ready for Pickup</option>
                                </select>
                                <button class="secondary small">Update</button>
                            </form>
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
                            <% if(st.getProfilePhoto()!=null){ %>
                                <img src="${pageContext.request.contextPath}/<%=st.getProfilePhoto()%>" style="width:40px;height:40px;border-radius:50%;object-fit:cover;">
                            <% } %>
                            <% if(st.getIdCard()!=null){ %>
                                <br><a href="${pageContext.request.contextPath}/<%=st.getIdCard()%>" target="_blank" style="font-size:0.7rem;">View ID</a>
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
        <% List<User> staffList=(List<User>)request.getAttribute("staffList"); %>
        <section id="staff">
            <div class="section-head"><h3>Staff Verification</h3></div>
            <div class="table-wrap">
                <table>
                    <tr><th>Photo</th><th>Name</th><th>Staff ID</th><th>Area</th><th>Verification</th><th>Action</th></tr>
                    <%if(staffList!=null) for(User st:staffList){%>
                    <tr>
                        <td>
                            <% if(st.getProfilePhoto()!=null){ %>
                                <img src="${pageContext.request.contextPath}/<%=st.getProfilePhoto()%>" style="width:40px;height:40px;border-radius:50%;object-fit:cover;">
                            <% } %>
                            <% if(st.getIdCard()!=null){ %>
                                <br><a href="${pageContext.request.contextPath}/<%=st.getIdCard()%>" target="_blank" style="font-size:0.7rem;">View ID</a>
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
                    <tr><th>Order / Bag</th><th>Student</th><th>Items</th><th>Status</th><th>Stage</th><th>Date</th></tr>
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
                
                if("Pending Approval".equals(o.getStatus())) sPend++;
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