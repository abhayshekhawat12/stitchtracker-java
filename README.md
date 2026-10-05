# StitchTrack - Java Web Application

Java/JSP remake of the supplied StitchTrack laundry management application for a Java lab/product-based project.

## Stack
- Java 17
- Jakarta Servlet 6 / JSP
- JDBC
- MySQL 8+
- Apache Tomcat 10.1+
- Maven
- ZXing for QR generation
- HTML/CSS/JavaScript for browser UI

## Main modules implemented
- Student and Admin login with HttpSession
- Student registration with admin approval
- Student dashboard with quota and order history
- New laundry request with garment counts
- Staff acceptance + bag assignment
- Single-use pickup QR token generation
- Laundry pipeline/status updates
- QR/manual pickup verification and delivery
- Quota renewal requests
- Mismatch/complaint tickets
- Audit logs
- Basic CSV export
- PWA manifest/service worker shell

## 1) Database setup
Open MySQL Workbench and run:

`database/stitchtrack_mysql.sql`

Default database: `stitchtrack_java`

## 2) Database connection
Defaults in `DBConnection.java`:
- host: localhost:3306
- database: stitchtrack_java
- user: root
- password: root

You can override without editing source using environment variables:
- `STITCHTRACK_DB_URL`
- `STITCHTRACK_DB_USER`
- `STITCHTRACK_DB_PASSWORD`

Example URL: `jdbc:mysql://localhost:3306/stitchtrack_java?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata`

## 3) Eclipse import
1. File -> Import -> Maven -> Existing Maven Projects
2. Select this folder
3. Finish and wait for Maven dependencies
4. Add Apache Tomcat 10.1 server
5. Project -> Properties -> Targeted Runtimes -> select Tomcat
6. Run As -> Run on Server
7. Open `http://localhost:8080/stitchtrack/`

## Demo credentials
Admin:
- email: `admin@stitchtrack.local`
- password: `admin123`

Student:
- email: `student@college.edu`
- password: `student123`

## Notes
The supplied React/Supabase project used real-time subscriptions and cloud services. This Java lab version replaces the core backend with Java Servlets + JDBC + MySQL. Browser JavaScript is retained only where a browser feature is required (for example camera-based QR detection). The QR scanner page also provides a manual token fallback.
