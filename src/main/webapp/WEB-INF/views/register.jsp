<%@ page contentType="text/html;charset=UTF-8" %>
<!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Register - StitchTrack</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <style>
        .tabs { display:flex; gap:10px; margin-bottom: 20px; }
        .tab { flex:1; text-align:center; padding:12px; background:var(--surface); border:1px solid var(--line); border-radius:var(--radius-sm); cursor:pointer; font-weight:600; color:var(--muted); text-decoration:none; }
        .tab.active { background:var(--blue); color:white; border-color:var(--blue); }
        .tab.active.staff { background:#7c3aed; border-color:#7c3aed; }
        .upload-area { border: 2px dashed var(--line); padding: 16px; border-radius: var(--radius-sm); text-align: center; }
        .upload-area input { width: 100%; }
    </style>
</head>
<body class="auth-bg">
    <% String type = request.getParameter("type"); boolean isStaff = "staff".equalsIgnoreCase(type); %>
    <main class="auth-card wide">
        <div class="brand">
            <div>
                <h1>StitchTrack</h1>
                <p><%= isStaff ? "Staff Registration" : "Student Registration" %></p>
            </div>
        </div>

        <div class="tabs">
            <a href="?type=student" class="tab <%= !isStaff ? "active" : "" %>">🎓 Student</a>
            <a href="?type=staff" class="tab <%= isStaff ? "active staff" : "" %>">🧺 Staff</a>
        </div>
        
        <% if(request.getAttribute("error")!=null){ %>
            <div class="alert error"><%=request.getAttribute("error")%></div>
        <% } %>
        <% if(request.getAttribute("success")!=null){ %>
            <div class="alert success"><%=request.getAttribute("success")%></div>
            <p class="center" style="margin-top:20px;">
                <a href="${pageContext.request.contextPath}/login" class="button primary">Go to Login</a>
            </p>
        <% } else { %>
            <form method="post" enctype="multipart/form-data" class="grid2" id="regForm" onsubmit="return handleReg()">
                <input type="hidden" name="type" value="<%= isStaff ? "STAFF" : "STUDENT" %>">
                <label>Full Name <input name="name" required></label>
                <label><%= isStaff ? "Staff ID (Optional)" : "Roll Number" %> <input name="roll" <%= isStaff ? "" : "required" %>></label>
                <label>Email <input type="email" name="email" required></label>
                <label>Phone Number <input name="phone" required></label>
                <label><%= isStaff ? "Assigned Area" : "Hostel / Block" %> <input name="hostel" required></label>
                <label><%= isStaff ? "Desk/Room" : "Room No" %> <input name="room" required></label>
                <label>Gender
                    <select name="gender">
                        <option>Male</option>
                        <option>Female</option>
                        <option>Other</option>
                    </select>
                </label>
                <div></div> <!-- spacer -->
                
                <label class="span2">Profile Photo (Face)
                    <div class="upload-area">
                        <input type="file" name="profile_photo" accept="image/*" required>
                    </div>
                </label>
                
                <label class="span2">College ID Card Photo
                    <div class="upload-area">
                        <input type="file" name="id_card" accept="image/*" required>
                    </div>
                </label>

                <label>Password
                    <div style="position:relative;">
                        <input type="password" id="regPassword" name="password" minlength="6" required style="padding-right: 40px;">
                        <button type="button" onclick="togglePassword('regPassword', this)" style="position:absolute;right:5px;top:5px;background:none;border:none;cursor:pointer;color:var(--muted);font-size:0.8rem;padding:6px;min-width:40px;">Show</button>
                    </div>
                </label>
                <label>Confirm Password
                    <input type="password" id="confirmPassword" minlength="6" required>
                </label>
                
                <div class="span2" style="margin-top: 10px;">
                    <button class="primary" style="width:100%; <%= isStaff ? "background:#7c3aed;" : "" %>" id="regBtn">Submit for Admin Approval</button>
                </div>
            </form>
            <p class="center" style="margin-top: 15px;"><a href="${pageContext.request.contextPath}/login">Back to login</a></p>
        <% } %>
    </main>
    <script>
        function togglePassword(id, btn) {
            var p = document.getElementById(id);
            if (p.type === 'password') { p.type = 'text'; btn.textContent = 'Hide'; }
            else { p.type = 'password'; btn.textContent = 'Show'; }
        }
        function handleReg() {
            var pw = document.getElementById('regPassword').value;
            var cp = document.getElementById('confirmPassword').value;
            if(pw !== cp) { alert("Passwords do not match!"); return false; }
            var btn = document.getElementById('regBtn');
            btn.innerHTML = 'Submitting...'; btn.style.opacity = '0.7';
            setTimeout(() => btn.disabled = true, 10);
            return true;
        }
    </script>
</body>
</html>