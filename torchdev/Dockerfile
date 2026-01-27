FROM rust AS rust-tools
RUN cargo install flamegraph && \
    cargo install addr2line --features="bin"

FROM nvcr.io/nvidia/cuda-dl-base:25.12-cuda13.1-devel-ubuntu24.04
ENV EDITOR=vim
ENV HISTFILE=/root/pytorch/cache/.bash_history

# Install uv and python
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/bin/
RUN uv python install 3.13
ENV UV_LINK_MODE=copy
ENV UV_CACHE_DIR=/root/pytorch/cache/uv

# Install and configure packages from apt
ARG TORCH_BUILD_DEPS="git ccache libssl-dev \
    mold clang-20 lldb-20 gcc-14 g++-14 gdb "
RUN DEBIAN_FRONTEND=noninteractive apt-get update &&  \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      --no-install-recommends ${TORCH_BUILD_DEPS} &&  \
    git config --global safe.directory '*'

# Install perf analysis tools
ARG LINUX_VER="6.18"
ARG LINUX_DIR="linux-${LINUX_VER}"
ARG LINUX_REMOTE_ARCHIVE="https://github.com/torvalds/linux/archive/refs/tags/v${LINUX_VER}.tar.gz"
ARG PERF_BUILD_DEPS="flex bison"
ARG PERF_RUNTIME_DEPS="libnuma-dev libcapstone-dev libdw-dev \
    libelf-dev libpfm4-dev libslang2-dev systemtap-sdt-dev   \
    libtraceevent-dev libdebuginfod-dev libbabeltrace-dev    "
RUN apt -y install ${PERF_BUILD_DEPS} ${PERF_RUNTIME_DEPS} && \
    curl -fL ${LINUX_REMOTE_ARCHIVE} | tar xzf - && \
    NO_JEVENTS=1 make -C ${LINUX_DIR}/tools/perf && \
    cp ${LINUX_DIR}/tools/perf/perf /usr/bin/ && \
    rm -rf ${LINUX_DIR} && apt remove -y ${PERF_BUILD_DEPS}
COPY --from=rust-tools /usr/local/cargo/bin/flamegraph /usr/bin/
COPY --from=rust-tools /usr/local/cargo/bin/addr2line  /usr/bin/
