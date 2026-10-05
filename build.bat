@echo off
set JAVAC="C:\Users\abhay\Downloads\StitchTrack-Java\StitchTrack-Java\jdk-17.0.2\bin\javac.exe"
set CP="target\stitchtrack\WEB-INF\lib\*;apache-tomcat-10.1.18\lib\*;src\main\webapp\WEB-INF\classes"
%JAVAC% -encoding UTF-8 -cp %CP% -d src\main\webapp\WEB-INF\classes src\main\java\com\stitchtrack\model\*.java src\main\java\com\stitchtrack\config\*.java src\main\java\com\stitchtrack\dao\*.java src\main\java\com\stitchtrack\util\*.java src\main\java\com\stitchtrack\filter\*.java src\main\java\com\stitchtrack\controller\*.java
echo Done.
