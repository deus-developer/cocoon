FROM debian:bookworm-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git pkg-config ca-certificates \
        libssl-dev zlib1g-dev gperf libreadline-dev \
        libjemalloc-dev librocksdb-dev libsodium-dev \
        liblz4-dev libmicrohttpd-dev \
        autoconf automake libtool \
        lsb-release wget software-properties-common gnupg && \
    rm -rf /var/lib/apt/lists/*

ARG LLVM_VERSION=20
RUN wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- ${LLVM_VERSION} && \
    rm -rf /var/lib/apt/lists/*

ENV CC=/usr/bin/clang-20
ENV CXX=/usr/bin/clang++-20

WORKDIR /src
COPY . .

ARG BUILD_TYPE=Release

RUN mkdir -p build && cd build && \
    cmake -GNinja \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DBUILD_SHARED_LIBS=OFF \
        -DTON_USE_JEMALLOC=ON \
        -DTON_USE_ABSEIL=OFF \
        -DTON_ONLY_TONLIB=ON \
        -DTON_USE_ROCKSDB=ON \
        -DPORTABLE=1 \
        -DTON_ARCH= \
        .. && \
    ninja client-runner router

RUN strip --strip-unneeded /src/build/client-runner /src/build/tee/router 2>/dev/null || true

FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl jq dumb-init \
        libstdc++6 libgcc-s1 libatomic1 \
        libssl3 zlib1g libjemalloc2 librocksdb7.8 \
        libsodium23 liblz4-1 libmicrohttpd12 && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -r -u 1000 -m -s /bin/bash cocoon

COPY --from=builder /src/build/client-runner /usr/local/bin/
COPY --from=builder /src/build/tee/router /usr/local/bin/
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    mkdir -p /data && \
    chown -R cocoon:cocoon /data

VOLUME ["/data"]

ENV COCOON_OWNER_ADDRESS="" \
    COCOON_NODE_WALLET_KEY="" \
    COCOON_VERBOSITY=3 \
    COCOON_PROXY_CONNECTIONS=1 \
    COCOON_HTTP_ACCESS_HASH=""

EXPOSE 10000

USER cocoon
WORKDIR /data

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:10000/jsonstats || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]
