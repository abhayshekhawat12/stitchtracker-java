<%@ page import="java.util.*,com.stitchtrack.model.User,com.stitchtrack.util.CreditRules" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    String[] cats  = (String[])request.getAttribute("categories");
    @SuppressWarnings("unchecked")
    Set<String> largeSet = (Set<String>)request.getAttribute("largeItems");
    if(largeSet == null) largeSet = CreditRules.LARGE_ITEMS;
    User u = (User)session.getAttribute("user");
    int creditsLeft = u.getCreditsLeft();
%>
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>New Laundry Request – StitchTrack</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <style>
        /* ── Garment Grid ── */
        .garment-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(290px, 1fr));
            gap: 16px;
            margin-bottom: 28px;
        }
        .garment {
            display: flex;
            flex-direction: row;
            justify-content: space-between;
            align-items: center;
            padding: 14px 18px;
            background: #fff;
            border: 2px solid var(--line);
            border-radius: var(--radius-md);
            transition: var(--transition);
            gap: 12px;
        }
        .garment:hover { border-color: var(--blue); box-shadow: var(--shadow-sm); }
        .garment.large-item  { border-color: #f59e0b; background: #fffbeb; }
        .garment.large-item:hover { border-color: #d97706; }
        .garment-name-wrap { display: flex; flex-direction: column; gap: 4px; }
        .garment-name  { font-weight: 600; font-size: 1rem; color: var(--ink); }
        .large-badge {
            display: inline-flex; align-items: center; gap: 4px;
            background: linear-gradient(135deg,#f59e0b,#d97706);
            color: #fff; font-size: 0.68rem; font-weight: 800;
            padding: 2px 8px; border-radius: 999px; letter-spacing: .04em;
        }

        /* ── Stepper ── */
        .stepper {
            display: flex; align-items: center; gap: 6px;
            background: var(--bg); border-radius: 99px;
            padding: 4px; border: 1px solid var(--line); flex-shrink: 0;
        }
        .step-btn {
            background: #fff; border: 1px solid var(--line);
            width: 32px; height: 32px; border-radius: 50%; font-size: 1.2rem;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; color: var(--ink); padding: 0;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05); transition: var(--transition);
        }
        .step-btn:hover { background: var(--blue); color: white; border-color: var(--blue); }
        .stepper input {
            border: none; background: transparent; width: 36px; text-align: center;
            font-weight: 700; font-size: 1.1rem; padding: 0; color: var(--blue);
        }
        .stepper input:focus { box-shadow: none; outline: none; }
        .stepper input::-webkit-outer-spin-button, .stepper input::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }

        /* ── Credit Summary Footer ── */
        .credit-footer {
            background: #fff; border: 1px solid var(--line); border-radius: var(--radius-lg);
            padding: 20px 24px; box-shadow: var(--shadow-md);
            position: sticky; bottom: 24px; z-index: 10;
        }
        .credit-grid {
            display: grid; grid-template-columns: repeat(auto-fit,minmax(130px,1fr));
            gap: 12px; margin-bottom: 16px;
        }
        .credit-stat { text-align: center; }
        .credit-stat .cs-val { font-size: 1.6rem; font-weight: 800; line-height: 1; }
        .credit-stat .cs-label { font-size: 0.72rem; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: .04em; margin-top: 2px; }
        .cs-val.ok   { color: #10b981; }
        .cs-val.warn { color: #f59e0b; }
        .cs-val.bad  { color: #ef4444; }

        .credit-bar { height: 8px; border-radius: 99px; background: var(--line); overflow: hidden; margin-bottom: 14px; }
        .credit-bar-fill { height: 100%; border-radius: 99px; background: linear-gradient(90deg,#3b82f6,#8b5cf6); transition: width .3s ease; }
        .credit-bar-fill.bad { background: linear-gradient(90deg,#ef4444,#dc2626); }

        .insuf-msg {
            background: #fde8e7; border: 1px solid #fca5a5; border-radius: 8px;
            padding: 10px 14px; font-size: 0.9rem; color: #b91c1c;
            display: none; margin-bottom: 10px;
        }

        .extra-fields {
            background: #f8fafc; border: 1px solid var(--line);
            border-radius: var(--radius-md); padding: 20px; margin-bottom: 20px;
        }

        /* ── Modal Overlay ── */
        .modal-overlay {
            display: none; position: fixed; inset: 0;
            background: rgba(0,0,0,0.55); z-index: 1000;
            align-items: center; justify-content: center; padding: 16px;
        }
        .modal-overlay.open { display: flex; }
        .modal-box {
            background: #fff; border-radius: 20px; padding: 32px 28px;
            max-width: 440px; width: 100%; box-shadow: 0 24px 60px rgba(0,0,0,0.18);
            animation: modalSlide .28s ease;
        }
        @keyframes modalSlide { from{transform:translateY(24px);opacity:0} to{transform:translateY(0);opacity:1} }
        .modal-icon { font-size: 3rem; text-align: center; margin-bottom: 10px; }
        .modal-title { font-size: 1.35rem; font-weight: 800; text-align: center; color: var(--ink); margin-bottom: 6px; }
        .modal-subtitle { font-size: 0.9rem; color: var(--muted); text-align: center; margin-bottom: 20px; }
        .modal-detail {
            background: linear-gradient(135deg,#fffbeb,#fef9c3); border: 1px solid #f59e0b;
            border-radius: 12px; padding: 16px 18px; margin-bottom: 20px;
        }
        .md-row { display: flex; justify-content: space-between; align-items: center; padding: 4px 0; font-size: 0.92rem; }
        .md-row + .md-row { border-top: 1px dashed #fde68a; margin-top: 4px; }
        .md-label { color: var(--muted); }
        .md-value { font-weight: 700; color: var(--ink); }
        .md-value.highlight { color: #d97706; font-size: 1.05rem; }
        .modal-btns { display: flex; gap: 12px; }
        .modal-btns button { flex: 1; padding: 13px; border-radius: 12px; font-size: 1rem; font-weight: 700; cursor: pointer; border: none; transition: .2s; }
        .modal-btns .btn-continue { background: linear-gradient(135deg,#3b82f6,#8b5cf6); color: #fff; }
        .modal-btns .btn-continue:hover { opacity: .9; transform: scale(1.02); }
        .modal-btns .btn-change { background: #f1f5f9; color: var(--ink); }
        .modal-btns .btn-change:hover { background: #e2e8f0; }

        /* ── Quota bar above form ── */
        .quota-bar-wrap { background: #fff; border: 1px solid var(--line); border-radius: 12px; padding: 14px 20px; margin-bottom: 20px; }
        .quota-bar-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
        .quota-bar-label { font-size: .85rem; color: var(--muted); font-weight: 600; }
        .quota-bar-val { font-size: .9rem; font-weight: 800; color: var(--blue); }

        @media(max-width: 600px) {
            .credit-grid { grid-template-columns: repeat(2,1fr); }
            .modal-box { padding: 24px 18px; }
        }
    </style>
</head>
<body>
    <!-- ── Large Item Popup Modal ── -->
    <div class="modal-overlay" id="largeItemModal" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
        <div class="modal-box">
            <div class="modal-icon">🛏️</div>
            <div class="modal-title" id="modalTitle">Large Item Selected!</div>
            <div class="modal-subtitle">
                Blankets, razai and other large items require <b>3 credits per item</b><br>
                because they need extra washing and processing.
            </div>
            <div class="modal-detail">
                <div class="md-row">
                    <span class="md-label">Item</span>
                    <span class="md-value" id="mItem">—</span>
                </div>
                <div class="md-row">
                    <span class="md-label">Credits per item</span>
                    <span class="md-value highlight">3 credits</span>
                </div>
                <div class="md-row">
                    <span class="md-label">Quantity selected</span>
                    <span class="md-value" id="mQty">—</span>
                </div>
                <div class="md-row">
                    <span class="md-label">Credits required</span>
                    <span class="md-value highlight" id="mReq">—</span>
                </div>
                <div class="md-row">
                    <span class="md-label">Balance after request</span>
                    <span class="md-value" id="mAfter">—</span>
                </div>
            </div>
            <div class="modal-btns">
                <button class="btn-change" onclick="closeModal()">✕ Change Item</button>
                <button class="btn-continue" onclick="confirmModal()">Continue →</button>
            </div>
        </div>
    </div>

    <header class="topbar">
        <div class="brand compact">
            <h1>StitchTrack</h1>
            <span>New Request</span>
        </div>
        <nav>
            <a href="${pageContext.request.contextPath}/student/dashboard">Dashboard</a>
            <a href="${pageContext.request.contextPath}/student/subscription">My Credits</a>
            <a href="${pageContext.request.contextPath}/logout">Logout</a>
        </nav>
    </header>

    <main class="container narrow">
        <section class="hero">
            <div>
                <p class="eyebrow">LAUNDRY REQUEST</p>
                <h2>Select your garments</h2>
                <p>Available credits: <b id="quotaDisplay" style="color:var(--blue);font-size:1.2rem;"><%=creditsLeft%></b>
                   &nbsp;<span style="color:var(--muted);font-size:0.85rem;">
                   (Large items cost 3 credits each)</span></p>
            </div>
        </section>

        <% if(request.getAttribute("error") != null) { %>
        <div class="alert error"><%=request.getAttribute("error")%></div>
        <% } %>

        <!-- Credit usage bar -->
        <div class="quota-bar-wrap">
            <div class="quota-bar-header">
                <span class="quota-bar-label">💳 Credit Balance</span>
                <span class="quota-bar-val"><%=u.getMembershipUsed()%> used / <%=u.getMembershipLimit()%> total</span>
            </div>
            <div class="credit-bar">
                <div class="credit-bar-fill" id="usedBar"
                     style="width:<%=Math.min(100,(int)(u.getMembershipUsed()*100.0/Math.max(1,u.getMembershipLimit())))%>%"></div>
            </div>
            <span style="font-size:.8rem;color:var(--muted);">
                <%=creditsLeft%> credits remaining &bull;
                <a href="${pageContext.request.contextPath}/student/subscription" style="color:var(--blue);">Get more credits →</a>
            </span>
        </div>

        <form method="post" action="${pageContext.request.contextPath}/student/new-request"
              id="laundryForm" onsubmit="return handleSubmit()">

            <div class="garment-grid" id="garmentGrid">
                <% for(String cat : cats) {
                    boolean isLarge = largeSet.contains(cat);
                    String key = "item_" + cat.replace(" ","_");
                    String icon = isLarge ? "🛏️ " : "";
                %>
                <div class="garment <%=isLarge?"large-item":""%>"
                     data-cat="<%=cat%>"
                     data-large="<%=isLarge%>"
                     data-rate="<%=isLarge?3:1%>">
                    <div class="garment-name-wrap">
                        <span class="garment-name"><%=icon%><%=cat%></span>
                        <% if(isLarge) { %>
                        <span class="large-badge">⚡ 3 Credits/item</span>
                        <% } else { %>
                        <span style="font-size:0.72rem;color:var(--muted);">1 credit/item</span>
                        <% } %>
                    </div>
                    <div class="stepper">
                        <button type="button" class="step-btn" onclick="step(this,-1,'<%=cat%>')">−</button>
                        <input class="count" type="number" min="0" max="30" value="0"
                               name="<%=key%>"
                               data-cat="<%=cat%>"
                               data-large="<%=isLarge%>"
                               data-rate="<%=isLarge?3:1%>"
                               oninput="onQuantityChange(this,'<%=cat%>',<%=isLarge%>)"
                               readonly>
                        <button type="button" class="step-btn" onclick="step(this,1,'<%=cat%>')">+</button>
                    </div>
                </div>
                <% } %>
            </div>

            <div class="extra-fields">
                <label style="margin-bottom:8px;">Special Instructions</label>
                <textarea name="instructions" placeholder="e.g., Wash colored clothes separately, use fabric softener…"></textarea>
            </div>

            <!-- Live Credit Summary -->
            <div class="credit-footer">
                <div class="credit-grid">
                    <div class="credit-stat">
                        <div class="cs-val" id="totalItemsDisp">0</div>
                        <div class="cs-label">Total Items</div>
                    </div>
                    <div class="credit-stat">
                        <div class="cs-val warn" id="totalCredDisp">0</div>
                        <div class="cs-label">Credits Required</div>
                    </div>
                    <div class="credit-stat">
                        <div class="cs-val ok" id="availDisp"><%=creditsLeft%></div>
                        <div class="cs-label">Available Credits</div>
                    </div>
                    <div class="credit-stat">
                        <div class="cs-val ok" id="afterDisp"><%=creditsLeft%></div>
                        <div class="cs-label">Remaining After</div>
                    </div>
                </div>
                <div class="credit-bar">
                    <div class="credit-bar-fill" id="reqBar" style="width:0%"></div>
                </div>
                <div class="insuf-msg" id="insufMsg">
                    ⚠️ <b>Insufficient credits.</b> Please
                    <a href="${pageContext.request.contextPath}/student/subscription"
                       style="color:#b91c1c;font-weight:700;">purchase an additional credit pack</a>
                    from the Subscription page.
                </div>
                <button type="submit" class="primary" id="submitBtn"
                        style="padding:14px 32px;font-size:1.1rem;width:100%;">
                    Submit Laundry Request
                </button>
            </div>
        </form>
    </main>

    <script>
        /* ─── Constants (mirror CreditRules.java) ─── */
        const LARGE_ITEMS = new Set([
            'Blanket','Bedsheet','Quilt','Razai','Comforter','Duvet'
        ]);
        const MAX_QUOTA = <%=creditsLeft%>;
        let pendingLargeItem = null;  // {cat, input, qty} — held while modal is open

        /* ─── Stepper ─── */
        function step(btn, delta, cat) {
            const input = btn.parentElement.querySelector('input');
            const val   = parseInt(input.value) || 0;
            const newVal = Math.max(0, Math.min(30, val + delta));
            if (newVal !== val) {
                input.value = newVal;
                onQuantityChange(input, cat, LARGE_ITEMS.has(cat));
            }
        }

        /* ─── Quantity change handler ─── */
        let lastLargeShown = {}; // {cat: lastQtyShown}

        function onQuantityChange(input, cat, isLarge) {
            const qty = parseInt(input.value) || 0;

            // Show popup only when a large item's qty increases from 0→n or n→n+1 for the first time
            if (isLarge && qty > 0) {
                const prev = lastLargeShown[cat] || 0;
                if (prev === 0) {
                    // First selection of this large item — show popup
                    pendingLargeItem = { cat, input, qty };
                    openModal(cat, qty);
                    return; // Don't recalc yet — wait for modal response
                }
            }
            if (isLarge) lastLargeShown[cat] = qty;
            recalc();
        }

        /* ─── Modal ─── */
        function openModal(cat, qty) {
            const credits = qty * 3;
            const after   = MAX_QUOTA - calcTotalCredits() - credits; // subtract pending large too
            document.getElementById('mItem').textContent  = cat;
            document.getElementById('mQty').textContent   = qty;
            document.getElementById('mReq').textContent   = credits + ' credits';
            document.getElementById('mAfter').textContent = after >= 0
                ? after + ' credits remaining' : '⚠️ Insufficient credits!';
            document.getElementById('mAfter').style.color = after >= 0 ? '#10b981' : '#ef4444';
            document.getElementById('largeItemModal').classList.add('open');
            document.body.style.overflow = 'hidden';
        }

        function closeModal() {
            document.getElementById('largeItemModal').classList.remove('open');
            document.body.style.overflow = '';
            if (pendingLargeItem) {
                // Revert the input back to 0
                pendingLargeItem.input.value = 0;
                lastLargeShown[pendingLargeItem.cat] = 0;
                pendingLargeItem = null;
            }
            recalc();
        }

        function confirmModal() {
            document.getElementById('largeItemModal').classList.remove('open');
            document.body.style.overflow = '';
            if (pendingLargeItem) {
                lastLargeShown[pendingLargeItem.cat] = pendingLargeItem.qty;
                pendingLargeItem = null;
            }
            recalc();
        }

        // Close modal on backdrop click
        document.getElementById('largeItemModal').addEventListener('click', function(e) {
            if (e.target === this) closeModal();
        });
        document.addEventListener('keydown', e => { if(e.key === 'Escape') closeModal(); });

        /* ─── Credit calculator ─── */
        function calcTotalItems() {
            let t = 0;
            document.querySelectorAll('.count').forEach(x => t += (parseInt(x.value)||0));
            return t;
        }
        function calcTotalCredits() {
            let c = 0;
            document.querySelectorAll('.count').forEach(x => {
                const qty  = parseInt(x.value) || 0;
                const rate = parseInt(x.dataset.rate) || 1;
                c += qty * rate;
            });
            return c;
        }

        function recalc() {
            const totalItems  = calcTotalItems();
            const totalCredit = calcTotalCredits();
            const avail       = MAX_QUOTA;
            const after       = avail - totalCredit;
            const pct         = Math.min(100, Math.round(totalCredit / Math.max(1, avail) * 100));

            document.getElementById('totalItemsDisp').textContent = totalItems;
            document.getElementById('totalCredDisp').textContent  = totalCredit;
            document.getElementById('availDisp').textContent      = avail;

            const afterEl  = document.getElementById('afterDisp');
            const barFill  = document.getElementById('reqBar');
            const insufMsg = document.getElementById('insufMsg');
            const submitBtn= document.getElementById('submitBtn');
            const quotaDisp= document.getElementById('quotaDisplay');

            afterEl.textContent = after >= 0 ? after : 0;

            // Colors
            afterEl.className = 'cs-val ' + (after >= 0 ? (after < avail * 0.2 ? 'warn' : 'ok') : 'bad');
            document.getElementById('totalCredDisp').className = 'cs-val ' + (totalCredit > avail ? 'bad' : 'warn');
            barFill.style.width = pct + '%';
            barFill.className   = 'credit-bar-fill' + (totalCredit > avail ? ' bad' : '');

            if (totalCredit > avail) {
                insufMsg.style.display = 'block';
                submitBtn.disabled     = true;
                submitBtn.style.opacity= '0.45';
                submitBtn.textContent  = 'Insufficient Credits';
            } else if (totalItems === 0) {
                insufMsg.style.display = 'none';
                submitBtn.disabled     = true;
                submitBtn.style.opacity= '0.45';
                submitBtn.textContent  = 'Submit Laundry Request';
            } else {
                insufMsg.style.display = 'none';
                submitBtn.disabled     = false;
                submitBtn.style.opacity= '1';
                submitBtn.textContent  = 'Submit ' + totalItems + ' item' + (totalItems!==1?'s':'') +
                                         ' (' + totalCredit + ' credit' + (totalCredit!==1?'s':'') + ')';
            }
            quotaDisp.textContent = avail;
        }

        /* ─── Form submit guard ─── */
        function handleSubmit() {
            const totalItems  = calcTotalItems();
            const totalCredit = calcTotalCredits();
            if (totalItems === 0) { alert('Please select at least one item.'); return false; }
            if (totalCredit > MAX_QUOTA) {
                alert('Insufficient credits. Please purchase a plan first.');
                return false;
            }
            const btn = document.getElementById('submitBtn');
            btn.textContent  = 'Submitting…';
            btn.style.opacity= '0.7';
            setTimeout(() => btn.disabled = true, 10);
            return true;
        }

        // Init
        recalc();
    </script>
</body>
</html>