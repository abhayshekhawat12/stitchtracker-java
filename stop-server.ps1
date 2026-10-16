# =====================================================================
# StitchTrack Tomcat 10 Stop Script
# =====================================================================

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
$env:JRE_HOME  = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"

$tomcatBin = "C:\Users\abhay\Downloads\tomcat-10.1.36-windows-x64\apache-tomcat-10.1.36\bin"
Push-Location $tomcatBin
& .\catalina.bat stop
Pop-Location

Write-Host "Tomcat server stopped." -ForegroundColor Yellow
