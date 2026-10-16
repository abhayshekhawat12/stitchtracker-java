# =====================================================================
# StitchTrack Tomcat 10 Start Script
# =====================================================================

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
$env:JRE_HOME  = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"

$tomcatBin = "C:\Users\abhay\Downloads\tomcat-10.1.36-windows-x64\apache-tomcat-10.1.36\bin"
Push-Location $tomcatBin
& .\catalina.bat start
Pop-Location

Write-Host "Tomcat server starting on http://localhost:8080/stitchtrack" -ForegroundColor Green
