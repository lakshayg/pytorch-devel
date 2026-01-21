#!/usr/bin/env -S make -f

MAKEFILE_ROOT    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
RELATIVE_CURDIR  := $(shell realpath --relative-to $(MAKEFILE_ROOT) $(CURDIR))
CONTAINER_ROOT   := /root/pytorch
CONTAINER_CURDIR := $(CONTAINER_ROOT)/$(RELATIVE_CURDIR)
WORKTREE_MAIN    := $(MAKEFILE_ROOT)/1
ARCH             := $(shell arch)
DOCKER_IMAGE     ?= torchdev

#===================================================================================

.PHONY: info
info:
	$(info This is Lakshay's PyTorch Recipe File)
	$(info =====================================)
	$(info TORCH_CUDA_ARCH_LIST=$(TORCH_CUDA_ARCH_LIST))
	$(info ARCH=$(ARCH))
	$(info =====================================)

.PHONY: git
git:
	git -C $(WORKTREE_MAIN) worktree repair $(CURDIR)

.PHONY: setup
setup:
	git clone --recursive https://github.com/pytorch/pytorch 1

.PHONY: torchdev
torchdev: Dockerfile
	docker build --tag torchdev $(MAKEFILE_ROOT)

.PHONY: start
RUNNING_CONTAINER=$(shell docker ps --filter 'ancestor=torchdev' --format '{{.Names}}')
start:
	$(if $(RUNNING_CONTAINER), \
		docker exec --workdir $(CONTAINER_CURDIR) -it $(RUNNING_CONTAINER) bash, \
		docker run --privileged --rm --gpus all -it --mount type=bind,src=$(MAKEFILE_ROOT),dst=$(CONTAINER_ROOT) --workdir $(CONTAINER_CURDIR) $(DOCKER_IMAGE))

.PHONY: edit
edit:
	$(if $(EDITOR), \
		$(EDITOR) $(MAKEFILE_LIST), \
        $(error EDITOR is not set))

#===================================================================================

export CC:=gcc-14
export CXX:=g++-14
export CXXFLAGS:=-Wfatal-errors

export CMAKE_SUPPRESS_DEVELOPER_WARNINGS:=ON
export CMAKE_POLICY_VERSION_MINIMUM:=3.5
export CMAKE_CUDA_HOST_COMPILER:=$(CC)
export CMAKE_BUILD_TYPE?=RelWithDebInfo
# export CMAKE_COMPILE_WARNING_AS_ERROR:=ON
# Keep all intermediate files generated during cuda compilation
# export CMAKE_CUDA_FLAGS:=--keep
ifneq ($(ARCH),aarch64)
export CMAKE_LINKER_TYPE:=MOLD
endif

# PyTorch vars
export USE_NUMA?=0
export USE_XCCL?=0
export USE_MKLDNN?=0
export USE_FBGEMM?=0
export USE_NNPACK?=0
export USE_XNNPACK?=0
export USE_DISTRIBUTED?=0
export USE_FBGEMM_GENAI?=0
export USE_FLASH_ATTENTION?=0
export USE_MEM_EFF_ATTENTION?=0
export USE_PRECOMPILED_HEADERS?=0
ifeq ($(ARCH),aarch64)
export USE_PRIORITIZED_TEXT_FOR_LD?=1
endif

export BUILD_TEST?=0
export BUILD_BINARY?=0
export BUILD_FUNCTORCH?=0
# export DEBUG:=1
# export VERBOSE:=1

COMPUTE_CAPS:=$(shell nvidia-smi --query-gpu=compute_cap --format=csv,noheader | sort | uniq)
export TORCH_CUDA_ARCH_LIST?=$(subst $() $(),;,$(COMPUTE_CAPS))
export TORCH_SHOW_CPP_STACKTRACES?=1
export TORCH_SYMBOLIZE_MODE?=fast
# export TORCH_SYMBOLIZE_MODE:=dladdr
# export TORCH_SYMBOLIZE_MODE:=addr2line

# Ccache
export CCACHE_DIR        := $(MAKEFILE_ROOT)/cache/ccache
export CCACHE_TEMPDIR    := $(MAKEFILE_ROOT)/tmp/ccache
export CCACHE_MAXSIZE    := 100G
export CCACHE_NOHASHDIR  := 1
export CCACHE_BASEDIR    := $(CURDIR)
export CCACHE_SLOPPINESS := pch_defines,time_macros
# export CCACHE_DEBUG      := 1

# uv
export UV_PYTHON_DOWNLOADS := never

# CUDA Runtime
export CUDA_BINARY_LOADER_THREAD_COUNT?=8

# Runtime configuration
# export MAX_JOBS ?= $(shell nproc)
# export CMAKE_FRESH:=1

.PHONY: build
build: git
	ccache --zero-stats
	uv sync --no-install-project
	uv sync --no-build-isolation --reinstall-package torch --verbose
	ccache --show-stats

.PHONY: lint
lint: git
	uv run --only-dev lintrunner init
	uv run --only-dev lintrunner lint --apply-patches

.PHONY: clean
clean:
	rm -rf .venv/ build/

.PHONY: python
python:
	uv run python
