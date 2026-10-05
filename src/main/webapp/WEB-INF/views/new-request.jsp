<%@ page import="com.stitchtrack.model.User" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% 
    String[] cats=(String[])request.getAttribute("categories");
    User u=(User)session.getAttribute("user");
%>
<!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>New Request - StitchTrack</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
</head>
    <style>
        .garment-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 16px;
            margin-bottom: 32px;
        }
        .garment {
            display: flex !important;
            flex-direction: row !important;
            justify-content: space-between !important;
            align-items: center !important;
            padding: 16px 20px !important;
            background: #fff;
            border: 1px solid var(--line);
            border-radius: var(--radius-md);
            transition: var(--transition);
        }
        .garment:hover {
            border-color: var(--blue);
            box-shadow: var(--shadow-sm);
        }
        .garment-name {
            font-weight: 600;
            font-size: 1.05rem;
            color: var(--ink);
        }
        .stepper {
            display: flex;
            align-items: center;
            gap: 6px;
            background: var(--bg);
            border-radius: 99px;
            padding: 4px;
            border: 1px solid var(--line);
        }
        .step-btn {
            background: #fff;
            border: 1px solid var(--line);
            width: 32px;
            height: 32px;
            border-radius: 50%;
            font-size: 1.2rem;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            color: var(--ink);
            padding: 0;
            box-shadow: 0 1px 2px rgba(0,0,0,0.05);
            transition: var(--transition);
        }
        .step-btn:hover {
            background: var(--blue);
            color: white;
            border-color: var(--blue);
        }
        .stepper input {
            border: none;
            background: transparent;
            width: 36px;
            text-align: center;
            font-weight: 700;
            font-size: 1.1rem;
            padding: 0;
            color: var(--blue);
        }
        .stepper input:focus {
            box-shadow: none;
            outline: none;
        }
        .stepper input::-webkit-outer-spin-button,
        .stepper input::-webkit-inner-spin-button {
            -webkit-appearance: none;
            margin: 0;
        }
        .extra-fields {
            background: #f8fafc;
            border: 1px solid var(--line);
            border-radius: var(--radius-md);
            padding: 24px;
            margin-bottom: 24px;
        }
        .request-footer {
            background: #fff;
            border: 1px solid var(--line);
            border-radius: var(--radius-lg);
            padding: 24px;
            box-shadow: var(--shadow-md);
            margin-top: 0;
            border-top: 1px solid var(--line);
            position: sticky;
            bottom: 24px;
            z-index: 10;
        }
        .request-footer strong {
            color: var(--blue);
        }
    </style>
</head>
<body>
    <header class="topbar">
        <div class="brand compact">
            <h1>StitchTrack</h1>
            <span>New Request</span>
        </div>
        <nav>
            <a href="${pageContext.request.contextPath}/student/dashboard">Dashboard</a>
            <a href="${pageContext.request.contextPath}/logout">Logout</a>
        </nav>
    </header>
    <main class="container narrow">
        <section class="hero">
            <div>
                <p class="eyebrow">LAUNDRY REQUEST</p>
                <h2>Select your garments</h2>
                <p>Remaining quota: <b id="quotaLeft" style="color:var(--blue);font-size:1.2rem;"><%=u.getCreditsLeft()%></b> items</p>
            </div>
        </section>
        
        <% if(request.getAttribute("error")!=null){ %>
            <div class="alert error"><%=request.getAttribute("error")%></div>
        <% } %>
        
        <form method="post" id="laundryForm" onsubmit="return handleSubmit()">
            <div class="garment-grid">
                <% for(String c:cats){ String key="item_"+c.replace(" ","_"); %>
                <div class="garment">
                    <span class="garment-name"><%=c%></span>
                    <div class="stepper">
                        <button type="button" class="step-btn" onclick="step(this, -1)">-</button>
                        <input class="count" type="number" min="0" max="50" value="0" name="<%=key%>" oninput="sumItems()" readonly>
                        <button type="button" class="step-btn" onclick="step(this, 1)">+</button>
                    </div>
                </div>
                <% } %>
            </div>
            
            <div class="extra-fields">
                <label style="margin-bottom:8px;">Special Instructions</label>
                <textarea name="instructions" placeholder="e.g., Wash colored clothes separately, use fabric softener..."></textarea>
            </div>

            <div class="request-footer">
                <div style="font-size:1.1rem; font-weight:500;">Total Items: <strong id="total" style="display:inline-block;margin-left:8px;font-size:1.8rem;">0</strong></div>
                <button type="submit" class="primary" id="submitBtn" style="padding: 14px 32px; font-size: 1.1rem;">Submit Request</button>
            </div>
        </form>
    </main>
    <script>
        var maxQuota = <%=u.getCreditsLeft()%>;
        
        function step(btn, delta) {
            let input = btn.parentElement.querySelector('input');
            let val = parseInt(input.value) || 0;
            let newVal = val + delta;
            if(newVal >= 0 && newVal <= 50) {
                input.value = newVal;
                sumItems();
            }
        }

        function sumItems(){
            let t=0;
            document.querySelectorAll('.count').forEach(x => {
                let v = Number(x.value||0);
                if(v < 0) { x.value = 0; v = 0; }
                t+=v;
            });
            document.getElementById('total').textContent = t;
            
            var btn = document.getElementById('submitBtn');
            if(t > maxQuota) {
                btn.disabled = true;
                btn.style.opacity = '0.5';
                document.getElementById('total').style.color = 'var(--danger)';
            } else {
                btn.disabled = t === 0;
                btn.style.opacity = t === 0 ? '0.5' : '1';
                document.getElementById('total').style.color = 'var(--blue)';
            }
        }
        
        function handleSubmit() {
            let t = parseInt(document.getElementById('total').textContent);
            if(t === 0) {
                alert('Please add at least one item.');
                return false;
            }
            if(t > maxQuota) {
                alert('You have exceeded your remaining quota.');
                return false;
            }
            var btn = document.getElementById('submitBtn');
            btn.innerHTML = 'Submitting...';
            btn.style.opacity = '0.7';
            setTimeout(() => btn.disabled = true, 10);
            return true;
        }
        
        sumItems();
    </script>
</body>
</html>