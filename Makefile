#!/usr/bin/env -S make --no-builtin-rules --warn-undefined-variables --makefile

CONTAINER_ROOT := /home/torchdev
MAKEFILE_ROOT  := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: info
info:
	@echo $(realpath $(MAKEFILE_LIST))

.PHONY: git
git: WORKTREE_MAIN := $(MAKEFILE_ROOT)/1
git:
	git rev-parse --is-inside-work-tree 2>&1 >/dev/null || git -C $(WORKTREE_MAIN) worktree repair $(CURDIR)

.PHONY: setup
setup:
	git clone --recursive -b pytorch-build-test/1 https://github.com/lakshayg/pytorch 1
	git -C 1 worktree add ../2 pytorch-build-test/2; git -C 2 submodule update --init --recursive
	git -C 1 worktree add ../3 pytorch-build-test/3; git -C 3 submodule update --init --recursive
	git -C 1 worktree add ../4 pytorch-build-test/4; git -C 4 submodule update --init --recursive
	git -C 1 worktree add ../5 pytorch-build-test/5; git -C 5 submodule update --init --recursive

.PHONY: experiment
experiment:
	mkdir -p results/1 results/2 results/3 results/4 results/5
	# cd 1; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/1/build-1.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/1/; git clean -fdx
	cd 2; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/2/build-1.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/2/; git clean -fdx
	# cd 3; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/3/build-1.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/3/; git clean -fdx
	cd 4; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/4/build-1.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/4/; git clean -fdx
	# cd 5; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/5/build-1.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/5/; git clean -fdx
	true
	# cd 1; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/1/build-2.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/1/; git clean -fdx
	cd 2; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/2/build-2.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/2/; git clean -fdx
	# cd 3; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/3/build-2.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/3/; git clean -fdx
	cd 4; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/4/build-2.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/4/; git clean -fdx
	# cd 5; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/5/build-2.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/5/; git clean -fdx
	true
	# cd 1; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/1/build-3.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/1/; git clean -fdx
	cd 2; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/2/build-3.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/2/; git clean -fdx
	# cd 3; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/3/build-3.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/3/; git clean -fdx
	cd 4; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/4/build-3.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/4/; git clean -fdx
	# cd 5; ../Makefile build 2>&1 | tee build.txt; cp build.txt ../results/5/build-3.txt; cp build/.cmake/instrumentation/v1/data/trace/* ../results/5/; git clean -fdx

.PHONY: torchdev
torchdev: torchdev/Dockerfile
	docker build --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) --tag $@ $@

.PHONY: start
start: RELATIVE_CURDIR  := $(shell realpath --relative-to $(MAKEFILE_ROOT) $(CURDIR))
start: CONTAINER_CURDIR := $(shell realpath --canonicalize-missing "$(CONTAINER_ROOT)/$(RELATIVE_CURDIR)")
start: DOCKER_IMAGE     ?= torchdev
start: DOCKER_CONTAINER := docker_$(firstword $(shell echo -n "$(DOCKER_IMAGE)" | md5sum))
start:
	docker exec --workdir $(CONTAINER_CURDIR) -it $(DOCKER_CONTAINER) bash 2>/dev/null || \
	docker run --privileged --rm -it \
		--gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=-1 \
		--volume $(MAKEFILE_ROOT):$(CONTAINER_ROOT) \
		--workdir $(CONTAINER_CURDIR) \
		--name $(DOCKER_CONTAINER) $(DOCKER_IMAGE)

#===================================================================================

export CC:=gcc
export CXX:=g++
export CFLAGS:=-Wfatal-errors
export CXXFLAGS:=-Wfatal-errors

export CUDA_CACHE_DISABLE := 1

export CCACHE_DISABLE := 1

.PHONY: build-%
build-%: export CMAKE_SUPPRESS_DEVELOPER_WARNINGS:=ON
build-%: export CMAKE_POLICY_VERSION_MINIMUM:=3.5
build-%: export CMAKE_CUDA_HOST_COMPILER:=$(CC)
build-%: export CMAKE_BUILD_TYPE?=RelWithDebInfo
build-%: export CMAKE_GENERATOR?=Ninja
# build-%: export CMAKE_COMPILE_WARNING_AS_ERROR:=ON
# Keep all intermediate files generated during cuda compilation
# build-%: export CMAKE_CUDA_FLAGS:=--keep

build-%: export USE_CUDNN?=0
build-%: export USE_NUMA?=0
build-%: export USE_XCCL?=0
build-%: export USE_MSLK?=0
build-%: export USE_MKLDNN?=0
build-%: export USE_FBGEMM?=0
build-%: export USE_NNPACK?=0
build-%: export USE_XNNPACK?=0
build-%: export USE_DISTRIBUTED?=0
build-%: export USE_FLASH_ATTENTION?=0
build-%: export USE_MEM_EFF_ATTENTION?=0
build-%: export USE_PRECOMPILED_HEADERS?=0
build-%: export TORCH_CUDA_ARCH_LIST?=$(shell nvidia-smi --query-gpu=compute_cap --format=csv,noheader | sort -uV | xargs | tr [:blank:] ';')
build-%: export BUILD_TEST?=0
build-%: export BUILD_BINARY?=0
build-%: export BUILD_FUNCTORCH?=1
build-%: export USE_FBGEMM_GENAI?=0
build-%: export USE_SYSTEM_NCCL?=1
build-%: export CMAKE_LINKER_TYPE:=LLD
build-%: export USE_PRIORITIZED_TEXT_FOR_LD:=0

build-%: git
	uv sync --no-install-project
	uv sync --no-build-isolation --reinstall-package torch --verbose

.PHONY: build
build: build-$(shell arch)

.PHONY: lint
lint: git
	uv run --only-dev lintrunner init
	uv run --only-dev lintrunner lint --apply-patches

.PHONY: clean
clean: git
	git clean -fdx -e tags

.PHONY: tags
tags: TMPFILE:=$(shell mktemp --tmpdir rgconfig.XXXXXX)
tags:
	[ -f ".gitmodules" ] && rg -N '^\s*\bpath\b\s*=\s*' --replace '--glob=!/' .gitmodules > $(TMPFILE) || true
	RIPGREP_CONFIG_PATH=$(TMPFILE) rg --no-ignore -tc -tcpp -tcuda --files | ctags -L -
#===================================================================================

.PHONY: shell python
shell python: export TORCH_SHOW_CPP_STACKTRACES?=1
shell python: export TORCH_SYMBOLIZE_MODE?=$(word 1, fast dladdr addr2line)
# shell python: export CUDA_BINARY_LOADER_THREAD_COUNT?=8
# shell python: export CUDA_MODULE_LOADING?=$(word 1, LAZY EAGER)
# shell python: export CUDA_CACHE_DISABLE?=0

shell: export HISTFILE:=$(CONTAINER_ROOT)/cache/.torch_shell_history
shell:
	bash --rcfile $(CURDIR)/.venv/bin/activate -i

python:
	uv run --with ipython ipython -i -c "import torch"
