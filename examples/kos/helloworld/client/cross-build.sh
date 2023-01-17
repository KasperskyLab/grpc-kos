#!/bin/bash

# © 2022 AO Kaspersky Lab. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

readonly SecureOption="--secure"

case $# in
    0) USE_SECURE_CONNECTION_VALUE=OFF
    ;;

    1) if [[ $1 == $SecureOption ]]
       then USE_SECURE_CONNECTION_VALUE=ON
       else
            echo Unexpected parameter: $1. The only acceptable parameter: $SecureOption
            exit
       fi
    ;;

    *) echo Too many parameters. The only acceptable parameter: $SecureOption
    exit
    ;;
esac

BUILD=$(cd "$(dirname ${0})"; pwd)/build
mkdir -p $BUILD && cd $BUILD

export LANG=C
export TARGET="aarch64-kos"
export PKG_CONFIG=""
export SDK_PREFIX="/opt/KasperskyOS-Community-Edition-1.1.0.24"
export INSTALL_PREFIX=$BUILD/../install
BUILD_SIM_TARGET="y"
export PATH="$SDK_PREFIX/toolchain/bin:$PATH"

HOST_GRPC_INSTALL=$HOME/.local
KOS_GRPC_INSTALL=$HOME/.local/kos

export BUILD_WITH_CLANG=
export BUILD_WITH_GCC=

TOOLCHAIN_SUFFIX=""

if [ "$BUILD_WITH_CLANG" == "y" ];then
    TOOLCHAIN_SUFFIX="-clang"
fi

if [ "$BUILD_WITH_GCC" == "y" ];then
    TOOLCHAIN_SUFFIX="-gcc"
fi

export LD_LIBRARY_PATH=$SDK_PREFIX/toolchain/lib

cmake -G "Unix Makefiles" \
      -D USE_SECURE_CONNECTION:BOOL=$USE_SECURE_CONNECTION_VALUE \
      -D CMAKE_BUILD_TYPE:STRING=Debug \
      -D CMAKE_INSTALL_PREFIX:STRING=$INSTALL_PREFIX \
      -D _PROTOBUF_PROTOC=$HOST_GRPC_INSTALL/bin/protoc \
      -D _GRPC_CPP_PLUGIN_EXECUTABLE=$HOST_GRPC_INSTALL/bin/grpc_cpp_plugin \
      -D CMAKE_FIND_ROOT_PATH=$KOS_GRPC_INSTALL \
      -D CMAKE_TOOLCHAIN_FILE=$SDK_PREFIX/toolchain/share/toolchain-$TARGET$TOOLCHAIN_SUFFIX.cmake \
      ../ && make sim
