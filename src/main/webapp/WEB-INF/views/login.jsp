<%@ page contentType="text/html;charset=UTF-8" %>
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>StitchTrack – Login</title>
    <meta name="description" content="Login to StitchTrack Smart College Laundry Management System.">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <style>
        /* ── Role Selector ── */
        .role-selector {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
            margin-bottom: 28px;
        }
        .role-card {
            position: relative;
            cursor: pointer;
        }
        .role-card input[type="radio"] {
            position: absolute;
            opacity: 0;
            width: 0; height: 0;
        }
        .role-label {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 8px;
            padding: 16px 8px 14px;
            border: 2px solid var(--line);
            border-radius: var(--radius-md);
            background: #f8fafc;
            cursor: pointer;
            transition: all 0.25s cubic-bezier(0.4,0,0.2,1);
            text-align: center;
            user-select: none;
        }
        .role-label:hover {
            border-color: #94a3b8;
            background: #f1f5f9;
            transform: translateY(-2px);
        }
        .role-card input:checked + .role-label {
            border-color: var(--blue);
            background: #eff6ff;
            box-shadow: 0 0 0 3px rgba(37,99,235,0.15);
            transform: translateY(-3px);
        }
        .role-card.staff  input:checked + .role-label { border-color: #7c3aed; background: #ede9fe; box-shadow: 0 0 0 3px rgba(124,58,237,0.15); }
        .role-card.admin  input:checked + .role-label { border-color: #059669; background: #ecfdf5; box-shadow: 0 0 0 3px rgba(5,150,105,0.15); }

        .role-icon {
            font-size: 1.9rem;
            line-height: 1;
            transition: transform 0.25s;
        }
        .role-card input:checked + .role-label .role-icon {
            transform: scale(1.15);
        }
        .role-name {
            font-size: 0.82rem;
            font-weight: 700;
            letter-spacing: 0.04em;
            color: var(--muted);
        }
        .role-card input:checked + .role-label .role-name { color: var(--blue); }
        .role-card.staff  input:checked + .role-label .role-name { color: #7c3aed; }
        .role-card.admin  input:checked + .role-label .role-name { color: #059669; }

        .role-check {
            position: absolute;
            top: 6px; right: 6px;
            width: 18px; height: 18px;
            background: var(--blue);
            border-radius: 50%;
            display: none;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 0.65rem;
            font-weight: 800;
        }
        .role-card.staff  .role-check { background: #7c3aed; }
        .role-card.admin  .role-check { background: #059669; }
        .role-card input:checked ~ .role-check { display: flex; }

        /* Dynamic login button themes */
        .login-btn-student { background: linear-gradient(135deg, #2563eb, #3b82f6); box-shadow: 0 4px 14px rgba(37,99,235,0.4); }
        .login-btn-staff   { background: linear-gradient(135deg, #7c3aed, #8b5cf6); box-shadow: 0 4px 14px rgba(124,58,237,0.4); }
        .login-btn-admin   { background: linear-gradient(135deg, #059669, #10b981); box-shadow: 0 4px 14px rgba(5,150,105,0.4); }

        /* Role hint */
        .role-hint {
            font-size: 0.78rem;
            text-align: center;
            margin: -12px 0 16px;
            font-weight: 500;
            color: var(--muted);
            min-height: 18px;
            transition: all 0.2s;
        }

        .divider-line {
            border: none;
            border-top: 1px solid var(--line);
            margin: 20px 0;
        }

        .auth-card { width: min(100%, 440px); }
    </style>
</head>
<body class="auth-bg">
    <main class="auth-card">
        <!-- Brand -->
        <div class="brand">
            <img src="${pageContext.request.contextPath}/assets/logo.png" onerror="this.style.display='none'">
            <div>
                <h1>StitchTrack</h1>
                <p>Smart College Laundry</p>
            </div>
        </div>

        <h2 style="margin-bottom:4px;">Welcome back 👋</h2>
        <p class="muted" style="margin:0 0 24px;">Select your role to sign in</p>

        <% if(request.getAttribute("error") != null){ %>
            <div class="alert error">&#10005; <%=request.getAttribute("error")%></div>
        <% } %>

        <!-- Role Selector -->
        <div class="role-selector" id="roleSelector">

            <div class="role-card" id="cardStudent">
                <input type="radio" name="roleChoice" id="roleStudent" value="STUDENT" checked onchange="switchRole('STUDENT')">
                <label class="role-label" for="roleStudent">
                    <span class="role-icon">🎓</span>
                    <span class="role-name">STUDENT</span>
                </label>
                <span class="role-check">✓</span>
            </div>

            <div class="role-card staff" id="cardStaff">
                <input type="radio" name="roleChoice" id="roleStaff" value="STAFF" onchange="switchRole('STAFF')">
                <label class="role-label" for="roleStaff">
                    <span class="role-icon">🧺</span>
                    <span class="role-name">STAFF</span>
                </label>
                <span class="role-check">✓</span>
            </div>

            <div class="role-card admin" id="cardAdmin">
                <input type="radio" name="roleChoice" id="roleAdmin" value="ADMIN" onchange="switchRole('ADMIN')">
                <label class="role-label" for="roleAdmin">
                    <span class="role-icon">🛡️</span>
                    <span class="role-name">ADMIN</span>
                </label>
                <span class="role-check">✓</span>
            </div>

        </div>

        <p class="role-hint" id="roleHint">🎓 Login as Student — use your roll number or email</p>

        <hr class="divider-line">

        <!-- Login Form -->
        <form method="post" class="stack" id="loginForm" onsubmit="return handleLogin()" style="gap:18px;">
            <label for="identifier">
                <span id="identifierLabel">Email or Roll Number</span>
                <input name="identifier" id="identifier" required placeholder="student@college.edu or ROLL001" autocomplete="username">
            </label>
            <label for="password">
                Password
                <div style="position:relative;">
                    <input name="password" id="password" type="password" required placeholder="••••••••" style="padding-right:48px;" autocomplete="current-password">
                    <button type="button" onclick="togglePassword(this)"
                        style="position:absolute;right:5px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--muted);font-size:0.8rem;padding:6px 10px;">
                        👁 Show
                    </button>
                </div>
            </label>
            <button type="submit" class="primary login-btn-student" id="loginBtn" style="padding:14px;font-size:1rem;font-weight:700;transition:all 0.3s;">
                🎓 Sign in as Student
            </button>
        </form>

        <p class="center" style="margin-top:20px;font-size:0.88rem;">
            New student? <a href="${pageContext.request.contextPath}/register">Create account</a>
        </p>
    </main>

    <script>
        var roles = {
            STUDENT: {
                hint:        '🎓 Login as Student — use your roll number or email',
                btnClass:    'login-btn-student',
                btnText:     '🎓 Sign in as Student',
                placeholder: 'student@college.edu or ROLL001',
                label:       'Email or Roll Number'
            },
            STAFF: {
                hint:        '🧺 Login as Laundry Staff — use your staff email',
                btnClass:    'login-btn-staff',
                btnText:     '🧺 Sign in as Staff',
                placeholder: 'laundrystaff@stitchtrack.com',
                label:       'Staff Email'
            },
            ADMIN: {
                hint:        '🛡️ Login as Admin — use your admin credentials',
                btnClass:    'login-btn-admin',
                btnText:     '🛡️ Sign in as Admin',
                placeholder: 'admin@college.edu',
                label:       'Admin Email'
            }
        };

        function switchRole(role) {
            var cfg    = roles[role];
            var btn    = document.getElementById('loginBtn');
            var hint   = document.getElementById('roleHint');
            var input  = document.getElementById('identifier');
            var lbl    = document.getElementById('identifierLabel');

            // Update hint
            hint.textContent = cfg.hint;

            // Swap button class
            btn.className = 'primary ' + cfg.btnClass;
            btn.textContent = cfg.btnText;

            // Update placeholder & label
            input.placeholder = cfg.placeholder;
            lbl.textContent   = cfg.label;
        }

        function togglePassword(btn) {
            var p = document.getElementById('password');
            if (p.type === 'password') {
                p.type = 'text';
                btn.textContent = '🙈 Hide';
            } else {
                p.type = 'password';
                btn.textContent = '👁 Show';
            }
        }

        function handleLogin() {
            var btn = document.getElementById('loginBtn');
            btn.innerHTML = '⏳ Signing in...';
            btn.style.opacity = '0.75';
            setTimeout(function(){ btn.disabled = true; }, 10);
            return true;
        }

        // If server sends back an error, keep the role visually selected
        (function(){
            var savedRole = sessionStorage.getItem('lastRole') || 'STUDENT';
            var radio = document.querySelector('input[name="roleChoice"][value="' + savedRole + '"]');
            if (radio) { radio.checked = true; switchRole(savedRole); }
        })();

        // Save selected role to sessionStorage before submit
        document.getElementById('loginForm').addEventListener('submit', function(){
            var checked = document.querySelector('input[name="roleChoice"]:checked');
            if (checked) sessionStorage.setItem('lastRole', checked.value);
        });
    </script>
</body>
</html>