# Stage 1: Build the application using Maven
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
# Build the WAR file, skip tests for faster deployment
RUN mvn clean package -DskipTests

# Stage 2: Run the application on Tomcat 10
FROM tomcat:10.1-jdk17
# Remove the default ROOT application
RUN rm -rf /usr/local/tomcat/webapps/ROOT
# Copy the compiled WAR file from the build stage to Tomcat's webapps directory as ROOT.war
COPY --from=build /app/target/stitchtrack.war /usr/local/tomcat/webapps/ROOT.war

# Expose port 8080 (Render expects web services to listen on a port, Tomcat defaults to 8080)
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
