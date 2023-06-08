ARG DEPLOY_BUILDER_VERSION
ARG DEPLOY_RUNTIME_VERSION
ARG MAVENVER=$DEPLOY_BUILDER_VERSION
ARG TOMCATVER=$DEPLOY_RUNTIME_VERSION

FROM maven:$MAVENVER as build
RUN mkdir -p /app
ADD ./app /app
RUN cd /app \
    && mvn package -X -e -Dmaven.test.skip=false \
    && WARNAME=$(cat ./pom.xml | grep 'finalName' | cut -d'>' -f2 | cut -d'<' -f1) \
    && mv "./target/$WARNAME.war" ./target/ROOT.war

FROM tomcat:$TOMCATVER
USER root
RUN rm -rf ./webapps/ROOT/
COPY --from=build /app/target/ROOT.war ./webapps/ROOT.war
RUN chown tomcat:tomcat ./webapps/ROOT.war \
    && chown tomcat:tomcat ./webapps \
    && echo "autoDeploy=true" >> ./conf/catalina.properties \
    && echo "deployOnStartup=true" >> ./conf/catalina.properties \
    && echo "addDefaultWebXmlToWebapp=false" >> ./conf/catalina.properties \
    && echo "alwaysAddWelcomeFiles=false" >> ./conf/catalina.properties

#USER tomcat
CMD ["catalina.sh", "run"]
