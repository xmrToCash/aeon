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

RUN git clone https://github.com/ncopa/su-exec.git su-exec-clone \
    && cd su-exec-clone \
    && make \
    && cp su-exec /data

ARG AEON_URL=https://github.com/aeonix/aeon.git
ARG BRANCH=master
ARG BUILD_PATH=/aeon/build/release/bin

RUN cd /data \
    && git clone -b "$BRANCH" --single-branch --depth 1 --recursive $AEON_URL
RUN cd aeon \
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
    && rm -rf /data/aeon \
    && rm -rf /data/su-exec-clone

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
VOLUME ["/aeon"]

ENV USER_ID 1000
ENV LOG_LEVEL 0
ENV RPC_BIND_IP 0.0.0.0
ENV RPC_BIND_PORT 18081
ENV P2P_BIND_IP 0.0.0.0
ENV P2P_BIND_PORT 18080

ENTRYPOINT ["/entrypoint.sh"]
