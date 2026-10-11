# StitchTrack Deployment & Hosting Guide

## 1. Root Cause: Why Vercel Showed "This page doesn't exist" (404)

- **Platform Architecture Mismatch**: Vercel is designed for Node.js, static frontend frameworks (React, Next.js, Vue, Vite), and serverless functions (Node, Python, Go).
- **No JVM or Servlet Container**: Vercel does **not** provide a Java Virtual Machine (JVM), does not support Apache Tomcat or any Jakarta EE/Servlet container, and cannot compile or execute `.jsp` files or `.war` web archives.
- **Why 404 Occurred**: When deployed on Vercel, Vercel attempted to serve the project as static files. Since JSP views are kept inside `/WEB-INF/views/` (protected by the servlet specification) and dynamic routing is handled by compiled Java Servlets, Vercel found no static `index.html` at the root and served its default error: **"404: NOT_FOUND - This page doesn't exist"**.

---

## 2. Recommended Hosting Platforms

Because StitchTrack is built on **Java 17 + Jakarta EE Servlets + JSP + Apache Tomcat 10 + MySQL**, it requires a platform that runs containerized or native Java environments.

The two best and easiest platforms are:
1. **Render (Recommended)** – Direct Docker deployment, free/low-cost web services.
2. **Railway** – 1-click Docker + 1-click managed MySQL database.

---

## 3. Deploying on Render (Step-by-Step)

### Option A: Using Render Web Dashboard
1. **Sign in to Render**: Go to [https://render.com](https://render.com) and log in with your GitHub account.
2. **Create Database**:
   - You can use an external MySQL database from [Aiven](https://aiven.io) (free tier), [Clever Cloud](https://www.clever-cloud.com), or [Railway](https://railway.app).
   - Alternatively, add a MySQL service on Render.
3. **Create Web Service**:
   - Click **New +** -> **Web Service**.
   - Select your GitHub repository: `abhayshekhawat12/laundryapp`.
   - **Runtime**: Choose **Docker**.
   - Render will automatically locate the `Dockerfile` in your repository.
4. **Configure Environment Variables**:
   In the **Environment Variables** section, add:
   | Key | Value | Description |
   |---|---|---|
   | `STITCHTRACK_DB_URL` | `jdbc:mysql://<host>:<port>/<dbname>?allowPublicKeyRetrieval=true&useSSL=true` | Your remote MySQL JDBC URL |
   | `STITCHTRACK_DB_USER` | `<your-db-username>` | Database username |
   | `STITCHTRACK_DB_PASSWORD` | `<your-db-password>` | Database password |
   | `CLOUDINARY_URL` | `cloudinary://<api_key>:<api_secret>@<cloud_name>` | (Optional) Cloudinary image upload key |
   
   *(Note: Alternatively, if your cloud database gives you a single URI like `mysql://user:pass@host:port/dbname`, you can just set `DATABASE_URL` or `MYSQL_URL` — our updated `DBConnection` automatically parses it!)*

5. **Deploy**:
   - Click **Create Web Service**.
   - Render will build the Maven project, create the Tomcat 10 Docker container, and start the app.
   - Your database tables and default admin/staff accounts will be **automatically created** on the first run!

---

## 4. Deploying on Railway (Step-by-Step)

1. Go to [https://railway.app](https://railway.app) and log in.
2. Click **New Project** -> **Provision MySQL**.
3. In the same project, click **New** -> **GitHub Repo** -> select `abhayshekhawat12/laundryapp`.
4. Railway will automatically detect the `Dockerfile` and build it.
5. In your Web Service settings:
   - Go to **Variables** -> Add `CLOUDINARY_URL` if you use image uploads.
   - Connect the MySQL service (Railway automatically exposes `MYSQL_URL` / `DATABASE_URL` which the application detects).
6. Under **Networking**, click **Generate Domain**.
7. Open the generated URL: Your application is live!

---

## 5. Local Running & Testing with Docker Compose

To test the entire stack (Tomcat + MySQL 8) locally with a single command:
```bash
docker compose up --build
```
Access the application at:
```
http://localhost:8080/login
```

---

## 6. Default Pre-Seeded Accounts

Once deployed, the database automatically initializes with these default accounts:

| Role | Email | Password |
|---|---|---|
| **Facility Admin** | `stitchtrackeradmin@gmail.com` | `stitchtracker56@` |
| **Laundry Staff** | `laundrystaff@stitchtrack.com` | `laundry@staff123` |
| **Student** | Self-register via `/register` | Set during registration (Admin approves) |
