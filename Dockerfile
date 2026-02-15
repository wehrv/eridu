# ---- Go ----
FROM ubuntu:latest AS go
ARG GO_VERSION
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-${TARGETARCH}.tar.gz" | tar -C /usr/local -xz \
    && /usr/local/go/bin/go version

# ---- Python ----
FROM ubuntu:latest AS python
ARG PYTHON_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl \
    zlib1g-dev libncurses-dev libgdbm-dev libnss3-dev \
    libssl-dev libreadline-dev libffi-dev libsqlite3-dev \
    libbz2-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" | tar -C /tmp -xz \
    && cd /tmp/Python-${PYTHON_VERSION} \
    && ./configure --prefix=/opt/python \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/Python-${PYTHON_VERSION} \
    && /opt/python/bin/python3 --version
RUN ln -s python3 /opt/python/bin/python \
    && ln -s pip3 /opt/python/bin/pip

# ---- Rust ----
FROM ubuntu:latest AS rust
ARG RUST_VERSION
ENV RUSTUP_HOME=/opt/rust/rustup
ENV CARGO_HOME=/opt/rust/cargo
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gcc \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://sh.rustup.rs | sh -s -- -y --default-toolchain "${RUST_VERSION}" --profile minimal \
    && /opt/rust/cargo/bin/rustc --version

# ---- Node ----
FROM ubuntu:latest AS node
ARG NODE_VERSION
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && ARCH=$([ "$TARGETARCH" = "amd64" ] && echo "x64" || echo "$TARGETARCH") \
    && mkdir -p /opt/node \
    && curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${ARCH}.tar.xz" | tar -C /opt/node -xJ --strip-components=1 \
    && /opt/node/bin/node --version

# ---- Final ----
FROM ubuntu:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip \
    build-essential pkg-config cmake \
    autoconf automake libtool \
    clang lld lldb \
    gdb strace valgrind \
    protobuf-compiler jq \
    libssl-dev zlib1g-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=go /usr/local/go /usr/local/go
COPY --from=python /opt/python /opt/python
COPY --from=rust /opt/rust /opt/rust
COPY --from=node /opt/node /opt/node

ENV GOPATH="/go"
ENV RUSTUP_HOME="/opt/rust/rustup"
ENV CARGO_HOME="/opt/rust/cargo"
ENV PATH="/usr/local/go/bin:${GOPATH}/bin:/opt/python/bin:/opt/rust/cargo/bin:/opt/node/bin:${PATH}"

RUN go install github.com/go-delve/delve/cmd/dlv@latest
RUN npm install -g pnpm

RUN go version && python3 --version && rustc --version && node --version && dlv version && pnpm --version
