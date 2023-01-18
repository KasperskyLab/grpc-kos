#!/bin/bash

# © 2022 AO Kaspersky Lab. All Rights Reserved

set -e

export GRPC_HOST_INSTALL=$HOME/.local

# Use externally provided env to determine build parallelism, otherwise use default.
GRPC_CPP_DISTRIBTEST_BUILD_COMPILER_JOBS=${GRPC_CPP_DISTRIBTEST_BUILD_COMPILER_JOBS:-4}

# Build and install gRPC for the host architecture.
# We do this because we need to be able to run protoc and grpc_cpp_plugin
# while cross-compiling.
mkdir -p cmake/build
pushd cmake/build
cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=$GRPC_HOST_INSTALL \
      ../..
make "-j${GRPC_CPP_DISTRIBTEST_BUILD_COMPILER_JOBS}" install
popd

# Build and install gRPC for Kaspersky OS (KOS).
# This build will use the host architecture copies of protoc and
# grpc_cpp_plugin that we built earlier.
export LANG=C
export TARGET="aarch64-kos"
export PKG_CONFIG=""
# Please specify the actual path to Kaspersky OS SDK on host system
export SDK_PREFIX="/opt/KasperskyOS-Community-Edition-1.1.1.13"
export PATH="$SDK_PREFIX/toolchain/bin:$PATH"
export LD_LIBRARY_PATH=$SDK_PREFIX/toolchain/lib
export KOS_INSTALL=$HOME/.local/kos

mkdir -p cmake/build_kos
pushd cmake/build_kos
cmake -G "Unix Makefiles" \
      -DCMAKE_INSTALL_PREFIX:STRING=$KOS_INSTALL \
      -DCMAKE_BUILD_TYPE:STRING=Debug \
      -DCMAKE_TOOLCHAIN_FILE=$SDK_PREFIX/toolchain/share/toolchain-$TARGET.cmake \
      -DgRPC_BUILD_TESTS=OFF \
      -D_gRPC_PROTOBUF_PROTOC_EXECUTABLE=$GRPC_HOST_INSTALL/bin/protoc \
      -DProtobuf_INCLUDE_DIR:PATH=$GRPC_HOST_INSTALL/include \
      -DProtobuf_LIBRARY_DEBUG:FILEPATH=$GRPC_HOST_INSTALL/lib/libprotobuf.a \
      -DProtobuf_LIBRARY_RELEASE:FILEPATH=$GRPC_HOST_INSTALL/lib/libprotobuf.a \
      -DProtobuf_LITE_LIBRARY_DEBUG:FILEPATH=$GRPC_HOST_INSTALL/lib/libprotobuf-lite.a \
      -DProtobuf_LITE_LIBRARY_RELEASE:FILEPATH=$GRPC_HOST_INSTALL/lib/libprotobuf-lite.a \
      -DProtobuf_PROTOC_EXECUTABLE:FILEPATH=$GRPC_HOST_INSTALL/bin/protoc \
      -DProtobuf_PROTOC_LIBRARY_DEBUG:FILEPATH=$GRPC_HOST_INSTALL/lib/libprotoc.a \
      -DProtobuf_PROTOC_LIBRARY_RELEASE:FILEPATH=$GRPC_HOST_INSTALL/lib/libprotoc.a \
      -DRE2_BUILD_TESTING=OFF \
      ../..

make "-j${GRPC_CPP_DISTRIBTEST_BUILD_COMPILER_JOBS}" install
popd
