#!/usr/bin/env -S make --no-builtin-rules --warn-undefined-variables --makefile

#===================================================================================

MAKEFILE_ROOT    := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
RELATIVE_CURDIR  := $(shell realpath --relative-to $(MAKEFILE_ROOT) $(CURDIR))
CONTAINER_ROOT   := /root/pytorch
CONTAINER_CURDIR := $(CONTAINER_ROOT)/$(RELATIVE_CURDIR)
WORKTREE_MAIN    := $(MAKEFILE_ROOT)/1
DOCKER_IMAGE     ?= torchdev

.PHONY: info
info:
	@echo $(realpath $(MAKEFILE_LIST))

.PHONY: git
git:
	$(if $(shell git rev-parse --is-inside-work-tree 2>/dev/null),,\
		git -C $(WORKTREE_MAIN) worktree repair $(CURDIR))

.PHONY: setup
setup:
	git clone --recursive https://github.com/pytorch/pytorch 1

.PHONY: torchdev
torchdev: $(MAKEFILE_ROOT)/torchdev/Dockerfile
	docker build --tag $@ $(dir $<)

.PHONY: start
start:
	$(or $(foreach _running_container,$(shell docker ps --filter 'ancestor=torchdev' --format '{{.Names}}'), \
		docker exec --workdir $(CONTAINER_CURDIR) -it $(_running_container) bash),                           \
		docker run --privileged --rm -it --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 --volume $(MAKEFILE_ROOT):$(CONTAINER_ROOT) --workdir $(CONTAINER_CURDIR) $(DOCKER_IMAGE))

.PHONY: edit
edit:
	$(if $(EDITOR), \
		$(EDITOR) $(MAKEFILE_LIST), \
		$(error EDITOR is not set))

#===================================================================================

export CC:=gcc-14
export CXX:=g++-14
export CXXFLAGS:=-Wfatal-errors

export CCACHE_DIR        := $(MAKEFILE_ROOT)/cache/ccache
export CCACHE_TEMPDIR    := $(MAKEFILE_ROOT)/tmp/ccache
export CCACHE_MAXSIZE    := 100G
export CCACHE_NOHASHDIR  := 1
export CCACHE_BASEDIR    := $(CURDIR)
export CCACHE_SLOPPINESS := pch_defines,time_macros

export UV_PYTHON_DOWNLOADS := never

.PHONY: build-%
build-%: export CMAKE_SUPPRESS_DEVELOPER_WARNINGS:=ON
build-%: export CMAKE_POLICY_VERSION_MINIMUM:=3.5
build-%: export CMAKE_CUDA_HOST_COMPILER:=$(CC)
build-%: export CMAKE_BUILD_TYPE?=RelWithDebInfo
build-%: export CMAKE_LINKER_TYPE:=MOLD
# build-%: export CMAKE_COMPILE_WARNING_AS_ERROR:=ON
# Keep all intermediate files generated during cuda compilation
# build-%: export CMAKE_CUDA_FLAGS:=--keep

build-%: export USE_NUMA?=0
build-%: export USE_XCCL?=0
build-%: export USE_MKLDNN?=0
build-%: export USE_FBGEMM?=0
build-%: export USE_NNPACK?=0
build-%: export USE_XNNPACK?=0
build-%: export USE_DISTRIBUTED?=0
build-%: export USE_FBGEMM_GENAI?=0
build-%: export USE_FLASH_ATTENTION?=0
build-%: export USE_MEM_EFF_ATTENTION?=0
build-%: export USE_PRECOMPILED_HEADERS?=0
build-%: export TORCH_CUDA_ARCH_LIST?=$(shell nvidia-smi --query-gpu=compute_cap --format=csv,noheader | sort -uV | xargs | tr [:blank:] ,)
build-%: export BUILD_TEST?=0
build-%: export BUILD_BINARY?=0
build-%: export BUILD_FUNCTORCH?=0

build-aarch64: export USE_PRIORITIZED_TEXT_FOR_LD?=1

build-%: git
	ccache --zero-stats
	uv sync --no-install-project
	uv sync --no-build-isolation --reinstall-package torch --verbose
	ccache --show-stats

.PHONY: build
build: build-$(shell arch)

.PHONY: lint
lint: git
	uv run --only-dev lintrunner init
	uv run --only-dev lintrunner lint --apply-patches

.PHONY: clean
clean: git
	git clean -fdx -e tags

#===================================================================================

.PHONY: shell python
shell python: export TORCH_SHOW_CPP_STACKTRACES?=1
shell python: export TORCH_SYMBOLIZE_MODE?=$(word 1, fast dladdr addr2line)
# shell python: export CUDA_BINARY_LOADER_THREAD_COUNT?=8
# shell python: export CUDA_MODULE_LOADING?=$(word 1, LAZY EAGER)
# shell python: export CUDA_CACHE_DISABLE?=0

shell:
	@PS1="(pytorch) \w: " bash --norc -i

python:
	uv run --with ipython ipython -i -c "import torch"
