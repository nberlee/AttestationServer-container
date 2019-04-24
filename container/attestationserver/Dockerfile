ARG OPENJDK_TAG=11-jre-slim

FROM openjdk:$OPENJDK_TAG as builder

# CHANGE THIS: it is the domain in the QR-code. It is hardcoded in the AttestationServer
ARG ATTESTATION_PUB_DOMAIN=attestation.at.home

ARG ATTESTATION_BRANCH=master
ARG ATTESTATION_COMMIT=44f18acb5aec247a8057688bea1301de0a469315

RUN apt update && apt install -y git
RUN git clone -b $ATTESTATION_BRANCH \
        --recurse-submodules \
        --shallow-submodules \
        -c advice.detachedHead=false \
        -j`nproc` \
         https://github.com/GrapheneOS/AttestationServer.git /src/AttestationServer

WORKDIR /src/AttestationServer
RUN git checkout $ATTESTATION_COMMIT

COPY patches/*.patch /src
RUN patch -p1 < /src/binding.patch
RUN sed -i "s/attestation.app/$ATTESTATION_PUB_DOMAIN/g" src/main/java/app/attestation/server/AttestationServer.java
RUN ./gradlew build

FROM openjdk:$OPENJDK_TAG

RUN apt update && \
    apt -y full-upgrade && \
    apt -y install sqlite3 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/AttestationServer/build/libs /app/
COPY --from=builder /src/AttestationServer/static /var/www/html
COPY entrypoint.sh /

RUN useradd --no-log-init -U attestation

WORKDIR /data
RUN chown -R attestation:attestation /data
USER attestation
VOLUME /data

EXPOSE 8080


ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/sh", "-c", "/usr/bin/java -cp '/app/AttestationServer.jar:/app/*' app.attestation.server.AttestationServer"]

