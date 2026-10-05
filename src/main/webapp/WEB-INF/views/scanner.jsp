<%@ page contentType="text/html;charset=UTF-8" %>
<!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Pickup Scanner - StitchTrack</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/app.css">
    <!-- jsQR library for QR decoding from canvas -->
    <script src="https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js"></script>
    <style>
        .scanner-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius-lg);
            padding: 32px;
            box-shadow: var(--shadow-md);
        }
        #video {
            width: 100%;
            max-height: 340px;
            object-fit: cover;
            border-radius: var(--radius-md);
            background: #111;
            display: none;
        }
        #canvas { display: none; }
        .scanner-frame {
            position: relative;
            border-radius: var(--radius-md);
            overflow: hidden;
            background: #000;
            min-height: 200px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .scanner-frame #video { display: block; }
        .scan-overlay {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 200px;
            height: 200px;
            border: 3px solid rgba(37,99,235,0.8);
            border-radius: 16px;
            box-shadow: 0 0 0 4000px rgba(0,0,0,0.4);
            animation: pulse 2s ease infinite;
            display: none;
        }
        .scan-overlay.active { display: block; }
        @keyframes pulse {
            0%, 100% { border-color: rgba(37,99,235,0.8); }
            50% { border-color: rgba(96,165,250,1); box-shadow: 0 0 0 4000px rgba(0,0,0,0.4), 0 0 20px rgba(37,99,235,0.6); }
        }
        .divider {
            display: flex;
            align-items: center;
            gap: 16px;
            margin: 28px 0;
            color: var(--muted);
            font-size: 0.9rem;
            font-weight: 600;
        }
        .divider::before, .divider::after {
            content: '';
            flex: 1;
            height: 1px;
            background: var(--line);
        }
        #scanStatus {
            text-align: center;
            padding: 12px;
            border-radius: var(--radius-md);
            font-weight: 500;
            font-size: 0.95rem;
            margin: 16px 0;
        }
    </style>
</head>
<body>
    <header class="topbar">
        <div class="brand compact">
            <h1>StitchTrack</h1>
            <span>Pickup Scanner</span>
        </div>
        <nav>
            <a href="${pageContext.request.contextPath}/admin/dashboard">Admin Dashboard</a>
            <a href="${pageContext.request.contextPath}/logout">Logout</a>
        </nav>
    </header>
    <main class="container narrow">
        <section class="hero">
            <div>
                <p class="eyebrow">SINGLE-USE QR CHECKOUT</p>
                <h2>Scan Student Pickup Token</h2>
                <p>Use your camera to scan the QR code, or enter the token manually below.</p>
            </div>
        </section>

        <%if(request.getAttribute("error")!=null){%>
            <div class="alert error">&#10005; <%=request.getAttribute("error")%></div>
        <%}%>
        <%if(request.getAttribute("success")!=null){%>
            <div class="alert success">&#10003; <%=request.getAttribute("success")%></div>
        <%}%>

        <div class="scanner-card">
            <!-- Camera Scanner Section -->
            <div id="cameraSection">
                <div class="scanner-frame" id="scannerFrame" style="min-height:60px;">
                    <video id="video" playsinline muted autoplay></video>
                    <div class="scan-overlay" id="scanOverlay"></div>
                    <p id="cameraPlaceholder" style="color:#aaa; padding:20px;">Camera not started</p>
                </div>
                <canvas id="canvas"></canvas>

                <p id="scanStatus" class="muted"></p>

                <button type="button" class="primary" id="startBtn" onclick="startScanner()" style="width:100%; margin-top:8px;">
                    📷 Start Camera Scanner
                </button>
                <button type="button" class="secondary" id="stopBtn" onclick="stopScanner()" style="width:100%; margin-top:10px; display:none;">
                    ⏹ Stop Camera
                </button>
            </div>

            <div class="divider">OR ENTER TOKEN MANUALLY</div>

            <!-- Manual Token Form -->
            <form method="post" id="scanForm" class="stack">
                <label>QR Token
                    <input id="token" name="token" required placeholder="STITCH-XXXXXXXXXXXX" style="font-family: monospace; font-size: 1.05rem; letter-spacing: 0.05em;">
                </label>
                <button class="primary" style="padding: 14px;">✅ Verify &amp; Deliver</button>
            </form>
        </div>
    </main>

    <script>
        let stream, scanInterval;

        async function startScanner() {
            const status = document.getElementById('scanStatus');
            const startBtn = document.getElementById('startBtn');
            const stopBtn = document.getElementById('stopBtn');
            const overlay = document.getElementById('scanOverlay');
            const placeholder = document.getElementById('cameraPlaceholder');

            status.textContent = 'Requesting camera access...';
            status.style.color = 'var(--muted)';

            try {
                stream = await navigator.mediaDevices.getUserMedia({
                    video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } }
                });

                const video = document.getElementById('video');
                video.srcObject = stream;
                await video.play();

                placeholder.style.display = 'none';
                overlay.classList.add('active');
                startBtn.style.display = 'none';
                stopBtn.style.display = 'block';
                status.textContent = '🔍 Scanning for QR code...';
                status.style.color = 'var(--blue)';

                // Use jsQR for scanning
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
                            document.getElementById('token').value = code.data;
                            status.textContent = '✅ QR Detected! Submitting...';
                            status.style.color = 'var(--ok)';
                            stopScanner();
                            setTimeout(() => document.getElementById('scanForm').submit(), 500);
                        }
                    }
                }, 300);

            } catch (err) {
                status.textContent = '❌ Camera error: ' + err.message + '. Please use manual entry below.';
                status.style.color = 'var(--danger)';
            }
        }

        function stopScanner() {
            if (stream) {
                stream.getTracks().forEach(t => t.stop());
                stream = null;
            }
            if (scanInterval) {
                clearInterval(scanInterval);
                scanInterval = null;
            }
            document.getElementById('startBtn').style.display = 'block';
            document.getElementById('stopBtn').style.display = 'none';
            document.getElementById('scanOverlay').classList.remove('active');
            document.getElementById('video').srcObject = null;
            document.getElementById('cameraPlaceholder').style.display = 'block';
        }
    </script>
</body>
</html>