# Build cryptoki-bridge
FROM debian:trixie AS cryptoki-bridge-builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade
RUN apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    clang \
    pkg-config \
    libssl-dev \
    protobuf-compiler
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /build
RUN git clone --recursive -b openssl-integration https://github.com/MarekMracna/cryptoki-bridge.git
WORKDIR /build/cryptoki-bridge
RUN cargo build --release

# Use a clean container for running
FROM debian:trixie AS runner
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade
RUN apt-get install -y --no-install-recommends \
    openssl \
    pkcs11-provider \
    patch \
    opensc

COPY --from=cryptoki-bridge-builder /build/cryptoki-bridge/target/release/libcryptoki_bridge.so /workspace/libcryptoki_bridge.so

ENV COMMUNICATOR_HOSTNAME=meesign.local
ENV COMMUNICATOR_CERTIFICATE_PATH=/workspace/ca-cert.pem
COPY ./ca-cert.pem /workspace/ca-cert.pem
COPY ./openssl.cnf.patch /workspace/openssl.cnf.patch

WORKDIR /workspace
RUN patch /etc/ssl/openssl.cnf < openssl.cnf.patch

CMD ["/bin/bash"]
