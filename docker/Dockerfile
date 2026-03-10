FROM debian:bookworm-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git pkg-config ca-certificates \
        libssl-dev zlib1g-dev gperf libreadline-dev \
        libjemalloc-dev librocksdb-dev libsodium-dev \
        liblz4-dev libmicrohttpd-dev \
        autoconf automake libtool \
        lsb-release wget software-properties-common gnupg ccache && \
    rm -rf /var/lib/apt/lists/*

ARG LLVM_VERSION=20
RUN wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- ${LLVM_VERSION} && \
    rm -rf /var/lib/apt/lists/*

ENV CC=/usr/bin/clang-${LLVM_VERSION}
ENV CXX=/usr/bin/clang++-${LLVM_VERSION}

WORKDIR /src

COPY ton/ ton/
COPY third-party/ third-party/
COPY CMakeLists.txt git_watcher.cmake git.h git.cc.in suppression_mappings.txt ./
COPY CMake/ CMake/
COPY tl/ tl/
COPY cocoon-tl-utils/ cocoon-tl-utils/
COPY tdport/ tdport/
COPY tee/ tee/
COPY net/ net/
COPY runners/ runners/

ARG BUILD_TYPE=Release

RUN --mount=type=cache,target=/root/.cache/ccache \
    mkdir -p build && cd build && \
    cmake -GNinja \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DBUILD_SHARED_LIBS=OFF \
        -DTON_USE_JEMALLOC=ON \
        -DTON_USE_ABSEIL=OFF \
        -DTON_ONLY_TONLIB=ON \
        -DTON_USE_ROCKSDB=ON \
        -DPORTABLE=1 \
        .. && \
    ninja -j$(nproc) client-runner router

RUN strip --strip-unneeded /src/build/client-runner /src/build/tee/router 2>/dev/null || true

FROM debian:bookworm-slim AS router

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates dumb-init \
        libstdc++6 libgcc-s1 libatomic1 \
        libssl3 zlib1g libjemalloc2 \
        libsodium23 liblz4-1 libmicrohttpd12 && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -r -u 1000 -m -s /bin/bash cocoon

COPY --from=builder /src/build/tee/router /usr/local/bin/
COPY docker/entrypoint-router.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER cocoon
EXPOSE 8116

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]

FROM debian:bookworm-slim AS client

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
COPY docker/entrypoint-client.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    mkdir -p /data && \
    chown -R cocoon:cocoon /data

VOLUME ["/data"]
EXPOSE 10000

USER cocoon
WORKDIR /data

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:10000/jsonstats || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]
