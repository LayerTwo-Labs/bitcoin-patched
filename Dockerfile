FROM debian:bookworm-slim AS builder

RUN apt-get update -y \
  && apt-get install -y ca-certificates curl git gnupg gosu python3 wget build-essential cmake pkg-config libevent-dev libboost-dev libsqlite3-dev libzmq3-dev libminiupnpc-dev libnatpmp-dev qtbase5-dev qttools5-dev qttools5-dev-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /src

# Copy source files
COPY . .

# Remove any existing build directory
RUN rm -rf build/

# Run CMake to configure the build
RUN cmake -S . -B build \
        -DDWITH_ZMQ=ON \
        -DBUILD_TESTS=OFF \
        -DBUILD_UTIL:BOOL=OFF \
        -DBUILD_TX:BOOL=OFF \
        -DBUILD_WALLET_TOOL=OFF

# Build the project
RUN cmake --build build -j

# Second stage
FROM debian:bookworm-slim

ARG UID=101
ARG GID=101

ARG TARGETPLATFORM

ENV DRIVECHAIN_DATA=/home/drivechain/.drivechain
ENV PATH=/opt/drivechain/bin:$PATH

RUN groupadd --gid ${GID} drivechain \
  && useradd --create-home --no-log-init -u ${UID} -g ${GID} drivechain \
  && apt-get update -y \
  && apt-get --no-install-recommends -y install jq curl gnupg gosu ca-certificates pkg-config libevent-dev libboost-dev libsqlite3-dev libzmq3-dev libminiupnpc-dev libnatpmp-dev qtbase5-dev qttools5-dev qttools5-dev-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /src/build/src/bitcoind /opt/drivechain/bin/drivechaind
COPY --from=builder /src/build/src/bitcoin-cli /opt/drivechain/bin/drivechain-cli

COPY --chmod=755 entrypoint.sh /entrypoint.sh

VOLUME ["/home/drivechain/.drivechain"]

# P2P network (mainnet, testnet & regnet respectively)
EXPOSE 8333 18333 18444

# RPC interface (mainnet, testnet & regnet respectively)
EXPOSE 8332 18332 18443

# ZMQ ports (for transactions & blocks respectively)
EXPOSE 28332 28333

HEALTHCHECK --interval=300s --start-period=60s --start-interval=10s --timeout=20s CMD gosu bitcoin bitcoin-cli -rpcwait -getinfo || exit 1

ENTRYPOINT ["/entrypoint.sh"]

RUN drivechaind -version | grep "Bitcoin Core version"

CMD ["drivechaind"]
