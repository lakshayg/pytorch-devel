FROM rust AS builder
RUN DEBIAN_FRONTEND=noninteractive apt update && apt install -y flex bison && \
    git clone --single-branch --depth 1 https://github.com/torvalds/linux && \
    NO_LIBELF=1 NO_JEVENTS=1 NO_LIBTRACEEVENT=1 make -C linux/tools/perf && \
    cargo install flamegraph

FROM nvcr.io/nvidia/cuda-dl-base:25.12-cuda13.1-devel-ubuntu24.04

# Install uv and python
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
RUN uv python install 3.13
ENV UV_LINK_MODE=copy                            \
    UV_CACHE_DIR=/root/pytorch/cache/uv

# Install and configure packages from apt
RUN DEBIAN_FRONTEND=noninteractive apt update && \
    apt -y install clang lldb gcc-14 g++-14 gdb && \
    apt -y install git mold ccache libssl-dev && \
    git config --global safe.directory '*'

# Install perf analysis tools
COPY --from=builder /linux/tools/perf/perf /usr/local/cargo/bin/flamegraph /bin/
