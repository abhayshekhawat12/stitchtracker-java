<%@ page import="java.util.*,com.stitchtrack.model.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    List<LaundryOrder> orders = (List<LaundryOrder>) request.getAttribute("orders");
    if (orders == null) orders = Collections.emptyList();
    String flash  = (String) session.getAttribute("flash");
    String ft     = (String) session.getAttribute("flashType");
    session.removeAttribute("flash"); session.removeAttribute("flashType");
    String tab = request.getParameter("tab");
    if (tab == null) tab = "pending";
    long pendingCount  = orders.stream().filter(o -> "Pending Approval".equals(o.getStatus())).count();
    long activeCount   = orders.stream().filter(o -> !Set.of("Pending Approval","Delivered","Rejected","Cancelled").contains(o.getStatus())).count();
    long deliveredCount= orders.stream().filter(o -> "Delivered".equals(o.getStatus())).count();
    com.stitchtrack.model.User staffUser = (com.stitchtrack.model.User) session.getAttribute("user");
%>
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Laundry Staff Panel – StitchTrack</title>
    <meta name="description" content="Laundry staff panel to accept, track and deliver student laundry requests.">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <style>
        :root {
            --staff-purple: #7c3aed;
            --staff-purple-light: #ede9fe;
            --staff-teal: #0d9488;
            --staff-teal-light: #ccfbf1;
            --staff-amber: #d97706;
            --staff-amber-light: #fef3c7;
        }

        .staff-topbar {
            background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%);
            border-bottom: none;
            box-shadow: 0 4px 20px rgba(67,56,202,0.4);
        }
        .staff-topbar .brand h1 {
            background: linear-gradient(to right, #a5b4fc, #c4b5fd);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .staff-topbar .brand span {
            color: #a5b4fc;
        }
        .staff-topbar nav a {
            color: rgba(255,255,255,0.7);
        }
        .staff-topbar nav a:hover {
            background: rgba(255,255,255,0.15);
            color: #fff;
        }
        .staff-topbar nav a.active {
            background: rgba(255,255,255,0.2);
            color: #fff;
        }
        .staff-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(255,255,255,0.15);
            color: #c4b5fd;
            border: 1px solid rgba(255,255,255,0.2);
            border-radius: 999px;
            padding: 4px 12px;
            font-size: 0.75rem;
            font-weight: 700;
            letter-spacing: 0.08em;
        }



        /* Stat cards */
        .stat-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 18px;
            margin-bottom: 36px;
        }
        .stat-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius-md);
            padding: 22px 24px;
            box-shadow: var(--shadow-sm);
            transition: var(--transition);
            position: relative;
            overflow: hidden;
        }
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: var(--shadow-md);
        }
        .stat-card::before {
            content: '';
            position: absolute;
            top: 0; left: 0;
            width: 4px;
            height: 100%;
            border-radius: 4px 0 0 4px;
        }
        .stat-card.pending::before { background: var(--staff-amber); }
        .stat-card.active::before  { background: var(--blue); }
        .stat-card.done::before    { background: var(--ok); }
        .stat-card span { display: block; font-size: 0.85rem; color: var(--muted); font-weight: 600; margin-bottom: 8px; }
        .stat-card strong { font-size: 2.2rem; font-weight: 800; color: var(--ink); }
        .stat-card.pending strong { color: var(--staff-amber); }
        .stat-card.active  strong { color: var(--blue); }
        .stat-card.done    strong { color: var(--ok); }

        /* Tab nav */
        .tab-nav {
            display: flex;
            gap: 4px;
            border-bottom: 2px solid var(--line);
            margin-bottom: 28px;
        }
        .tab-nav a {
            padding: 12px 20px;
            border-radius: var(--radius-sm) var(--radius-sm) 0 0;
            font-weight: 600;
            font-size: 0.9rem;
            color: var(--muted);
            text-decoration: none;
            transition: var(--transition);
            border-bottom: 2px solid transparent;
            margin-bottom: -2px;
        }
        .tab-nav a:hover { color: var(--ink); background: #f1f5f9; }
        .tab-nav a.active {
            color: var(--blue);
            border-bottom-color: var(--blue);
            background: #eff6ff;
        }

        /* Order rows — pending section */
        .request-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius-md);
            padding: 20px 24px;
            display: flex;
            align-items: flex-start;
            gap: 20px;
            margin-bottom: 14px;
            box-shadow: var(--shadow-sm);
            transition: var(--transition);
        }
        .request-card:hover {
            box-shadow: var(--shadow-md);
            border-color: #cbd5e1;
        }
        .request-card .rc-info { flex: 1; min-width: 0; }
        .rc-order { font-weight: 700; font-size: 0.95rem; color: var(--ink); font-family: monospace; }
        .rc-student { font-size: 1rem; font-weight: 600; margin: 4px 0; }
        .rc-student span { color: var(--muted); font-weight: 400; font-size: 0.85rem; margin-left: 6px; }
        .rc-meta { display: flex; gap: 16px; flex-wrap: wrap; margin-top: 8px; font-size: 0.82rem; color: var(--muted); }
        .rc-meta strong { color: var(--ink); }
        .clothes-chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 10px; }
        .clothes-chip {
            background: var(--staff-purple-light);
            color: var(--staff-purple);
            border-radius: 999px;
            padding: 4px 12px;
            font-size: 0.78rem;
            font-weight: 600;
        }
        .accept-form { display: flex; gap: 10px; align-items: center; flex-shrink: 0; flex-wrap: wrap; }
        .accept-form input[type=text] {
            width: 120px;
            padding: 10px 14px;
            font-size: 0.9rem;
        }
        .btn-accept {
            background: linear-gradient(135deg, #059669, #10b981);
            color: white;
            border: none;
            border-radius: var(--radius-md);
            padding: 10px 20px;
            font-weight: 700;
            font-size: 0.9rem;
            cursor: pointer;
            white-space: nowrap;
            transition: var(--transition);
            box-shadow: 0 4px 12px rgba(16,185,129,0.3);
        }
        .btn-accept:hover { transform: translateY(-2px); box-shadow: 0 6px 18px rgba(16,185,129,0.35); }

        /* Active pipeline table */
        .pill-received  { background: #e0f2fe; color: #0369a1; }
        .pill-sorting   { background: #fef3c7; color: #92400e; }
        .pill-washing   { background: #ede9fe; color: #6d28d9; }
        .pill-drying    { background: #fce7f3; color: #9d174d; }
        .pill-ironing   { background: #ecfdf5; color: #065f46; }
        .pill-ready     { background: #d1fae5; color: #065f46; }
        .pill-delivered { background: #f0fdf4; color: #15803d; }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--muted);
        }
        .empty-state .icon { font-size: 3rem; display: block; margin-bottom: 12px; }
        .empty-state p { font-size: 1.05rem; font-weight: 500; }

        .scanner-btn-wrap {
            display: flex;
            justify-content: flex-end;
            margin-bottom: 24px;
        }
        .btn-scanner {
            background: linear-gradient(135deg, #7c3aed, #8b5cf6);
            color: white;
            border: none;
            border-radius: var(--radius-md);
            padding: 12px 28px;
            font-weight: 700;
            font-size: 0.95rem;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 10px;
            text-decoration: none;
            box-shadow: 0 4px 14px rgba(124,58,237,0.35);
            transition: var(--transition);
        }
        .btn-scanner:hover { transform: translateY(-2px); box-shadow: 0 6px 22px rgba(124,58,237,0.4); color: white; text-decoration: none; }
    </style>
</head>
<body>
<header class="topbar staff-topbar">
    <div class="brand compact">
        <h1>StitchTrack</h1>
        <span>Laundry Staff Panel &nbsp;<span class="staff-badge">🧺 STAFF</span></span>
    </div>
    <nav>
        <a href="?tab=pending"   class="<%= "pending".equals(tab)   ? "active" : "" %>">📥 Pending</a>
        <a href="?tab=pipeline"  class="<%= "pipeline".equals(tab)  ? "active" : "" %>">⚙️ Pipeline</a>
        <a href="?tab=delivered" class="<%= "delivered".equals(tab) ? "active" : "" %>">✅ Delivered</a>
        <a href="${pageContext.request.contextPath}/staff/scanner" style="background:rgba(255,255,255,0.15);color:#fff;">📷 QR Scanner</a>
        <a href="${pageContext.request.contextPath}/logout">Logout</a>
    </nav>
</header>

<main class="container">

    <% if (flash != null) { %>
    <div class="alert <%= ft %>"><%= flash %></div>
    <% } %>

    <!-- Hero -->
    <section class="hero">
        <div>
            <p class="eyebrow">LAUNDRY STAFF PANEL</p>
            <h2>Welcome, <%= staffUser != null ? staffUser.getName() : "Staff" %> 👋</h2>
            <p>Manage student laundry requests — accept, track, scan &amp; deliver.</p>
        </div>
        <a href="${pageContext.request.contextPath}/staff/scanner" class="btn-scanner">
            📷 Open QR Scanner
        </a>
    </section>

    <!-- Stat cards -->
    <div class="stat-cards">
        <div class="stat-card pending">
            <span>⏳ Pending Approval</span>
            <strong><%= pendingCount %></strong>
        </div>
        <div class="stat-card active">
            <span>⚙️ Active Pipeline</span>
            <strong><%= activeCount %></strong>
        </div>
        <div class="stat-card done">
            <span>✅ Delivered Today</span>
            <strong><%= deliveredCount %></strong>
        </div>
    </div>

    <!-- Tab nav -->
    <div class="tab-nav">
        <a href="?tab=pending"   class="<%= "pending".equals(tab)   ? "active" : "" %>">Pending Requests <% if(pendingCount>0){%><span class="pill" style="font-size:0.7rem;margin-left:4px;"><%= pendingCount %></span><%}%></a>
        <a href="?tab=pipeline"  class="<%= "pipeline".equals(tab)  ? "active" : "" %>">Active Pipeline <% if(activeCount>0){%><span class="pill" style="font-size:0.7rem;margin-left:4px;"><%= activeCount %></span><%}%></a>
        <a href="?tab=delivered" class="<%= "delivered".equals(tab) ? "active" : "" %>">Delivered</a>
    </div>

    <!-- ====== PENDING TAB ====== -->
    <% if ("pending".equals(tab)) { %>
    <div class="section-head">
        <h3>📥 Pending Student Requests</h3>
        <small class="muted">Accept request &amp; assign a bag number to generate QR</small>
    </div>

    <%
        boolean anyPending = false;
        for (LaundryOrder o : orders) {
            if (!"Pending Approval".equals(o.getStatus())) continue;
            anyPending = true;
    %>
    <div class="request-card">
        <div class="rc-info">
            <div class="rc-order">#<%= o.getOrderNumber() %></div>
            <div class="rc-student">
                <%= o.getStudentName() %>
                <span><%= o.getStudentRoll() %></span>
            </div>
            <div class="rc-meta">
                <div>📅 Submitted: <strong><%= o.getCreatedAt() %></strong></div>
                <div>🧺 Total Items: <strong><%= o.getTotalItems() %></strong></div>
            </div>
            <div class="clothes-chips">
                <% for (Map.Entry<String,Integer> item : o.getItems().entrySet()) { %>
                <span class="clothes-chip"><%= item.getValue() %> × <%= item.getKey() %></span>
                <% } %>
            </div>
        </div>
        <form method="post" action="${pageContext.request.contextPath}/staff/action" class="accept-form">
            <input type="hidden" name="action" value="accept">
            <input type="hidden" name="orderId" value="<%= o.getId() %>">
            <input type="number" name="bag" required min="1" placeholder="905"
                   title="Enter bag number (e.g. 1)" style="font-family:monospace;">
            <button type="submit" class="btn-accept">✔ Accept &amp; Generate QR</button>
        </form>
    </div>
    <% } %>

    <% if (!anyPending) { %>
    <div class="empty-state">
        <span class="icon">🎉</span>
        <p>No pending requests right now. All caught up!</p>
    </div>
    <% } %>
    <% } %>

    <!-- ====== PIPELINE TAB ====== -->
    <% if ("pipeline".equals(tab)) { %>
    <div class="section-head" style="display:flex; justify-content:space-between; align-items:center;">
        <div>
            <h3>⚙️ Active Pipeline</h3>
            <small class="muted">Orders currently being processed</small>
        </div>
        <input type="text" id="bagSearch" placeholder="🔍 Search Bag (e.g. 1)..." style="padding:8px 12px; border:1px solid var(--line); border-radius:var(--radius-sm); font-size:0.9rem; width:220px;">
    </div>
    <div class="table-wrap">
        <table id="pipelineTable">
            <thead>
                <tr>
                    <th>Order / Bag</th>
                    <th>Student</th>
                    <th>Items Breakdown</th>
                    <th>Total</th>
                    <th>Stage</th>
                    <th>Since</th>
                </tr>
            </thead>
            <tbody>
            <%
                boolean anyActive = false;
                for (LaundryOrder o : orders) {
                    if (Set.of("Pending Approval","Delivered","Rejected","Cancelled").contains(o.getStatus())) continue;
                    anyActive = true;
            %>
            <tr class="pipeline-row">
                <td>
                    <strong style="font-family:monospace;font-size:0.85rem;"><%= o.getOrderNumber() %></strong>
                    <% if (o.getBagNumber() != null) { %>
                    <br><small class="bag-number">🏷️ Bag: <%= o.getBagNumber() %></small>
                    <% } %>
                </td>
                <td>
                    <strong><%= o.getStudentName() %></strong>
                    <br><small><%= o.getStudentRoll() %></small>
                </td>
                <td>
                    <div class="clothes-chips" style="padding-top:0;">
                        <% for (Map.Entry<String,Integer> item : o.getItems().entrySet()) { %>
                        <span class="clothes-chip"><%= item.getValue() %> × <%= item.getKey() %></span>
                        <% } %>
                    </div>
                </td>
                <td><strong><%= o.getTotalItems() %></strong></td>
                <td>
                    <form method="post" action="${pageContext.request.contextPath}/staff/action" style="display:flex;gap:5px;align-items:center;">
                        <input type="hidden" name="action" value="stage">
                        <input type="hidden" name="orderId" value="<%= o.getId() %>">
                        <select name="stage" style="padding:4px;font-size:0.8rem;border:1px solid #ccc;border-radius:4px;">
                            <option <%= "Received".equals(o.getCurrentStage()) ? "selected" : "" %>>Received</option>
                            <option <%= "Sorting".equals(o.getCurrentStage()) ? "selected" : "" %>>Sorting</option>
                            <option <%= "Washing".equals(o.getCurrentStage()) ? "selected" : "" %>>Washing</option>
                            <option <%= "Drying".equals(o.getCurrentStage()) ? "selected" : "" %>>Drying</option>
                            <option <%= "Ironing".equals(o.getCurrentStage()) ? "selected" : "" %>>Ironing</option>
                            <option <%= "Ready for Pickup".equals(o.getCurrentStage()) ? "selected" : "" %>>Ready for Pickup</option>
                        </select>
                        <button type="submit" style="padding:4px 8px;font-size:0.8rem;background:var(--staff-purple);color:white;border:none;border-radius:4px;cursor:pointer;">Update</button>
                        <% if("Ready for Pickup".equals(o.getCurrentStage())) { %>
                            <button type="button" onclick="waReady('<%= o.getStudentPhone() %>', '<%= o.getOrderNumber() %>', '<%= o.getStudentName() %>')" style="padding:4px 8px;font-size:0.8rem;background:#25D366;color:white;border:none;border-radius:4px;cursor:pointer;">📲 WA</button>
                        <% } %>
                    </form>
                </td>
                <td style="font-size:0.8rem;color:var(--muted);"><%= o.getCreatedAt() %></td>
            </tr>
            <% } %>
            <% if (!anyActive) { %>
            <tr><td colspan="6" style="text-align:center;padding:40px;color:var(--muted);">No active orders in pipeline.</td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
    
    <script>
        document.getElementById('bagSearch')?.addEventListener('input', function(e) {
            const query = e.target.value.toLowerCase();
            const rows = document.querySelectorAll('#pipelineTable tbody .pipeline-row');
            rows.forEach(row => {
                const bagText = row.querySelector('.bag-number')?.textContent.toLowerCase() || '';
                if (bagText.includes(query)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });
    </script>
    <% } %>

    <!-- ====== DELIVERED TAB ====== -->
    <% if ("delivered".equals(tab)) { %>
    <div class="section-head">
        <h3>✅ Delivered Orders</h3>
        <small class="muted">Successfully delivered laundry history</small>
    </div>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Order</th>
                    <th>Student</th>
                    <th>Bag</th>
                    <th>Items</th>
                    <th>Submitted</th>
                    <th>Delivered At</th>
                </tr>
            </thead>
            <tbody>
            <%
                boolean anyDelivered = false;
                for (LaundryOrder o : orders) {
                    if (!"Delivered".equals(o.getStatus())) continue;
                    anyDelivered = true;
            %>
            <tr>
                <td style="font-family:monospace;font-size:0.85rem;"><%= o.getOrderNumber() %></td>
                <td><strong><%= o.getStudentName() %></strong><small><%= o.getStudentRoll() %></small></td>
                <td><%= o.getBagNumber() != null ? o.getBagNumber() : "—" %></td>
                <td>
                    <div class="clothes-chips" style="padding-top:0;">
                    <% for (Map.Entry<String,Integer> item : o.getItems().entrySet()) { %>
                    <span class="clothes-chip"><%= item.getValue() %> × <%= item.getKey() %></span>
                    <% } %>
                    </div>
                </td>
                <td style="font-size:0.8rem;"><%= o.getCreatedAt() %></td>
                <td style="font-size:0.8rem;color:var(--ok);font-weight:600;"><%= o.getDeliveredAt() %></td>
                <td>
                    <button type="button" onclick="waInvoice('<%= o.getStudentPhone() %>', '<%= o.getOrderNumber() %>', '<%= o.getStudentName() %>', <%= o.getTotalItems() %>)" style="padding:4px 8px;font-size:0.8rem;background:#25D366;color:white;border:none;border-radius:4px;cursor:pointer;">📲 Invoice</button>
                </td>
            </tr>
            <% } %>
            <% if (!anyDelivered) { %>
            <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--muted);">No deliveries yet.</td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
    <% } %>

</main>

<script>
function waReady(phone, orderId, name) {
    if(!phone || phone === 'null') { alert("No phone number registered for this student!"); return; }
    let msg = `Hello \${name},\nYour laundry order *#\${orderId}* is now *Ready for Pickup*!\nPlease collect it from the facility.`;
    window.open(`https://wa.me/91\${phone}?text=\${encodeURIComponent(msg)}`, '_blank');
}
function waInvoice(phone, orderId, name, items) {
    if(!phone || phone === 'null') { alert("No phone number registered for this student!"); return; }
    let msg = `Hello \${name},\nYour laundry order *#\${orderId}* containing *\${items} items* has been successfully delivered.\nThank you for using StitchTrack!`;
    window.open(`https://wa.me/91\${phone}?text=\${encodeURIComponent(msg)}`, '_blank');
}
</script>
</body>
</html>
