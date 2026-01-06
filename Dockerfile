FROM tomcat:9.0-jdk17

RUN rm -rf /usr/local/tomcat/webapps/*

COPY target/hello-java-k8.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

