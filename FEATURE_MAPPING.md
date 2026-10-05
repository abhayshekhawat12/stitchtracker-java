# Existing StitchTrack -> Java StitchTrack Mapping

| Existing React/Supabase Feature | Java Version |
|---|---|
| React student dashboard | JSP student dashboard |
| React admin command center | JSP admin dashboard |
| Supabase authentication | Java Servlet + HttpSession + BCrypt |
| Supabase PostgreSQL | MySQL + JDBC DAO layer |
| Student registration & approval | RegisterServlet + Admin verification |
| Laundry request | LaundryCreateServlet + laundry_orders/laundry_items |
| Bag assignment | Admin action + active-bag validation |
| Single-use pickup QR | ZXing QRServlet + token state in MySQL |
| QR checkout | PickupScannerServlet + camera/manual token input |
| Laundry pipeline | Java status transitions |
| Semester quota | users.membership_limit / membership_used |
| Renewal requests | renewal_requests table + approval flow |
| Mismatch/complaints | complaints table + student/admin flow |
| Audit log | audit_logs table + Java logging |
| CSV reporting | ExportCsvServlet |
| PWA shell | manifest.json + service worker |
| Supabase realtime | Not required for core lab build; normal request/refresh flow |
| Google Sheets sync | Not included in this lab-ready core version |
| Web Push | Not included in this lab-ready core version |
