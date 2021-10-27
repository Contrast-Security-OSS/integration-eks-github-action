FROM openjdk:8-slim

ARG APP_VERSION=1.5.1

ENV APP_VERSION ${APP_VERSION}

RUN mkdir -p /opt/app

ADD spring-petclinic-$APP_VERSION.jar /opt/app

ENTRYPOINT java -Dserver.port=9999 -jar /opt/app/spring-petclinic-$APP_VERSION.jar

EXPOSE 9999
