<%@ page import="java.util.*,com.stitchtrack.model.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    LaundryOrder order   = (LaundryOrder) request.getAttribute("order");
    User         student = (User)         request.getAttribute("student");
    Boolean      canDel  = (Boolean)      request.getAttribute("canDeliver");
    String       warn    = (String)       request.getAttribute("warning");
    String flash  = (String) session.getAttribute("flash");
    String ft     = (String) session.getAttribute("flashType");
    session.removeAttribute("flash"); session.removeAttribute("flashType");
    boolean canDeliver = Boolean.TRUE.equals(canDel);
%>
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Staff QR Scanner – StitchTrack</title>
    <meta name="description" content="Scan student laundry QR code to view details and mark as delivered.">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <script src="https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js"></script>
    <style>
        :root {
            --staff-purple: #7c3aed;
            --staff-purple-light: #ede9fe;
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
        .staff-topbar .brand span { color: #a5b4fc; }
        .staff-topbar nav a { color: rgba(255,255,255,0.7); }
        .staff-topbar nav a:hover { background: rgba(255,255,255,0.15); color: #fff; }

        /* Scanner card */
        .scanner-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius-lg);
            padding: 32px;
            box-shadow: var(--shadow-md);
            margin-bottom: 28px;
        }
        .scanner-frame {
            position: relative;
            border-radius: var(--radius-md);
            overflow: hidden;
            background: #0f0f23;
            min-height: 220px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        #video {
            width: 100%; max-height: 360px;
            object-fit: cover;
            border-radius: var(--radius-md);
            display: block;
        }
        #canvas { display: none; }
        .scan-overlay {
            position: absolute;
            top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            width: 200px; height: 200px;
            border: 3px solid rgba(124,58,237,0.85);
            border-radius: 16px;
            box-shadow: 0 0 0 4000px rgba(0,0,0,0.45);
            animation: scanPulse 2s ease infinite;
            display: none;
        }
        .scan-overlay.active { display: block; }
        @keyframes scanPulse {
            0%, 100% { border-color: rgba(124,58,237,0.85); }
            50%       { border-color: #a78bfa; box-shadow: 0 0 0 4000px rgba(0,0,0,0.45), 0 0 24px rgba(124,58,237,0.6); }
        }
        .scan-line {
            position: absolute;
            width: 180px; height: 2px;
            background: linear-gradient(90deg, transparent, #a78bfa, transparent);
            top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            animation: scanLine 2s ease-in-out infinite;
            display: none;
        }
        .scan-overlay.active ~ .scan-line { display: block; }
        @keyframes scanLine {
            0%   { top: calc(50% - 90px); }
            50%  { top: calc(50% + 90px); }
            100% { top: calc(50% - 90px); }
        }
        .camera-placeholder {
            color: #6b7280;
            text-align: center;
            padding: 40px 20px;
        }
        .camera-placeholder .icon { font-size: 3rem; display: block; margin-bottom: 12px; }
        #scanStatus {
            text-align: center;
            padding: 12px;
            border-radius: var(--radius-md);
            font-weight: 600;
            font-size: 0.95rem;
            margin: 14px 0;
            min-height: 44px;
        }
        .divider {
            display: flex;
            align-items: center;
            gap: 16px;
            margin: 28px 0;
            color: var(--muted);
            font-size: 0.85rem;
            font-weight: 700;
            letter-spacing: 0.08em;
            text-transform: uppercase;
        }
        .divider::before, .divider::after {
            content: ''; flex: 1; height: 1px; background: var(--line);
        }
        .btn-camera {
            background: linear-gradient(135deg, #7c3aed, #8b5cf6);
            color: white;
            border: none;
            border-radius: var(--radius-md);
            padding: 14px 24px;
            font-weight: 700;
            font-size: 1rem;
            cursor: pointer;
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            transition: var(--transition);
            box-shadow: 0 4px 14px rgba(124,58,237,0.35);
        }
        .btn-camera:hover { transform: translateY(-2px); box-shadow: 0 6px 22px rgba(124,58,237,0.45); }
        .btn-stop {
            background: #fee2e2; color: #b91c1c;
            border: none; border-radius: var(--radius-md);
            padding: 14px 24px; font-weight: 700; font-size: 1rem;
            cursor: pointer; width: 100%; display: none; margin-top: 10px;
            transition: var(--transition);
        }
        .btn-stop:hover { background: #fecaca; }

        /* ======= Result Panel ======= */
        .result-panel {
            background: var(--surface);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-lg);
            overflow: hidden;
            animation: slideIn 0.4s cubic-bezier(0.16, 1, 0.3, 1);
        }
        @keyframes slideIn {
            from { opacity: 0; transform: translateY(24px); }
            to   { opacity: 1; transform: translateY(0); }
        }

        /* Top colored banner */
        .result-banner {
            padding: 24px 32px;
            display: flex;
            align-items: center;
            gap: 20px;
        }
        .result-banner.ready    { background: linear-gradient(135deg, #065f46, #059669); }
        .result-banner.not-ready{ background: linear-gradient(135deg, #92400e, #d97706); }
        .result-banner.delivered{ background: linear-gradient(135deg, #1e40af, #3b82f6); }
        .result-banner-icon { font-size: 2.5rem; }
        .result-banner-text h3 { margin: 0 0 4px; color: #fff; font-size: 1.3rem; }
        .result-banner-text p  { margin: 0; color: rgba(255,255,255,0.8); font-size: 0.9rem; }

        /* Student profile card */
        .student-profile {
            display: grid;
            grid-template-columns: auto 1fr;
            gap: 24px;
            align-items: start;
            padding: 28px 32px 0;
            border-bottom: 1px solid var(--line);
            padding-bottom: 24px;
        }
        .student-avatar {
            width: 72px; height: 72px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--staff-purple-light), #ddd6fe);
            display: flex; align-items: center; justify-content: center;
            font-size: 1.8rem;
            font-weight: 800;
            color: var(--staff-purple);
            border: 3px solid var(--staff-purple-light);
            flex-shrink: 0;
        }
        .student-info h4 { margin: 0 0 4px; font-size: 1.35rem; color: var(--ink); }
        .student-info .roll { color: var(--muted); font-size: 0.9rem; font-weight: 600; margin-bottom: 12px; }
        .student-meta-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
            gap: 10px;
        }
        .meta-item {
            background: #f8fafc;
            border: 1px solid var(--line);
            border-radius: var(--radius-sm);
            padding: 10px 14px;
        }
        .meta-item .label { font-size: 0.73rem; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 4px; }
        .meta-item .value { font-size: 0.9rem; font-weight: 600; color: var(--ink); }

        /* Order detail */
        .order-detail {
            padding: 24px 32px;
            border-bottom: 1px solid var(--line);
        }
        .order-detail h4 {
            margin: 0 0 16px;
            font-size: 1rem;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: 0.08em;
            font-size: 0.78rem;
            font-weight: 800;
        }
        .order-summary-row {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            margin-bottom: 16px;
        }
        .order-field {
            display: flex;
            flex-direction: column;
            gap: 3px;
        }
        .order-field .label { font-size: 0.75rem; color: var(--muted); font-weight: 600; }
        .order-field .val   { font-size: 0.95rem; font-weight: 700; color: var(--ink); font-family: monospace; }

        /* Clothes breakdown */
        .clothes-section {
            padding: 20px 32px;
            border-bottom: 1px solid var(--line);
        }
        .clothes-section h4 { margin: 0 0 14px; font-size: 0.78rem; font-weight: 800; color: var(--muted); text-transform: uppercase; letter-spacing: 0.08em; }
        .clothes-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
            gap: 12px;
        }
        .clothes-item {
            background: var(--staff-purple-light);
            border-radius: var(--radius-md);
            padding: 14px 16px;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 6px;
            text-align: center;
            border: 1px solid #ddd6fe;
            transition: var(--transition);
        }
        .clothes-item:hover { transform: translateY(-2px); box-shadow: var(--shadow-sm); }
        .clothes-item .count {
            font-size: 1.75rem;
            font-weight: 800;
            color: var(--staff-purple);
            line-height: 1;
        }
        .clothes-item .type {
            font-size: 0.82rem;
            font-weight: 600;
            color: #5b21b6;
        }
        .clothes-item .icon { font-size: 1.4rem; }
        .total-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: var(--ink);
            color: #fff;
            border-radius: 999px;
            padding: 8px 20px;
            font-weight: 700;
            font-size: 0.9rem;
            margin-top: 14px;
        }

        /* Deliver button */
        .deliver-section {
            padding: 24px 32px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            flex-wrap: wrap;
            background: #f8fafc;
        }
        .btn-deliver {
            background: linear-gradient(135deg, #059669, #10b981);
            color: white;
            border: none;
            border-radius: var(--radius-md);
            padding: 16px 40px;
            font-size: 1.1rem;
            font-weight: 800;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 12px;
            box-shadow: 0 6px 20px rgba(16,185,129,0.35);
            transition: var(--transition);
            letter-spacing: 0.02em;
        }
        .btn-deliver:hover { transform: translateY(-3px); box-shadow: 0 10px 28px rgba(16,185,129,0.45); }
        .btn-deliver:active { transform: translateY(0); }
        .deliver-info { font-size: 0.85rem; color: var(--muted); font-weight: 500; max-width: 280px; }
        .deliver-info strong { color: var(--ok); }

        /* already delivered / not ready state */
        .status-notice {
            padding: 20px 32px;
            display: flex;
            align-items: center;
            gap: 16px;
            background: #fef3c7;
            color: #92400e;
            border-top: 1px solid #fde68a;
        }
        .status-notice.info { background: #eff6ff; color: #1e40af; border-top-color: #bfdbfe; }
        .status-notice .icon { font-size: 1.5rem; flex-shrink: 0; }
        .status-notice p { margin: 0; font-weight: 600; font-size: 0.95rem; }

        @media (max-width: 600px) {
            .student-profile { grid-template-columns: 1fr; }
            .student-avatar { width: 56px; height: 56px; font-size: 1.4rem; }
            .result-banner { flex-direction: column; }
            .deliver-section { flex-direction: column; align-items: stretch; }
            .btn-deliver { justify-content: center; }
        }
    </style>
</head>
<body>
<header class="topbar staff-topbar">
    <div class="brand compact">
        <h1>StitchTrack</h1>
        <span>Staff QR Scanner</span>
    </div>
    <nav>
        <a href="${pageContext.request.contextPath}/staff/dashboard">← Dashboard</a>
        <a href="${pageContext.request.contextPath}/logout">Logout</a>
    </nav>
</header>

<main class="container narrow">
    <section class="hero" style="margin-bottom:28px;">
        <div>
            <p class="eyebrow">LAUNDRY STAFF — QR SCANNER</p>
            <h2>Scan &amp; Deliver</h2>
            <p>Scan the student's laundry QR to view full details, then mark as delivered.</p>
        </div>
    </section>

    <% if (flash  != null) { %><div class="alert <%= ft  %>"><%= flash  %></div><% } %>
    <% if (request.getAttribute("error") != null) { %>
    <div class="alert error">&#10005; <%= request.getAttribute("error") %></div>
    <% } %>

    <!-- ===== SCANNER CARD ===== -->
    <div class="scanner-card">
        <div class="scanner-frame" id="scannerFrame">
            <video id="video" playsinline muted autoplay></video>
            <div class="scan-overlay" id="scanOverlay"></div>
            <div class="scan-line" id="scanLine"></div>
            <div class="camera-placeholder" id="camPlaceholder">
                <span class="icon">📷</span>
                <p>Camera not started</p>
                <small>Click the button below to activate your camera</small>
            </div>
        </div>
        <canvas id="canvas"></canvas>
        <div id="scanStatus"></div>
        <button type="button" class="btn-camera" id="startBtn" onclick="startScanner()">
            📷 Start Camera Scanner
        </button>
        <button type="button" class="btn-stop" id="stopBtn" onclick="stopScanner()">
            ⏹ Stop Camera
        </button>

        <div class="divider">or enter token manually</div>

        <form method="post" id="scanForm" class="stack" style="gap:14px;">
            <label for="tokenInput">QR Token
                <input id="tokenInput" name="token" required
                       placeholder="STITCH-XXXXXXXXXXXX"
                       style="font-family:monospace;font-size:1.05rem;letter-spacing:0.04em;">
            </label>
            <button class="primary" style="padding:14px;font-size:1rem;">
                🔍 Lookup Order Details
            </button>
        </form>
    </div>

    <!-- ===== RESULT PANEL ===== -->
    <% if (order != null && student != null) { %>
    <%
        String bannerCls, bannerTitle, bannerDesc, bannerIcon;
        if (canDeliver) {
            bannerCls   = "ready";
            bannerIcon  = "✅";
            bannerTitle = "Ready for Delivery";
            bannerDesc  = "This order is ready. Review details below and click DELIVERED.";
        } else if ("Delivered".equals(order.getStatus())) {
            bannerCls   = "delivered";
            bannerIcon  = "📦";
            bannerTitle = "Already Delivered";
            bannerDesc  = "This order was already marked as delivered.";
        } else {
            bannerCls   = "not-ready";
            bannerIcon  = "⚠️";
            bannerTitle = "Not Ready Yet";
            bannerDesc  = "This order cannot be delivered yet.";
        }
        String initial = student.getName() != null && !student.getName().isEmpty()
            ? String.valueOf(student.getName().charAt(0)).toUpperCase() : "?";
        int quotaPct = student.getMembershipLimit() > 0
            ? (int)((double)student.getMembershipUsed() / student.getMembershipLimit() * 100)
            : 0;
    %>
    <div class="result-panel">
        <!-- Banner -->
        <div class="result-banner <%= bannerCls %>">
            <span class="result-banner-icon"><%= bannerIcon %></span>
            <div class="result-banner-text">
                <h3><%= bannerTitle %></h3>
                <p><%= bannerDesc %></p>
            </div>
        </div>

        <!-- Student Profile -->
        <div class="student-profile">
            <div class="student-avatar"><%= initial %></div>
            <div class="student-info">
                <h4><%= student.getName() %></h4>
                <div class="roll">
                    🎓 <%= student.getRollNumber() != null ? student.getRollNumber() : "—" %>
                    &nbsp;&nbsp;|&nbsp;&nbsp;
                    📧 <%= student.getEmail() %>
                </div>
                <div class="student-meta-grid">
                    <div class="meta-item">
                        <div class="label">🏠 Hostel</div>
                        <div class="value"><%= student.getHostel() != null ? student.getHostel() : "—" %></div>
                    </div>
                    <div class="meta-item">
                        <div class="label">🚪 Room No.</div>
                        <div class="value"><%= student.getRoomNo() != null ? student.getRoomNo() : "—" %></div>
                    </div>
                    <div class="meta-item">
                        <div class="label">📱 Phone</div>
                        <div class="value"><%= student.getPhone() != null ? student.getPhone() : "—" %></div>
                    </div>
                    <div class="meta-item">
                        <div class="label">🏷️ Quota</div>
                        <div class="value"><%= student.getMembershipUsed() %> / <%= student.getMembershipLimit() %></div>
                    </div>
                    <div class="meta-item">
                        <div class="label">⚧ Gender</div>
                        <div class="value"><%= student.getGender() != null ? student.getGender() : "—" %></div>
                    </div>
                    <div class="meta-item">
                        <div class="label">✅ Account</div>
                        <div class="value"><%= student.getAccountStatus() %></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Order Detail -->
        <div class="order-detail">
            <h4>📋 Order Information</h4>
            <div class="order-summary-row">
                <div class="order-field">
                    <span class="label">Order Number</span>
                    <span class="val"><%= order.getOrderNumber() %></span>
                </div>
                <div class="order-field">
                    <span class="label">Bag Number</span>
                    <span class="val"><%= order.getBagNumber() != null ? order.getBagNumber() : "—" %></span>
                </div>
                <div class="order-field">
                    <span class="label">Status</span>
                    <span class="val" style="font-family:inherit;"><%= order.getCurrentStage() %></span>
                </div>
                <div class="order-field">
                    <span class="label">QR Token</span>
                    <span class="val" style="font-size:0.75rem;word-break:break-all;"><%= order.getQrToken() %></span>
                </div>
                <div class="order-field">
                    <span class="label">Submitted</span>
                    <span class="val" style="font-family:inherit;font-size:0.82rem;"><%= order.getCreatedAt() %></span>
                </div>
                <% if (order.getDeliveredAt() != null) { %>
                <div class="order-field">
                    <span class="label">Delivered At</span>
                    <span class="val" style="font-family:inherit;font-size:0.82rem;color:var(--ok);"><%= order.getDeliveredAt() %></span>
                </div>
                <% } %>
            </div>
        </div>

        <!-- Clothes Breakdown -->
        <div class="clothes-section">
            <h4>🧺 Clothes Breakdown</h4>
            <div class="clothes-grid">
                <% for (Map.Entry<String, Integer> item : order.getItems().entrySet()) { 
                    String cat = item.getKey();
                    String icon = cat.toLowerCase().contains("shirt")  ? "👕" :
                                  cat.toLowerCase().contains("pant")   ? "👖" :
                                  cat.toLowerCase().contains("trouser")? "👖" :
                                  cat.toLowerCase().contains("sock")   ? "🧦" :
                                  cat.toLowerCase().contains("underwear") || cat.toLowerCase().contains("inner") ? "🩲" :
                                  cat.toLowerCase().contains("jacket") || cat.toLowerCase().contains("coat")   ? "🧥" :
                                  cat.toLowerCase().contains("kurta")  || cat.toLowerCase().contains("salwar") ? "👗" :
                                  cat.toLowerCase().contains("towel")  ? "🛁" :
                                  cat.toLowerCase().contains("bed")    || cat.toLowerCase().contains("sheet")  ? "🛏️" :
                                  "🧺";
                %>
                <div class="clothes-item">
                    <span class="icon"><%= icon %></span>
                    <span class="count"><%= item.getValue() %></span>
                    <span class="type"><%= cat %></span>
                </div>
                <% } %>
            </div>
            <div>
                <span class="total-badge">🧺 Total: <%= order.getTotalItems() %> items</span>
            </div>
        </div>

        <!-- Deliver / Status Notice -->
        <% if (canDeliver) { %>
        <div class="deliver-section">
            <div class="deliver-info">
                Confirm that you are handing over <strong><%= order.getTotalItems() %> items</strong>
                to <strong style="color:var(--ink);"><%= student.getName() %></strong> in person.
                This action cannot be undone.
            </div>
            <form method="post" action="${pageContext.request.contextPath}/staff/action"
                  onsubmit="return confirm('Are you sure you want to mark this order as DELIVERED? This cannot be undone.');">
                <input type="hidden" name="action" value="deliver">
                <input type="hidden" name="token" value="<%= order.getQrToken() %>">
                <button type="submit" class="btn-deliver">
                    ✅ Mark as DELIVERED
                </button>
            </form>
        </div>
        <% } else if (warn != null) { %>
        <div class="status-notice <%= "Delivered".equals(order.getStatus()) ? "info" : "" %>">
            <span class="icon"><%= "Delivered".equals(order.getStatus()) ? "📦" : "⚠️" %></span>
            <p><%= warn %></p>
        </div>
        <% } %>
    </div>
    <% } %>

    <!-- Try another scan link if result shown -->
    <% if (order != null) { %>
    <div style="text-align:center;margin-top:24px;">
        <a href="${pageContext.request.contextPath}/staff/scanner"
           class="button secondary" style="padding:12px 28px;font-weight:700;">
            🔄 Scan Another QR
        </a>
    </div>
    <% } %>

</main>

<script>
    let stream, scanInterval;

    async function startScanner() {
        const status = document.getElementById('scanStatus');
        const startBtn = document.getElementById('startBtn');
        const stopBtn = document.getElementById('stopBtn');
        const overlay = document.getElementById('scanOverlay');
        const scanLine = document.getElementById('scanLine');
        const placeholder = document.getElementById('camPlaceholder');
        const video = document.getElementById('video');

        status.textContent = '🔄 Requesting camera access...';
        status.style.color = 'var(--muted)';

        try {
            stream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } }
            });
            video.srcObject = stream;
            await video.play();

            placeholder.style.display = 'none';
            overlay.classList.add('active');
            startBtn.style.display = 'none';
            stopBtn.style.display = 'block';
            status.textContent = '🔍 Scanning for QR code — point camera at the bag QR...';
            status.style.color = '#7c3aed';
            status.style.background = '#ede9fe';

            const canvas = document.getElementById('canvas');
            const ctx = canvas.getContext('2d');

            scanInterval = setInterval(() => {
                if (video.readyState === video.HAVE_ENOUGH_DATA) {
                    canvas.width = video.videoWidth;
                    canvas.height = video.videoHeight;
                    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
                    const code = jsQR(imageData.data, imageData.width, imageData.height, { inversionAttempts: 'dontInvert' });
                    if (code) {
                        document.getElementById('tokenInput').value = code.data;
                        status.textContent = '✅ QR Detected! Looking up order...';
                        status.style.color = '#065f46';
                        status.style.background = '#d1fae5';
                        stopScanner();
                        setTimeout(() => document.getElementById('scanForm').submit(), 500);
                    }
                }
            }, 300);

        } catch (err) {
            status.textContent = '❌ Camera error: ' + err.message + '. Use manual input below.';
            status.style.color = 'var(--danger)';
            status.style.background = 'var(--danger-bg)';
        }
    }

    function stopScanner() {
        if (stream) { stream.getTracks().forEach(t => t.stop()); stream = null; }
        if (scanInterval) { clearInterval(scanInterval); scanInterval = null; }
        document.getElementById('startBtn').style.display = 'block';
        document.getElementById('stopBtn').style.display = 'none';
        document.getElementById('scanOverlay').classList.remove('active');
        document.getElementById('video').srcObject = null;
        document.getElementById('camPlaceholder').style.display = 'block';
    }
</script>
</body>
</html>
