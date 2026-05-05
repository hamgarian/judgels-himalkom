FROM gradle:8.1.1-jdk17 AS build
WORKDIR /app
COPY . .
RUN gradle :judgels-server-app:installDist --no-daemon \
    && cp judgels-server-app/init.sh judgels-server-app/build/install/judgels-server-app/init.sh \
    && chmod +x judgels-server-app/build/install/judgels-server-app/init.sh

FROM alpine:3.21.3
RUN apk --no-cache add binutils openjdk17-jdk openjdk17-jmods
RUN /usr/lib/jvm/java-17-openjdk/bin/jlink \
    --add-modules \
        java.base,java.desktop,java.naming,java.sql,java.management,java.instrument,jdk.crypto.ec,jdk.unsupported \
    --compress 2 --strip-debug --no-header-files --no-man-pages \
    --output "/judgels/java"

FROM alpine:3.21.3
ENV JAVA_HOME=/judgels/java
ENV PATH="$PATH:$JAVA_HOME/bin"
COPY --from=1 "$JAVA_HOME" "$JAVA_HOME"
RUN addgroup -S judgels && adduser -S -g judgels judgels
RUN apk add --no-cache bash procps ttf-dejavu libjpeg-turbo-dev
RUN mkdir -p /var/judgels/data /var/judgels/log \
    && chown -R judgels:judgels /var/judgels
USER judgels
WORKDIR /judgels/server
EXPOSE 9101 9111
COPY --chown=judgels:judgels --from=0 /app/judgels-server-app/build/install/judgels-server-app .
RUN test -x ./init.sh && test -x ./bin/judgels-server-app
ENTRYPOINT ["./init.sh"]
CMD ["server"]
