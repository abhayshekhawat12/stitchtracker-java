<%@ page import="java.util.*,com.stitchtrack.model.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% 
    User u=(User)request.getAttribute("user"); 
    List<LaundryOrder> orders=(List<LaundryOrder>)request.getAttribute("orders"); 
    String flash=(String)session.getAttribute("flash"),ft=(String)session.getAttribute("flashType");
    session.removeAttribute("flash");
    session.removeAttribute("flashType");
    List<Map<String,Object>> notifs = (List<Map<String,Object>>)request.getAttribute("notifications");
    if(notifs == null) notifs = Collections.emptyList();
    long unreadCount = notifs.stream().filter(n -> !(Boolean)n.get("isRead")).count();
%>
<!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Student Dashboard - StitchTrack</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <style>
        .timeline { display: flex; align-items: center; justify-content: space-between; position: relative; margin: 20px 0; padding: 0 10px; }
        .timeline::before { content: ''; position: absolute; top: 12px; left: 20px; right: 20px; height: 2px; background: #e2e6ea; z-index: 1; }
        .timeline-step { display: flex; flex-direction: column; align-items: center; z-index: 2; position: relative; background: #fff; padding: 0 5px; }
        .timeline-dot { width: 26px; height: 26px; border-radius: 50%; background: #fff; border: 2px solid #e2e6ea; display: flex; align-items: center; justify-content: center; font-size: 0.7rem; font-weight: bold; color: #fff; margin-bottom: 5px; }
        .timeline-step.completed .timeline-dot { background: var(--ok); border-color: var(--ok); }
        .timeline-step.completed .timeline-dot::after { content: '✓'; }
        .timeline-step.current .timeline-dot { background: var(--blue); border-color: var(--blue); }
        .timeline-step.current .timeline-dot::after { content: '●'; }
        .timeline-label { font-size: 0.65rem; font-weight: 700; color: var(--muted); text-align: center; }
        .timeline-step.current .timeline-label { color: var(--blue); }
        .timeline-step.completed .timeline-label { color: var(--ok); }
    </style>
</head>
<body>
    <header class="topbar">
        <div class="brand compact">
            <h1>StitchTrack</h1>
            <span>Student</span>
        </div>
        <nav>
            <a href="${pageContext.request.contextPath}/student/dashboard">Dashboard</a>
            <a href="${pageContext.request.contextPath}/student/new-request">New Request</a>
            <a href="${pageContext.request.contextPath}/student/subscription" style="display:inline-flex;align-items:center;gap:4px;font-weight:600;color:var(--blue);">⚡ Subscription</a>
            <a href="${pageContext.request.contextPath}/student/notifications" class="bell-wrapper" style="text-decoration:none;">
                🔔
                <% if(unreadCount > 0) { %><div class="bell-badge"><%=unreadCount%></div><% } %>
            </a>
            <a href="${pageContext.request.contextPath}/logout">Logout</a>
        </nav>
    </header>
    <main class="container">
        <% if(flash!=null){ %>
            <div class="alert <%=ft%>"><%=flash%></div>
        <% } %>
        
        <section class="hero">
            <div>
                <p class="eyebrow">WELCOME BACK, <%=u.getName().split(" ")[0].toUpperCase()%> 👋</p>
                <h2><%=u.getName()%></h2>
                <p>Roll: <%=u.getRollNumber()%> &middot; <%=u.getHostel()%> / <%=u.getRoomNo()%></p>
            </div>
            <div style="display:flex;gap:10px;flex-wrap:wrap;">
                <a class="button secondary" href="${pageContext.request.contextPath}/student/subscription" style="display:inline-flex;align-items:center;gap:6px;">💳 Plans & Credits</a>
                <% if ("Approved".equals(u.getVerificationStatus())) { %>
                    <a class="button primary" href="${pageContext.request.contextPath}/student/new-request">+ New Laundry Request</a>
                <% } else { %>
                    <button class="button primary" style="opacity: 0.5;" disabled>Account Pending Verification</button>
                <% } %>
            </div>
        </section>
        
        <section class="cards">
            <article class="card">
                <span>Laundry Credit Balance</span>
                <strong><%=u.getMembershipUsed()%> / <%=u.getMembershipLimit()%> <span style="font-size:0.85rem;font-weight:normal;color:var(--muted);">credits</span></strong>
                <div class="progress">
                    <i style="width:<%=Math.min(100,(u.getMembershipUsed()*100/Math.max(1,u.getMembershipLimit())))%>%"></i>
                </div>
                <div style="display:flex;justify-content:space-between;align-items:center;margin-top:6px;">
                    <small><strong><%=u.getCreditsLeft()%></strong> credits available</small>
                    <span style="font-size:0.75rem;color:var(--muted);background:#f1f5f9;padding:2px 8px;border-radius:10px;">Large items = 3 credits</span>
                </div>
                <div style="margin-top:12px;display:flex;gap:8px;flex-wrap:wrap;align-items:center;">
                    <a href="${pageContext.request.contextPath}/student/subscription" class="button primary" style="padding:6px 14px;font-size:0.82rem;text-decoration:none;">+ Top-up Credits</a>
                    <form method="post" action="${pageContext.request.contextPath}/student/support" style="margin:0;">
                        <input type="hidden" name="action" value="renewal">
                        <button class="linkbtn" style="font-size:0.8rem;">Emergency quota</button>
                    </form>
                </div>
            </article>
            <article class="card">
                <span>Account Status</span>
                <strong><%=u.getAccountStatus()%></strong>
                <% if("Approved".equals(u.getVerificationStatus())) { %>
                    <small style="color:var(--ok);font-weight:700;">✓ Verified</small>
                <% } else if("Rejected".equals(u.getVerificationStatus())) { %>
                    <small style="color:var(--danger);font-weight:700;">✕ Rejected</small>
                <% } else { %>
                    <small style="color:var(--muted);font-weight:700;">Pending Verification</small>
                <% } %>
            </article>
        </section>
        
        <section>
            <div class="section-head">
                <h3>My Laundry Orders</h3>
            </div>
            <div class="order-grid">
                <% if(orders.isEmpty()){ %>
                    <div class="empty">
                        <p>You haven't submitted a laundry request yet.</p>
                        <% if ("Approved".equals(u.getVerificationStatus())) { %>
                            <a class="button secondary" href="${pageContext.request.contextPath}/student/new-request" style="margin-top:10px;">Create Laundry Request</a>
                        <% } %>
                    </div>
                <% } %>
                
                <% for(LaundryOrder o:orders) { 
                    String st = o.getCurrentStage();
                    boolean isAssigned = o.getBagNumber() != null;
                    boolean isPickedUp = Arrays.asList("Received", "Sorting", "Washing", "Drying", "Ironing", "Ready for Pickup", "Delivered").contains(st);
                    boolean isWashing = Arrays.asList("Washing", "Drying", "Ironing", "Ready for Pickup", "Delivered").contains(st);
                    boolean isReady = Arrays.asList("Ready for Pickup", "Delivered").contains(st);
                    boolean isDelivered = "Delivered".equals(st);
                %>
                <article class="order-card">
                    <div class="order-top">
                        <div>
                            <b><%=o.getOrderNumber()%></b>
                            <small>Date: <%=o.getCreatedAt()%></small>
                        </div>
                        <span class="pill" style="
                            <%= "Delivered".equals(o.getStatus()) ? "background:#e5f5e9;color:#0d652d;" : "" %>
                            <%= "Cancelled".equals(o.getStatus()) || "Rejected".equals(o.getStatus()) ? "background:#fde8e7;color:#b3261e;" : "" %>
                        "><%=o.getStatus()%></span>
                    </div>
                    
                    <div class="order-meta">
                        <span>Bag ID: <b><%=o.getBagNumber()==null?"Pending":o.getBagNumber()%></b></span>
                        <span><b><%=o.getTotalItems()%></b> items</span>
                        <span>Credits: <b><%=o.getTotalCredits() > 0 ? o.getTotalCredits() : o.getTotalItems()%></b></span>
                        <span>Stage: <b><%=o.getCurrentStage()%></b></span>
                    </div>
                    
                    <% if(!"Cancelled".equals(o.getStatus()) && !"Rejected".equals(o.getStatus())) { %>
                    <div class="timeline">
                        <div class="timeline-step completed"><div class="timeline-dot"></div><div class="timeline-label">Submitted</div></div>
                        <div class="timeline-step <%= isAssigned ? "completed" : (o.isPendingApproval() ? "current" : "") %>"><div class="timeline-dot"></div><div class="timeline-label">Bag Assigned</div></div>
                        <div class="timeline-step <%= isPickedUp ? "completed" : (isAssigned && !isPickedUp ? "current" : "") %>"><div class="timeline-dot"></div><div class="timeline-label">Picked Up</div></div>
                        <div class="timeline-step <%= isWashing ? "completed" : (isPickedUp && !isWashing ? "current" : "") %>"><div class="timeline-dot"></div><div class="timeline-label">Washing</div></div>
                        <div class="timeline-step <%= isReady ? "completed" : (isWashing && !isReady ? "current" : "") %>"><div class="timeline-dot"></div><div class="timeline-label">Ready</div></div>
                        <div class="timeline-step <%= isDelivered ? "completed" : (isReady && !isDelivered ? "current" : "") %>"><div class="timeline-dot"></div><div class="timeline-label">Delivered</div></div>
                    </div>
                    <% } %>

                    <% if(o.getQrToken()!=null && "unused".equalsIgnoreCase(o.getQrStatus())) { %>
                    <div class="qrbox">
                        <img src="${pageContext.request.contextPath}/qr?token=<%=java.net.URLEncoder.encode(o.getQrToken(),"UTF-8")%>" onerror="this.style.display='none'">
                        <div>
                            <b>Single-Use Pickup QR</b>
                            <code><%=o.getQrToken()%></code>
                            <small>Show this to the delivery staff. It becomes invalid after use.</small>
                        </div>
                    </div>
                    <% } %>
                    
                    <details>
                        <summary>Garment breakdown</summary>
                        <div class="chips">
                            <% for(var e:o.getItems().entrySet()) { %>
                                <span><%=e.getKey()%>: <b><%=e.getValue()%></b></span>
                            <% } %>
                        </div>
                    </details>
                    <details>
                        <summary>Report an issue</summary>
                        <form method="post" action="${pageContext.request.contextPath}/student/support" class="stack mini" style="margin-top:10px;">
                            <input type="hidden" name="action" value="complaint">
                            <input type="hidden" name="orderId" value="<%=o.getId()%>">
                            <input type="hidden" name="bag" value="<%=o.getBagNumber()==null?"":o.getBagNumber()%>">
                            <select name="category">
                                <option value="mismatch">Mismatch</option>
                                <option value="complaint">Complaint</option>
                            </select>
                            <select name="issue">
                                <option>Garment Count Mismatch</option>
                                <option>Missing Item</option>
                                <option>Damaged Item</option>
                                <option>Wrong Bag</option>
                                <option>Delay</option>
                                <option>Other</option>
                            </select>
                            <textarea name="description" placeholder="Describe the issue" required></textarea>
                            <button class="secondary small">Submit Report</button>
                        </form>
                    </details>
                </article>
                <% } %>
            </div>
        </section>
    </main>
</body>
</html>