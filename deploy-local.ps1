# =====================================================================
# StitchTrack Local Build & Deployment Script for Tomcat 10
# =====================================================================

$ErrorActionPreference = "Stop"

$workspaceRoot = "C:\Users\abhay\Downloads\StitchTrack-Java\StitchTrack-Java"
$tomcatHome    = "C:\Users\abhay\Downloads\tomcat-10.1.36-windows-x64\apache-tomcat-10.1.36"
$jdkBin        = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin"
$javac         = Join-Path $jdkBin "javac.exe"
$jar           = Join-Path $jdkBin "jar.exe"

Write-Host "=== [1/5] Cleaning and preparing build folders ===" -ForegroundColor Cyan
$buildDir = Join-Path $workspaceRoot "build"
$classesDir = Join-Path $buildDir "classes"
$stageDir = Join-Path $buildDir "stage\stitchtrack"

if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
New-Item -ItemType Directory -Force -Path $classesDir | Out-Null
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

Write-Host "=== [2/5] Compiling Java source files ===" -ForegroundColor Cyan
$cp = "$tomcatHome\lib\*;$workspaceRoot\src\main\webapp\WEB-INF\lib\*"
$sources = Get-ChildItem -Path "$workspaceRoot\src\main\java" -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
& $javac -encoding UTF-8 -cp $cp -d $classesDir $sources
if ($LASTEXITCODE -ne 0) {
    Write-Error "Java compilation failed!"
}

Write-Host "=== [3/5] Assembling Webapp Stage ===" -ForegroundColor Cyan
Copy-Item -Path "$workspaceRoot\src\main\webapp\*" -Destination $stageDir -Recurse -Force
New-Item -ItemType Directory -Force -Path "$stageDir\WEB-INF\classes" | Out-Null
Copy-Item -Path "$classesDir\*" -Destination "$stageDir\WEB-INF\classes" -Recurse -Force
Copy-Item -Path "$workspaceRoot\src\main\resources\*" -Destination "$stageDir\WEB-INF\classes" -Recurse -Force

# Create target dir and war file
New-Item -ItemType Directory -Force -Path "$workspaceRoot\target" | Out-Null
$warFile = "$workspaceRoot\target\stitchtrack.war"
if (Test-Path $warFile) { Remove-Item -Force $warFile }
Push-Location $stageDir
& $jar -cvf $warFile * | Out-Null
Pop-Location
Write-Host "WAR generated at: $warFile" -ForegroundColor Green

Write-Host "=== [4/5] Deploying to Apache Tomcat 10 ===" -ForegroundColor Cyan
$targetWebapp = Join-Path $tomcatHome "webapps\stitchtrack"
$targetWebappWar = Join-Path $tomcatHome "webapps\stitchtrack.war"

# Clean prior deployed folder/war
if (Test-Path $targetWebapp) { Remove-Item -Recurse -Force $targetWebapp }
if (Test-Path $targetWebappWar) { Remove-Item -Force $targetWebappWar }

# Copy war to Tomcat webapps
Copy-Item -Path $warFile -Destination $targetWebappWar -Force
# Also copy exploded directory directly for instantaneous pickup without unzipping delay
Copy-Item -Path $stageDir -Destination $targetWebapp -Recurse -Force

Write-Host "Successfully deployed to $targetWebapp and $targetWebappWar" -ForegroundColor Green
Write-Host "=== [5/5] Deployment Complete ===" -ForegroundColor Cyan
