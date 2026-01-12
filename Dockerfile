FROM rust AS builder
RUN DEBIAN_FRONTEND=noninteractive apt update && \
    apt install -y flex bison && \
    git clone --depth 1 https://github.com/torvalds/linux && \
    NO_LIBELF=1 NO_JEVENTS=1 NO_LIBTRACEEVENT=1 make -C linux/tools/perf && \
    cargo install flamegraph

FROM nvcr.io/nvidia/cuda-dl-base:25.12-cuda13.1-devel-ubuntu24.04
# FROM nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04
# FROM ubuntu:24.04
#
# # Install CUDA and cuDNN
# ADD https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb /root/packages/
# RUN DEBIAN_FRONTEND=noninteractive \
#     apt update && \
#     apt -y install ca-certificates && \
#     dpkg -i /root/packages/cuda-keyring_1.1-1_all.deb && \
#     apt update && apt -y install cuda-toolkit-12-9 cudnn9-cuda-12
# ENV PATH="/usr/local/cuda/bin:${PATH}" \
#     LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
#
# # Install NVSHMEM
# ADD https://developer.download.nvidia.com/compute/redist/nvshmem/3.3.20/builds/cuda12/txz/agnostic/x64/libnvshmem-linux-x86_64-3.3.20_cuda12-archive.tar.xz /root/packages/
# RUN tar -xvf /root/packages/libnvshmem-linux-x86_64-3.3.20_cuda12-archive.tar.xz -h --strip-components 1 -C /usr/local/cuda

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
