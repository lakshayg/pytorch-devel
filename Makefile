MAKEFILE_ROOT    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
RELATIVE_CURDIR  := $(shell realpath --relative-to $(MAKEFILE_ROOT) $(CURDIR))
CONTAINER_ROOT   := /root/pytorch
CONTAINER_CURDIR := $(CONTAINER_ROOT)/$(RELATIVE_CURDIR)
WORKTREE_MAIN    := $(MAKEFILE_ROOT)/1
ARCH             := $(shell arch)

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

.PHONY: torchdev
torchdev: Dockerfile
	docker build --tag torchdev --build-arg KERNEL_RELEASE=$(shell uname -r) $(MAKEFILE_ROOT)

.PHONY: start
RUNNING_CONTAINER=$(shell docker ps --filter 'ancestor=torchdev' --format '{{.Names}}')
start:
	$(if $(RUNNING_CONTAINER), \
		docker exec --workdir $(CONTAINER_CURDIR) -it $(RUNNING_CONTAINER) bash, \
		docker run --rm --gpus all -it --mount type=bind,src=$(MAKEFILE_ROOT),dst=$(CONTAINER_ROOT) --workdir $(CONTAINER_CURDIR) torchdev)

#===================================================================================

export CMAKE_SUPPRESS_DEVELOPER_WARNINGS:=ON
export CMAKE_POLICY_VERSION_MINIMUM:=3.5
export CMAKE_BUILD_TYPE:=RelWithDebInfo
export CXXFLAGS:=-Wfatal-errors
export CMAKE_CUDA_HOST_COMPILER:=$(CC)
# export CMAKE_COMPILE_WARNING_AS_ERROR:=ON
# Keep all intermediate files generated during cuda compilation
# export CMAKE_CUDA_FLAGS:=--keep
ifneq ($(ARCH),aarch64)
export CMAKE_LINKER_TYPE:=MOLD
endif

# PyTorch vars
COMPUTE_CAPS:=$(shell nvidia-smi --query-gpu=compute_cap --format=csv,noheader | sort | uniq)
export TORCH_CUDA_ARCH_LIST:=$(subst $() $(),;,$(COMPUTE_CAPS))
export USE_PRECOMPILED_HEADERS:=0
export USE_XCCL:=OFF
export USE_NUMA:=OFF
export USE_DISTRIBUTED:=1
export USE_MKLDNN:=0
# flash-attention is very expensive to build
export USE_FLASH_ATTENTION:=0
export BUILD_TEST:=1
export BUILD_BINARY:=1
export BUILD_FUNCTORCH:=ON
# export DEBUG:=1
# export VERBOSE:=1
ifeq ($(ARCH),aarch64)
export USE_PRIORITIZED_TEXT_FOR_LD:=1
endif

# Ccache
export CCACHE_DIR        := $(MAKEFILE_ROOT)/cache/ccache
export CCACHE_TEMPDIR    := $(MAKEFILE_ROOT)/tmp/ccache
export CCACHE_MAXSIZE    := 100G
export CCACHE_NOHASHDIR  := 1
export CCACHE_BASEDIR    := $(CURDIR)
export CCACHE_SLOPPINESS := pch_defines,time_macros
# export CCACHE_DEBUG      := 1

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
