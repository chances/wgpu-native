RUST_BACKTRACE:=1
EXCLUDES:=

GENERATOR_PLATFORM:=

FFI_DIR:=ffi
BUILD_DIR:=build
CREATE_BUILD_DIR:=
OUTPUT_DIR:=
FINAL_LIB_NAME:=libwgpu


WILDCARD_SOURCE:=$(wildcard src/*.rs)

GIT_TAG=$(shell git describe --abbrev=0 --tags)
GIT_TAG_FULL=$(shell git describe --tags)
OS_NAME=

EXTRA_BUILD_ARGS=
TARGET_DIR=target
ifdef TARGET
	EXTRA_BUILD_ARGS=--target $(TARGET)
	TARGET_DIR=target/$(TARGET)
endif

ifndef ARCHIVE_NAME
	ARCHIVE_NAME=wgpu-$(TARGET)
endif

ifeq ($(OS),Windows_NT)
	# '-Force' ignores error if folder already exists
	CREATE_BUILD_DIR=powershell -Command md $(BUILD_DIR) -Force
	GENERATOR_PLATFORM=-DCMAKE_GENERATOR_PLATFORM=x64
	OUTPUT_DIR=build/Debug
else
	CREATE_BUILD_DIR=mkdir -p $(BUILD_DIR)
	OUTPUT_DIR=build
endif

ifeq ($(OS),Windows_NT)
	LIB_NAME=wgpu_native
	LIB_EXTENSION=dll
	OS_NAME=windows
else
	UNAME_S:=$(shell uname -s)
	LIB_NAME=libwgpu_native
	ifeq ($(UNAME_S),Linux)
		LIB_EXTENSION=so
		OS_NAME=linux
	endif
	ifeq ($(UNAME_S),Darwin)
		LIB_EXTENSION=dylib
		OS_NAME=macos
	endif
endif

.PHONY: all check test doc clear \
	example-compute example-triangle \
	run-example-compute run-example-triangle  \
	lib-native lib-native-release

all: example-compute example-triangle example-capture

package: lib-native lib-native-release
	mkdir -p dist
	echo "$(GIT_TAG_FULL)" > dist/commit-sha
	for RELEASE in debug release; do \
		ARCHIVE=$(ARCHIVE_NAME)-$$RELEASE.zip; \
		rm -f dist/$$ARCHIVE; \
		sed 's/webgpu-headers\///' ffi/wgpu.h > wgpu.h ;\
		if [ $(OS_NAME) = windows ]; then \
			mv $(TARGET_DIR)/$$RELEASE/$(LIB_NAME).dll $(TARGET_DIR)/$$RELEASE/$(FINAL_LIB_NAME).dll; \
			mv $(TARGET_DIR)/$$RELEASE/$(LIB_NAME).dll.lib $(TARGET_DIR)/$$RELEASE/$(FINAL_LIB_NAME).lib; \
			7z a -tzip dist/$$ARCHIVE ./$(TARGET_DIR)/$$RELEASE/$(FINAL_LIB_NAME).$(LIB_EXTENSION) ./target/$$RELEASE/$(FINAL_LIB_NAME).lib ./ffi/webgpu-headers/*.h ./wgpu.h ./dist/commit-sha; \
		else \
			mv $(TARGET_DIR)/$$RELEASE/$(LIB_NAME).$(LIB_EXTENSION) $(TARGET_DIR)/$$RELEASE/$(FINAL_LIB_NAME).$(LIB_EXTENSION); \
			zip -j dist/$$ARCHIVE $(TARGET_DIR)/$$RELEASE/$(FINAL_LIB_NAME).$(LIB_EXTENSION) ./ffi/webgpu-headers/*.h ./wgpu.h ./dist/commit-sha; \
		fi; \
		rm wgpu.h ;\
	done

clean:
	cargo clean
	rm -Rf examples/compute/build examples/triangle/build

check:
	cargo check --all

test:
	cargo test --all

doc:
	cargo doc --all

clear:
	cargo clean

lib-native: Cargo.lock Cargo.toml Makefile $(WILDCARD_SOURCE)
	cargo build $(EXTRA_BUILD_ARGS)
	
lib-native-release: Cargo.lock Cargo.toml Makefile $(WILDCARD_SOURCE)
	cargo build --release $(EXTRA_BUILD_ARGS)

example-compute: lib-native examples/compute/main.c
	cd examples/compute && $(CREATE_BUILD_DIR) && cd build && cmake -DCMAKE_BUILD_TYPE=Debug .. $(GENERATOR_PLATFORM) && cmake --build .

run-example-compute: example-compute
	cd examples/compute && "$(OUTPUT_DIR)/compute" 1 2 3 4

example-triangle: lib-native examples/triangle/main.c
	cd examples/triangle && $(CREATE_BUILD_DIR) && cd build && cmake -DCMAKE_BUILD_TYPE=Debug .. $(GENERATOR_PLATFORM) && cmake --build .

run-example-triangle: example-triangle
	cd examples/triangle && "$(OUTPUT_DIR)/triangle"

build-helper:
	cargo build -p helper

example-capture: lib-native build-helper examples/capture/main.c
	cd examples/capture && $(CREATE_BUILD_DIR) && cd build && cmake -DCMAKE_BUILD_TYPE=Debug .. $(GENERATOR_PLATFORM) && cmake --build .

run-example-capture: example-capture
	cd examples/capture && "$(OUTPUT_DIR)/capture"
