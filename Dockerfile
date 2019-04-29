FROM debian:stable-slim as builder

WORKDIR /data

RUN apt-get update -qq && apt-get -y install \
        build-essential \
        cmake \
        pkg-config \
        libboost-all-dev \
        libssl-dev \
        libzmq3-dev \
        libpgm-dev \
        libunbound-dev \
        libsodium-dev \
        libunwind8-dev \
        liblzma-dev \
        libreadline6-dev \
        libldns-dev \
        libexpat1-dev \
        doxygen \
        graphviz \
        libpcsclite-dev \
        libgtest-dev \
        git \
    && cd /usr/src/gtest \
    && cmake . \
    && make \
    && mv libg* /usr/lib/

RUN git clone--single-branch --depth 1 https://github.com/ncopa/su-exec.git su-exec.git \
    && cd su-exec.git \
    && make \
    && cp su-exec /data

ARG AEON_URL=https://github.com/aeonix/aeon.git
ARG BRANCH
ARG BUILD_PATH=/aeon.git/build/release/bin

RUN cd /data \
    && git clone -b "$BRANCH" --single-branch --depth 1 --recursive $AEON_URL aeon.git
RUN cd aeon.git \
    && USE_SINGLE_BUILDDIR=1 make \
    && mv /data$BUILD_PATH/aeond /data/ \
    && chmod +x /data/aeond \
    && mv /data$BUILD_PATH/aeon-wallet-rpc /data/ \
    && chmod +x /data/aeon-wallet-rpc \
    && mv /data$BUILD_PATH/aeon-wallet-cli /data/ \
    && chmod +x /data/aeon-wallet-cli

RUN apt-get purge -y \
        build-essential \
        cmake \
        libboost-all-dev \
        libssl-dev \
        libzmq3-dev \
        libpgm-dev \
        libunbound-dev \
        libsodium-dev \
        libunwind8-dev \
        liblzma-dev \
        libreadline6-dev \
        libldns-dev \
        libexpat1-dev \
        doxygen \
        graphviz \
        libpcsclite-dev \
        libgtest-dev \
        git \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt \
    && rm -rf /data/aeon.git \
    && rm -rf /data/su-exec.git

FROM debian:stable-slim
COPY --from=builder /data/aeond /usr/local/bin/
COPY --from=builder /data/aeon-wallet-rpc /usr/local/bin/
COPY --from=builder /data/aeon-wallet-cli /usr/local/bin/
COPY --from=builder /data/su-exec /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh

RUN apt-get update && apt-get install -y \
        libboost-all-dev \
        libzmq3-dev \
        libunbound-dev \
        libexpat1-dev \
        libpcsclite-dev \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt

RUN chmod +x /entrypoint.sh \
    && rm -rf /data


WORKDIR /aeon

RUN aeond --version > /version.txt \
    && cat /etc/os-release > /system.txt \
    && ldd $(command -v aeond) > /dependencies.txt

VOLUME ["/aeon"]

ENV USER_ID 1000
ENV LOG_LEVEL 0
ENV DAEMON_HOST 127.0.0.1
ENV DAEMON_PORT 11181
ENV RPC_BIND_IP 0.0.0.0
ENV RPC_BIND_PORT 11181
ENV P2P_BIND_IP 0.0.0.0
ENV P2P_BIND_PORT 11180

ENTRYPOINT ["/entrypoint.sh"]
