FROM debian:stable-slim as builder


WORKDIR /data

# libpcsclite1 as dependency for monero since 0.12.0.0/0.12.2.0
RUN apt-get update && apt-get install -y \
        bzip2 \
        curl \
        git \
        cmake \
    && curl -L https://github.com/aeonix/aeon/releases/download/v0.12.6.0-aeon/aeon-linux-x64-v0.12.6.0.tar.bz2 -O \
    && tar -xjvf aeon-linux-x64-v0.12.6.0.tar.bz2 \
    && rm aeon-linux-x64-v0.12.6.0.tar.bz2 \
    && mv ./aeon-v-0.12.6.0/aeond /data/ \
    && chmod +x /data/aeond \
    && mv ./aeon-v-0.12.6.0/aeon-wallet-rpc /data/ \
    && chmod +x /data/aeon-wallet-rpc \
    && mv ./aeon-v-0.12.6.0/aeon-wallet-cli /data/ \
    && chmod +x /data/aeon-wallet-cli

RUN git clone https://github.com/ncopa/su-exec.git su-exec-clone \
    && cd su-exec-clone && make && cp su-exec /data \
    && apt-get purge -y \
        curl \
        bzip2 \
        git \
        cmake \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt \
    && rm -rf /aeon \
    && rm -rf su-exec-clone

FROM debian:stable-slim
COPY --from=builder /data/aeond /usr/local/bin/
COPY --from=builder /data/aeon-wallet-rpc /usr/local/bin/
COPY --from=builder /data/aeon-wallet-cli /usr/local/bin/
COPY --from=builder /data/su-exec /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh

RUN apt-get update && apt-get install -y \
        libpcsclite1 \
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
