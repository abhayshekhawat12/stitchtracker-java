<%@ page import="java.util.*,com.stitchtrack.model.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    User u = (User)request.getAttribute("user");
    if(u == null) u = (User)session.getAttribute("user");
    List<SubscriptionPlan> plans = (List<SubscriptionPlan>)request.getAttribute("plans");
    List<SubscriptionTransaction> txHistory = (List<SubscriptionTransaction>)request.getAttribute("txHistory");
    String upiId = (String)request.getAttribute("upiId");
    if(upiId == null || upiId.isBlank()) upiId = "stitchtrack@upi";
    String upiName = (String)request.getAttribute("upiName");
    if(upiName == null || upiName.isBlank()) upiName = "StitchTrack Facility";

    String flash = (String)session.getAttribute("flash");
    String ft = (String)session.getAttribute("flashType");
    session.removeAttribute("flash"); session.removeAttribute("flashType");

    int totalPurchased = 0;
    if(txHistory != null) for(SubscriptionTransaction t : txHistory) {
        if("SUCCESS".equals(t.getPaymentStatus()) || "FREE".equals(t.getPaymentStatus())) totalPurchased += t.getClothesCredited();
    }
%>
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Subscription Plans & Credit Top-up - StitchTrack</title>
    <meta name="description" content="Top up your StitchTrack clothes quota using direct UPI QR payment.">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <style>
        /* ── Subscription Page Styles ── */
        body { background: linear-gradient(135deg, #f0f4ff 0%, #faf5ff 100%); min-height: 100vh; }

        .sub-hero {
            text-align: center;
            padding: 44px 24px 24px;
        }
        .sub-hero h2 { font-size: 2.1rem; font-weight: 800; color: var(--ink); margin-bottom: 8px; }
        .sub-hero p { color: var(--muted); font-size: 1.05rem; }

        /* Quota summary bar */
        .quota-summary {
            display: flex;
            gap: 16px;
            justify-content: center;
            flex-wrap: wrap;
            margin-bottom: 24px;
        }
        .quota-pill {
            background: #fff;
            border: 1px solid var(--line);
            border-radius: 999px;
            padding: 10px 22px;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 0.95rem;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        .quota-pill .qp-icon { font-size: 1.3rem; }
        .quota-pill .qp-value { font-weight: 800; font-size: 1.2rem; color: var(--blue); }
        .quota-pill .qp-label { color: var(--muted); font-size: 0.85rem; }

        /* Plan cards grid */
        .plans-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 24px;
            max-width: 960px;
            margin: 0 auto 48px;
            padding: 0 24px;
        }

        .plan-card {
            background: #fff;
            border: 2px solid var(--line);
            border-radius: 20px;
            padding: 32px 24px;
            text-align: center;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0,0,0,0.04);
        }
        .plan-card:hover {
            border-color: var(--blue);
            transform: translateY(-6px);
            box-shadow: 0 16px 40px rgba(59,130,246,0.15);
        }
        .plan-card.featured {
            border-color: #8b5cf6;
            background: linear-gradient(145deg, #fdf4ff, #fff);
        }
        .plan-card.featured:hover {
            border-color: #7c3aed;
            box-shadow: 0 16px 40px rgba(139,92,246,0.2);
        }
        .featured-badge {
            position: absolute;
            top: 0; right: 0;
            background: linear-gradient(135deg, #8b5cf6, #6d28d9);
            color: white;
            font-size: 0.7rem;
            font-weight: 800;
            padding: 6px 16px;
            border-bottom-left-radius: 12px;
            letter-spacing: 0.05em;
        }
        .plan-icon { font-size: 2.6rem; margin-bottom: 12px; display: block; }
        .plan-name { font-size: 1.25rem; font-weight: 800; color: var(--ink); margin-bottom: 6px; }
        .plan-clothes {
            font-size: 2.8rem;
            font-weight: 900;
            background: linear-gradient(135deg, #2563eb, #8b5cf6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            line-height: 1;
            margin-bottom: 4px;
        }
        .plan-clothes-label { font-size: 0.85rem; color: var(--muted); margin-bottom: 16px; font-weight: 600; }
        .plan-price { font-size: 1.8rem; font-weight: 800; color: var(--ink); margin-bottom: 24px; }
        .plan-price span { font-size: 0.95rem; font-weight: 500; color: var(--muted); }

        .plan-btn {
            display: block;
            width: 100%;
            padding: 14px;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 700;
            cursor: pointer;
            border: none;
            transition: all 0.2s;
            text-align: center;
        }
        .plan-btn.pay-btn {
            background: linear-gradient(135deg, #2563eb, #7c3aed);
            color: white;
            box-shadow: 0 4px 14px rgba(37,99,235,0.25);
        }
        .plan-btn.pay-btn:hover {
            opacity: 0.95;
            transform: scale(1.02);
            box-shadow: 0 6px 20px rgba(37,99,235,0.35);
        }

        /* Direct UPI Info Box */
        .upi-guide-box {
            background: #ffffff;
            border: 2px solid #e2e8f0;
            border-radius: 16px;
            padding: 20px 24px;
            max-width: 960px;
            margin: 0 auto 36px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            flex-wrap: wrap;
            box-shadow: 0 4px 12px rgba(0,0,0,0.03);
        }
        .upi-guide-left { display: flex; align-items: center; gap: 14px; }
        .upi-guide-icon { font-size: 2.2rem; background: #eff6ff; padding: 10px; border-radius: 12px; }

        /* Modal Styles */
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.65);
            backdrop-filter: blur(5px);
            z-index: 1000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal-overlay.active { display: flex; }
        .modal-box {
            background: #ffffff;
            border-radius: 20px;
            width: 100%;
            max-width: 520px;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 25px 60px rgba(0,0,0,0.3);
            animation: modalPop 0.25s ease-out;
            padding: 28px;
            position: relative;
        }
        @keyframes modalPop {
            from { transform: scale(0.92); opacity: 0; }
            to { transform: scale(1); opacity: 1; }
        }
        .modal-close {
            position: absolute;
            top: 18px; right: 20px;
            font-size: 1.5rem;
            background: none;
            border: none;
            cursor: pointer;
            color: var(--muted);
            width: 36px; height: 36px;
            display: flex; align-items: center; justify-content: center;
            border-radius: 50%;
            transition: all 0.2s;
        }
        .modal-close:hover { background: #f1f5f9; color: var(--ink); }

        .qr-wrapper {
            background: #f8fafc;
            border: 2px dashed #cbd5e1;
            border-radius: 16px;
            padding: 16px;
            text-align: center;
            margin: 16px 0;
        }
        .qr-wrapper img {
            max-width: 200px;
            height: auto;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            background: #fff;
            padding: 8px;
        }

        .upi-copy-box {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: #f1f5f9;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 8px 14px;
            margin: 10px 0;
        }
        .copy-btn {
            background: #2563eb;
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 0.8rem;
            font-weight: 700;
            cursor: pointer;
        }
        .copy-btn:hover { background: #1d4ed8; }

        /* Transaction history */
        .tx-section { max-width: 960px; margin: 0 auto; padding: 0 24px 48px; }
        .tx-section h3 { font-size: 1.25rem; font-weight: 800; margin-bottom: 16px; }
        .tx-table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 14px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
        .tx-table th { background: #f8fafc; padding: 14px 16px; text-align: left; font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.05em; color: var(--muted); border-bottom: 1px solid var(--line); }
        .tx-table td { padding: 14px 16px; border-bottom: 1px solid #f1f5f9; font-size: 0.9rem; }
        .tx-table tr:last-child td { border-bottom: none; }
        .status-pill { display: inline-block; padding: 4px 10px; border-radius: 999px; font-size: 0.75rem; font-weight: 700; }
        .status-pill.SUCCESS { background: #e5f5e9; color: #0d652d; }
        .status-pill.FREE { background: #eff6ff; color: #1e40af; }
        .status-pill.PENDING_VERIFICATION, .status-pill.PENDING { background: #fef3c7; color: #92400e; }
        .status-pill.REJECTED, .status-pill.FAILED { background: #fde8e7; color: #b3261e; }
    </style>
</head>
<body>
    <header class="topbar">
        <div class="brand compact">
            <h1>StitchTrack</h1>
            <span>Student Portal</span>
        </div>
        <nav>
            <a href="${pageContext.request.contextPath}/student/dashboard">Dashboard</a>
            <a href="${pageContext.request.contextPath}/student/new-request">New Request</a>
            <a href="${pageContext.request.contextPath}/student/subscription" class="active">⚡ Subscription</a>
            <a href="${pageContext.request.contextPath}/logout">Logout</a>
        </nav>
    </header>

    <main class="container">
        <% if(flash != null) { %>
            <div class="alert <%=ft%>" style="margin-top:20px;"><%=flash%></div>
        <% } %>

        <div class="sub-hero">
            <p class="eyebrow">TOP-UP CLOTHES QUOTA</p>
            <h2>Subscription Packs</h2>
            <p>Scan the UPI QR code or pay via any UPI App, submit your UTR & proof for instant credit approval.</p>
        </div>

        <!-- Quota Summary -->
        <div class="quota-summary">
            <div class="quota-pill">
                <span class="qp-icon">👕</span>
                <div>
                    <div class="qp-value"><%=u.getMembershipLimit()%></div>
                    <div class="qp-label">Total Allocated</div>
                </div>
            </div>
            <div class="quota-pill">
                <span class="qp-icon">🧺</span>
                <div>
                    <div class="qp-value" style="color:#ef4444;"><%=u.getMembershipUsed()%></div>
                    <div class="qp-label">Clothes Used</div>
                </div>
            </div>
            <div class="quota-pill">
                <span class="qp-icon">✅</span>
                <div>
                    <div class="qp-value" style="color:#10b981;"><%=u.getCreditsLeft()%></div>
                    <div class="qp-label">Credits Remaining</div>
                </div>
            </div>
            <div class="quota-pill">
                <span class="qp-icon">💳</span>
                <div>
                    <div class="qp-value" style="color:#8b5cf6;"><%=totalPurchased%></div>
                    <div class="qp-label">Total Purchased</div>
                </div>
            </div>
        </div>

        <!-- Free Quota Status Banner -->
        <div style="max-width:960px;margin:0 auto 24px;padding:0 24px;">
            <div style="background:#ecfdf5;border:1px solid #a7f3d0;color:#065f46;border-radius:14px;padding:14px 20px;display:flex;align-items:center;gap:12px;font-size:0.95rem;box-shadow:0 2px 8px rgba(16,185,129,0.08);">
                <span style="font-size:1.5rem;">🎁</span>
                <div>
                    <strong style="color:#047857;">50 Free Starter Clothes:</strong> Automatically credited to your account on your first login! Use the packs below whenever you need to add more laundry quota.
                </div>
            </div>
        </div>

        <!-- Direct UPI Notice -->
        <div class="upi-guide-box">
            <div class="upi-guide-left">
                <span class="upi-guide-icon">📱</span>
                <div>
                    <h4 style="margin:0 0 4px 0;color:var(--ink);">Direct UPI Payment (Zero Gateway Fees)</h4>
                    <p style="margin:0;color:var(--muted);font-size:0.9rem;">
                        Click <b>"Choose Pack"</b> below &rarr; Scan QR via Google Pay / PhonePe / Paytm &rarr; Upload screenshot & UTR number.
                    </p>
                </div>
            </div>
            <div style="display:flex;align-items:center;gap:8px;">
                <span style="background:#f1f5f9;border:1px solid #cbd5e1;padding:6px 12px;border-radius:8px;font-weight:700;font-size:0.85rem;color:var(--blue);">
                    UPI: <%=upiId%>
                </span>
            </div>
        </div>

        <!-- Plan Cards (Paid Packs Only - Free Starter Excluded) -->
        <div class="plans-grid">
            <% if(plans != null) for(SubscriptionPlan p : plans) {
                if(p.isFree()) continue; // Do not show Free Starter card
                boolean isFeatured = p.getId() == 3; // Standard Pack
                String[] icons = {"🎁", "📦", "⭐", "👑"};
                String icon = (p.getId() >= 1 && p.getId() <= 4) ? icons[p.getId()-1] : "📦";
            %>
            <div class="plan-card <%=isFeatured?"featured":""%>">
                <% if(isFeatured) { %><div class="featured-badge">MOST POPULAR</div><% } %>
                <span class="plan-icon"><%=icon%></span>
                <div class="plan-name"><%=p.getPlanName()%></div>
                <div class="plan-clothes"><%=p.getClothesAdded()%></div>
                <div class="plan-clothes-label">+<%=p.getClothesAdded()%> additional clothes quota</div>
                <div class="plan-price">
                    ₹<%=p.getPriceInr()%> <span>/ one-time</span>
                </div>
                <button type="button" class="plan-btn pay-btn"
                        onclick="openUpiModal(<%=p.getId()%>, '<%=p.getPlanName()%>', <%=p.getPriceInr()%>, <%=p.getClothesAdded()%>)">
                    ⚡ Buy Pack &bull; Pay ₹<%=p.getPriceInr()%> &rarr;
                </button>
            </div>
            <% } %>
        </div>

        <!-- Transaction History -->
        <div class="tx-section">
            <h3>📋 Credit Purchase History</h3>
            <% if(txHistory == null || txHistory.isEmpty()) { %>
            <div class="empty" style="padding:32px;text-align:center;background:#fff;border-radius:12px;border:1px solid var(--line);">
                <p style="color:var(--muted);">No transactions recorded yet.</p>
            </div>
            <% } else { %>
            <div style="overflow-x:auto;">
                <table class="tx-table">
                    <thead>
                        <tr>
                            <th>Date / Ref</th>
                            <th>Pack</th>
                            <th>Clothes Added</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>UTR / Proof</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for(SubscriptionTransaction t : txHistory) { 
                            String stText = t.getPaymentStatus();
                            if("PENDING_VERIFICATION".equals(stText)) stText = "⏳ Pending Verification";
                            else if("SUCCESS".equals(stText)) stText = "✅ Approved";
                            else if("FREE".equals(stText)) stText = "🎁 Free Starter";
                            else if("REJECTED".equals(stText)) stText = "✕ Rejected";
                        %>
                        <tr>
                            <td>
                                <b><%=t.getTransactionRef()%></b><br>
                                <small style="color:var(--muted);"><%=t.getCreatedAt()%></small>
                            </td>
                            <td><b><%=t.getPlanName()%></b></td>
                            <td style="color:var(--ok);font-weight:700;">+<%=t.getClothesCredited()%></td>
                            <td><strong><%=t.getAmountInr()==0?"Free":"₹"+t.getAmountInr()%></strong></td>
                            <td><span class="status-pill <%=t.getPaymentStatus()%>"><%=stText%></span></td>
                            <td>
                                <% if(t.getUtrNumber() != null && !t.getUtrNumber().isBlank()) { %>
                                    <small>UTR: <b><%=t.getUtrNumber()%></b></small><br>
                                <% } %>
                                <% if(t.getPaymentScreenshot() != null && !t.getPaymentScreenshot().isBlank()) { 
                                    String shotUrl = t.getPaymentScreenshot().startsWith("http") ? t.getPaymentScreenshot() : request.getContextPath() + "/" + t.getPaymentScreenshot();
                                %>
                                    <a href="<%=shotUrl%>" target="_blank" style="color:var(--blue);font-size:0.8rem;text-decoration:underline;">🖼️ View Screenshot</a>
                                <% } else if("FREE".equals(t.getPaymentStatus())) { %>
                                    <small style="color:var(--muted);">Auto-assigned</small>
                                <% } else { %>
                                    <small style="color:var(--muted);">-</small>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            <% } %>
        </div>
    </main>

    <!-- UPI Payment Modal Dialog -->
    <div id="upiModal" class="modal-overlay">
        <div class="modal-box">
            <button type="button" class="modal-close" onclick="closeUpiModal()">&times;</button>
            <div style="text-align:center;margin-bottom:16px;">
                <span style="font-size:2.4rem;">📱</span>
                <h3 id="modalPlanTitle" style="margin:6px 0 2px;font-size:1.35rem;color:var(--ink);">UPI Payment</h3>
                <p id="modalPlanSub" style="margin:0;color:var(--muted);font-size:0.95rem;">Scan & Pay via any UPI app</p>
            </div>

            <!-- QR Code Section -->
            <div class="qr-wrapper">
                <p style="margin:0 0 8px 0;font-size:0.85rem;font-weight:700;color:var(--muted);">SCAN WITH ANY UPI APP</p>
                <img id="upiQrImage" src="" alt="UPI QR Code">
                <div style="font-size:0.8rem;color:var(--muted);margin-top:8px;">GPay &bull; PhonePe &bull; Paytm &bull; BHIM &bull; Cred</div>
            </div>

            <!-- UPI ID & Copy -->
            <div class="upi-copy-box">
                <div>
                    <small style="display:block;color:var(--muted);font-size:0.75rem;">FACILITY UPI ID</small>
                    <b id="upiIdText" style="color:var(--blue);"><%=upiId%></b>
                </div>
                <button type="button" class="copy-btn" id="copyBtn" onclick="copyUpiId()">📋 Copy</button>
            </div>

            <div style="background:#fef3c7;border:1px solid #fde68a;border-radius:10px;padding:10px 14px;margin-bottom:16px;font-size:0.82rem;color:#92400e;">
                ⚠️ <b>Important:</b> Pay the exact amount (<strong id="modalAmountNotice">₹0</strong>). Then enter the 12-digit UTR/Txn ID and upload the payment confirmation screenshot below.
            </div>

            <!-- Payment Submission Form -->
            <form method="post" action="${pageContext.request.contextPath}/student/subscription" enctype="multipart/form-data">
                <input type="hidden" name="action" value="manual-upi">
                <input type="hidden" name="planId" id="formPlanId" value="">

                <div style="margin-bottom:14px;">
                    <label style="display:block;font-size:0.85rem;font-weight:700;margin-bottom:6px;color:var(--ink);">
                        UPI Reference / UTR Number <span style="color:#ef4444;">*</span>
                    </label>
                    <input type="text" name="utrNumber" id="utrInput" required
                           placeholder="e.g. 428912345678 (12-digit reference number)"
                           style="width:100%;padding:10px 12px;border:1px solid var(--line);border-radius:8px;font-size:0.95rem;">
                </div>

                <div style="margin-bottom:18px;">
                    <label style="display:block;font-size:0.85rem;font-weight:700;margin-bottom:6px;color:var(--ink);">
                        Upload Payment Screenshot <span style="color:#ef4444;">*</span>
                    </label>
                    <input type="file" name="screenshot" id="screenshotInput" accept="image/*" required
                           style="width:100%;padding:8px 12px;border:1px dashed #94a3b8;border-radius:8px;font-size:0.85rem;background:#f8fafc;">
                </div>

                <div style="display:flex;gap:10px;">
                    <button type="button" class="button secondary" style="flex:1;padding:12px;" onclick="closeUpiModal()">Cancel</button>
                    <button type="submit" class="button primary" style="flex:2;padding:12px;background:#10b981;border-color:#10b981;">🚀 Submit Payment Proof</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        const UPI_ID = '<%=upiId%>';
        const UPI_NAME = '<%=upiName.replace("'","")%>';

        function openUpiModal(planId, planName, priceInr, clothes) {
            document.getElementById('formPlanId').value = planId;
            document.getElementById('modalPlanTitle').textContent = planName + ' (₹' + priceInr + ')';
            document.getElementById('modalPlanSub').textContent = '+' + clothes + ' clothes quota will be added';
            document.getElementById('modalAmountNotice').textContent = '₹' + priceInr;

            // Generate UPI payment string
            // upi://pay?pa=upiId&pn=upiName&am=priceInr&cu=INR&tn=StitchTrack_Plan
            const upiString = 'upi://pay?pa=' + encodeURIComponent(UPI_ID) +
                              '&pn=' + encodeURIComponent(UPI_NAME) +
                              '&am=' + encodeURIComponent(priceInr) +
                              '&cu=INR&tn=StitchTrack_' + encodeURIComponent(planName);

            // Generate QR Code URL via QR server API
            const qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=' + encodeURIComponent(upiString);
            document.getElementById('upiQrImage').src = qrUrl;

            document.getElementById('upiModal').classList.add('active');
        }

        function closeUpiModal() {
            document.getElementById('upiModal').classList.remove('active');
            document.getElementById('utrInput').value = '';
            document.getElementById('screenshotInput').value = '';
        }

        function copyUpiId() {
            navigator.clipboard.writeText(UPI_ID).then(() => {
                const btn = document.getElementById('copyBtn');
                btn.textContent = 'Copied! ✓';
                setTimeout(() => { btn.textContent = '📋 Copy'; }, 2000);
            });
        }

        // Close on escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') closeUpiModal();
        });
    </script>
</body>
</html>
