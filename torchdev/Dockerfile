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
ARG GCC_PKGS="gcc-14 g++-14 gdb"
ARG CLANG_PKGS="clang-20 lldb-20"
ARG TORCH_BUILD_DEPS="git mold ccache libssl-dev libopenblas-dev"
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${GCC_PKGS} ${CLANG_PKGS} ${TORCH_BUILD_DEPS} && \
    update-alternatives --install /usr/bin/cc        cc        $(which gcc-14)   1   && \
    update-alternatives --install /usr/bin/c++       c++       $(which g++-14)   1   && \
    update-alternatives --install /usr/bin/gcc       gcc       $(which gcc-14)   1      \
                        --slave   /usr/bin/g++       g++       $(which g++-14)       && \
    update-alternatives --install /usr/bin/clang     clang     $(which clang-20) 1      \
                        --slave   /usr/bin/clang++   clang++   $(which clang++-20)      \
                        --slave   /usr/bin/lldb      lldb      $(which lldb-20)         \
                        --slave   /usr/bin/clang-cpp clang-cpp $(which clang-cpp-20) && \
    git config --global safe.directory '*'

# Install perf analysis tools
ARG LINUX_VER="6.18"
ARG LINUX_DIR="linux-${LINUX_VER}"
ARG LINUX_REMOTE_ARCHIVE="https://github.com/torvalds/linux/archive/refs/tags/v${LINUX_VER}.tar.gz"
ARG PERF_BUILD_DEPS="flex bison"
ARG PERF_RUNTIME_DEPS="libnuma-dev libcapstone-dev libdw-dev \
    libelf-dev libpfm4-dev libslang2-dev systemtap-sdt-dev   \
    libtraceevent-dev libdebuginfod-dev libbabeltrace-dev    "
RUN apt-get install -y --no-install-recommends ${PERF_BUILD_DEPS} ${PERF_RUNTIME_DEPS} && \
    curl -fL ${LINUX_REMOTE_ARCHIVE} | tar xzf - && \
    NO_JEVENTS=1 make -C ${LINUX_DIR}/tools/perf && \
    cp ${LINUX_DIR}/tools/perf/perf /usr/bin/ && \
    rm -rf ${LINUX_DIR} && apt remove -y ${PERF_BUILD_DEPS}
COPY --from=rust-tools /usr/local/cargo/bin/flamegraph /usr/bin/
COPY --from=rust-tools /usr/local/cargo/bin/addr2line  /usr/bin/
