FROM gradle:8.1.1-jdk17 AS gradle-build
WORKDIR /app
COPY . .
RUN gradle :judgels-grader-app:installDist --no-daemon \
    && cp judgels-grader-app/init.sh judgels-grader-app/build/install/judgels-grader-app/init.sh \
    && chmod +x judgels-grader-app/build/install/judgels-grader-app/init.sh

FROM ubuntu:24.04 AS isolate-build
RUN apt-get update \
    && apt-get install -y git make gcc libcap-dev
ENV ISOLATE_VERSION v1.10.1
RUN git clone --branch $ISOLATE_VERSION --depth 1 https://github.com/ioi/isolate; \
    cd isolate; \
    make install
RUN git clone --depth 1 git://git.ucw.cz/moe.git; \
    cd moe/eval; \
    gcc -o iwrapper iwrapper.c

FROM ubuntu:24.04
ENV CARGO_HOME /usr
ENV RUSTUP_HOME /usr
ENV XDG_CACHE_HOME /tmp
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk
ENV PATH $JAVA_HOME/bin:$PATH
RUN apt-get update \
    && apt-get -y --no-install-recommends install software-properties-common gpg-agent \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get -y --no-install-recommends install \
       curl \
       openssh-client \
       rsync \
    && apt-get -y --no-install-recommends install \
       fp-compiler \
       g++-13 \
       golang \
       libcap-dev \
       openjdk-17-jdk-headless \
       openjdk-17-jre \
       pypy3 \
       python3 \
    && ln -s /usr/lib/jvm/java-17-openjdk-$(dpkg --print-architecture) $JAVA_HOME \
    && ln -s /usr/bin/gcc-13 /usr/bin/gcc \
    && ln -s /usr/bin/g++-13 /usr/bin/g++ \
    && curl -sSf https://sh.rustup.rs/ | bash -s -- -y -q --default-toolchain=1.57.0 \
    && test -x "$JAVA_HOME/bin/java" \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /judgels/grader
ARG VCS_REF
LABEL org.opencontainers.image.title judgels/grader
LABEL org.opencontainers.image.source https://github.com/ia-toki/judgels
LABEL org.opencontainers.image.revision $VCS_REF
COPY --from=isolate-build /isolate/isolate /judgels/isolate/bin/
COPY --from=isolate-build /usr/local/etc/isolate /usr/local/etc/
COPY --from=isolate-build /moe/eval/iwrapper /judgels/isolate/bin/
COPY --from=gradle-build /app/judgels-grader-app/build/install/judgels-grader-app .
RUN test -x ./init.sh && test -x ./bin/judgels-grader-app
ENTRYPOINT ["./init.sh"]
CMD ["server"]
