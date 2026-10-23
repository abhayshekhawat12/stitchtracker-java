# Stage 1: Build the application using Maven
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
# Build the WAR file, skipping unit tests for fast, deterministic build
RUN mvn clean package -DskipTests

# Stage 2: Run the application on Apache Tomcat 10
FROM tomcat:10.1-jdk17

# Configure JVM memory limits for Render free tier (512MB RAM cap)
ENV JAVA_OPTS="-Xms128m -Xmx384m -XX:+UseG1GC"

# Remove all default Tomcat webapps to prevent conflicts and reduce memory footprint
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the compiled WAR file from the build stage to Tomcat's webapps directory as ROOT.war
COPY --from=build /app/target/stitchtrack.war /usr/local/tomcat/webapps/ROOT.war

# Expose port 8080 (fallback)
EXPOSE 8080

# Adapt Tomcat to listen on Render's dynamic $PORT and disable shutdown port 8005 so Render only sees HTTP
CMD ["sh", "-c", "sed -i 's/<Server port=\"8005\"/<Server port=\"-1\"/g' /usr/local/tomcat/conf/server.xml && sed -i \"s/port=\\\"8080\\\"/port=\\\"${PORT:-8080}\\\"/g\" /usr/local/tomcat/conf/server.xml && catalina.sh run"]
