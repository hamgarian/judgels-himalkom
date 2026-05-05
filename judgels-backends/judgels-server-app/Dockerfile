FROM gradle:8.1.1-jdk17-alpine AS build
WORKDIR /app
COPY . .
RUN gradle :judgels-server-app:distTar --no-daemon

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
USER judgels
WORKDIR /judgels/server
EXPOSE 9101 9111
COPY --from=0 /app/judgels-server-app/build/distributions .
ENTRYPOINT ["./init.sh"]
CMD ["server"]