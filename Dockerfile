FROM sonarqube:7.9.2-community


ENV SONAR_AUTH_AAD_VERSION=1.2.0 \
    SONAR_CSHARP_VERSION=8.3.0.14607

ADD https://github.com/SonarSource/sonar-dotnet/releases/download/${SONAR_CSHARP_VERSION}/sonar-csharp-plugin-${SONAR_CSHARP_VERSION}.jar .
ADD https://github.com/SonarQubeCommunity/sonar-auth-aad/releases/download/${SONAR_AUTH_AAD_VERSION}/sonar-auth-aad-plugin-${SONAR_AUTH_AAD_VERSION}.jar .

RUN mv *.jar $SONARQUBE_HOME/extensions/plugins \
    && ls -lah $SONARQUBE_HOME/extensions/plugins

# Configure Azure Web App database entrypoint
COPY entrypoint.sh ./bin/
USER root
RUN chmod +x ./bin/entrypoint.sh
USER sonarqube
ENTRYPOINT ["./bin/entrypoint.sh"]
