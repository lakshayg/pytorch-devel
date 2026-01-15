FROM rust AS builder
RUN cargo install flamegraph && \
    cargo install addr2line --features="bin"

FROM nvcr.io/nvidia/cuda-dl-base:25.12-cuda13.1-devel-ubuntu24.04
ENV EDITOR=vim

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
ARG PERF_BUILD_DEPS="flex bison"
ARG PERF_RUNTIME_DEPS="libnuma-dev libcapstone-dev libdw-dev \
    libelf-dev libpfm4-dev libslang2-dev systemtap-sdt-dev   \
    libtraceevent-dev libdebuginfod-dev libbabeltrace-dev    "
RUN apt -y install ${PERF_BUILD_DEPS} ${PERF_RUNTIME_DEPS} && \
    git clone --single-branch --depth 1 https://github.com/torvalds/linux && \
    NO_JEVENTS=1 make -C linux/tools/perf && cp linux/tools/perf/perf /bin/ && \
    rm -rf linux && apt remove -y ${PERF_BUILD_DEPS}
COPY --from=builder /usr/local/cargo/bin/flamegraph /bin/
COPY --from=builder /usr/local/cargo/bin/addr2line  /usr/bin/
