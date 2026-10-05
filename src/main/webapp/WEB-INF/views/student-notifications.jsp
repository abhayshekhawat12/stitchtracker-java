<%@ page import="java.util.*,com.stitchtrack.model.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% 
    User u=(User)request.getSession().getAttribute("user"); 
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
    <title>Notifications - StitchTrack</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <style>
        .notif-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius-md);
            padding: 20px;
            margin-bottom: 16px;
            display: flex;
            flex-direction: column;
            gap: 8px;
            transition: var(--transition);
        }
        .notif-card.unread {
            background: #f0f7ff;
            border-color: #bfdbfe;
        }
        .notif-card:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-sm);
        }
        .notif-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .notif-header h4 {
            margin: 0;
            font-size: 1.1rem;
            color: var(--ink);
        }
        .notif-time {
            font-size: 0.8rem;
            color: var(--muted);
            font-weight: 500;
        }
        .notif-msg {
            margin: 0;
            color: #475569;
            font-size: 0.95rem;
            line-height: 1.5;
        }
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
            <a href="${pageContext.request.contextPath}/student/notifications" class="bell-wrapper active" style="text-decoration:none;">
                🔔
                <% if(unreadCount > 0) { %><div class="bell-badge"><%=unreadCount%></div><% } %>
            </a>
            <a href="${pageContext.request.contextPath}/logout">Logout</a>
        </nav>
    </header>
    
    <main class="container narrow">
        <% if(flash!=null){ %>
            <div class="alert <%=ft%>"><%=flash%></div>
        <% } %>
        
        <div class="section-head" style="margin-top:20px;">
            <div>
                <h3>Your Notifications</h3>
                <small class="muted">Updates about your laundry requests and account.</small>
            </div>
            <% if(unreadCount > 0) { %>
            <form method="post" action="${pageContext.request.contextPath}/student/notifications" style="margin:0;">
                <input type="hidden" name="action" value="markRead">
                <button class="button secondary small">✔ Mark all as read</button>
            </form>
            <% } %>
        </div>
        
        <div class="notif-list">
            <% if(notifs.isEmpty()){ %>
                <div class="empty">
                    <p>No notifications yet.</p>
                </div>
            <% } else {
                for(Map<String,Object> n : notifs) { 
                    boolean isUnread = !(Boolean)n.get("isRead");
            %>
            <div class="notif-card <%= isUnread ? "unread" : "" %>">
                <div class="notif-header">
                    <h4>
                        <% if(isUnread) { %><span style="color:var(--danger);font-size:1.2rem;line-height:0;vertical-align:middle;margin-right:4px;">•</span><% } %>
                        <%=n.get("title")%>
                    </h4>
                    <span class="notif-time"><%=n.get("createdAt")%></span>
                </div>
                <p class="notif-msg"><%=n.get("message")%></p>
            </div>
            <% }} %>
        </div>
    </main>
</body>
</html>
