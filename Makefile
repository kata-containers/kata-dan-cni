# Copyright (c) 2026 Kata Containers community
#
# SPDX-License-Identifier: Apache-2.0

LIBC ?= gnu

BUILD_TYPE ?= release
HOST_ARCH = $(shell uname -m)
ARCH ?= $(HOST_ARCH)

ifneq ($(LIBC),musl)
    ifeq ($(LIBC),gnu)
        override LIBC = gnu
    else
        $(error "ERROR: A non supported LIBC value was passed. Supported values are musl and gnu")
    endif
endif

ifeq ($(ARCH), ppc64le)
    override LIBC = gnu
    override ARCH = powerpc64le
    $(warning "WARNING: powerpc64le-unknown-linux-musl target is unavailable")
endif

ifeq ($(ARCH), riscv64)
    override LIBC = gnu
    override ARCH = riscv64gc
    $(warning "WARNING: riscv64gc-unknown-linux-musl target is unavailable")
endif

ifeq ($(ARCH), s390x)
    override LIBC = gnu
    $(warning "WARNING: s390x-unknown-linux-musl target is unavailable")
endif

EXTRA_RUSTFLAGS :=
TRIPLE = $(ARCH)-unknown-linux-$(LIBC)

CARGO ?= cargo
INSTALL ?= install

PACKAGE := kata-dan-cni
BINARY := kata-dan-cni
TARGET_DIR = $(if $(CARGO_TARGET_DIR),$(CARGO_TARGET_DIR),target)
BINARY_DIR = $(if $(findstring release,$(BUILD_TYPE)),release,debug)
RELEASE_FLAG = $(if $(findstring release,$(BUILD_TYPE)),--release)

CNI_BIN_DIR ?= /opt/cni/bin
DESTDIR ?=

.DEFAULT_GOAL := default
default: build
all: build

build:
	RUSTFLAGS="$(EXTRA_RUSTFLAGS) --deny warnings" $(CARGO) build --locked -p $(PACKAGE) --bins --target $(TRIPLE) $(RELEASE_FLAG)

release:
	$(MAKE) build BUILD_TYPE=release

fmt:
	$(CARGO) fmt --all -- --check

clippy:
	$(CARGO) clippy --workspace --all-targets --all-features --release --locked -- -D warnings

standard_rust_check: fmt clippy

check: standard_rust_check test

test:
	RUSTFLAGS="$(EXTRA_RUSTFLAGS) --deny warnings" $(CARGO) test --workspace --all-targets --all-features --locked --target $(TRIPLE) $(RELEASE_FLAG)

test-integration:
	CARGO="$(CARGO)" TRIPLE="$(TRIPLE)" BUILD_TYPE="$(BUILD_TYPE)" RUSTFLAGS="$(EXTRA_RUSTFLAGS) --deny warnings" bash tests/run-integration.sh

clean:
	$(CARGO) clean

static-checks-build:
	@echo "INFO: static-checks-build do nothing.."

install: build
	$(INSTALL) -D -m 0755 \
		"$(TARGET_DIR)/$(TRIPLE)/$(BINARY_DIR)/$(BINARY)" \
		"$(DESTDIR)$(CNI_BIN_DIR)/$(BINARY)"

.PHONY: default all build release fmt clippy standard_rust_check check test test-integration clean static-checks-build install
