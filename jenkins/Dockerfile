FROM jenkins/jenkins:alpine

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

COPY admin.groovy /usr/share/jenkins/ref/init.groovy.d/admin.groovy
 
COPY plugins /usr/share/jenkins/ref/plugins
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins
