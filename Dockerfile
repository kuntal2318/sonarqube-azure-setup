FROM sonarqube:7.9.2-community

ENV SONAR_KOTLIN_COMMUNITY_VERSION=0.5.0 

RUN wget "https://github.com/arturbosch/sonar-kotlin/releases/download/$SONAR_KOTLIN_COMMUNITY_VERSION/sonar-kotlin-$SONAR_KOTLIN_COMMUNITY_VERSION.jar" \
    && mv *.jar $SONARQUBE_HOME/extensions/plugins \
    && ls -lah $SONARQUBE_HOME/extensions/plugins

# Configure Azure Web App database entrypoint
COPY entrypoint.sh ./bin/
RUN chmod +x ./bin/entrypoint.sh
ENTRYPOINT ["./bin/entrypoint.sh"]
