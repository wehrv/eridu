# Eridu

Multi-language Docker build image with Go, Python, Rust, and Node.js (LTS). Used as a `FROM` base stage for compiling projects. Rebuilt daily via cron.

## Files

- `Dockerfile` — 5-stage build (go, python, rust, node, final)
- `.launch.sh` — Build script with automatic version detection from upstream APIs
- `docker-compose.yml` — Build-only compose service

## Build

```bash
# Automatic version detection + build
./.launch.sh

# Manual (versions passed as build args)
docker-compose build --build-arg GO_VERSION=go1.25.7 ...
```

## Image

- **Name**: `infra-eridu:latest`
- **Base**: Ubuntu latest
- **Size**: ~2.5 GB
- **No running container** — build image only

## Dockerfile Architecture

5-stage multi-stage build for isolation and caching:

| Stage | Base | Source | Install Path |
|-------|------|--------|-------------|
| Go | ubuntu | `go.dev/dl/` binary | `/usr/local/go` |
| Python | ubuntu | `python.org/ftp` (compiled from source) | `/opt/python` |
| Rust | ubuntu | rustup installer | `/opt/rust` |
| Node | ubuntu | `nodejs.org/dist/` binary | `/opt/node` |
| Final | ubuntu | Copies from above + installs tools | — |

## Version Detection (.launch.sh)

Queries upstream APIs for latest stable versions:

| Language | API Source |
|----------|-----------|
| Go | `go.dev/dl/?mode=json` |
| Python | `endoflife.date/api/python.json` |
| Rust | `static.rust-lang.org/dist/channel-rust-stable.toml` |
| Node | `nodejs.org/dist/index.json` (first LTS entry) |

Versions passed as `ARG` to docker-compose build. Only rebuilds when a version changes.

## Included Tools

**Languages**: Go, Python 3, Rust, Node.js LTS

**Compilers/Linkers**: gcc, g++, clang, lld

**Debuggers**: gdb, lldb, dlv (Go delve), strace, valgrind

**Build Systems**: cmake, autoconf, automake, libtool, pkg-config

**Utilities**: git, curl, unzip, protobuf-compiler, jq

**Libraries**: libssl-dev, zlib1g-dev, libffi-dev

## Environment Variables

```
GOPATH=/go
RUSTUP_HOME=/opt/rust/rustup
CARGO_HOME=/opt/rust/cargo
PATH=/usr/local/go/bin:/go/bin:/opt/python/bin:/opt/rust/cargo/bin:/opt/node/bin:$PATH
```

## Usage in Dockerfiles

```dockerfile
FROM eridu:latest AS build
WORKDIR /src
ENV GOPROXY=http://host.docker.internal:3000|direct
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /myapp ./cmd/myapp

FROM ubuntu:24.04
COPY --from=build /myapp /usr/local/bin/myapp
ENTRYPOINT ["myapp"]
```

Currently used by: `primal-noknok`
