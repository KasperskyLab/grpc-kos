#!/usr/bin/env bash
#
# © 2024 AO Kaspersky Lab
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

EXAMPLE_DIR="$(dirname "$(realpath "${0}")")"
BUILD=${EXAMPLE_DIR}/build/kos
ROOT_DIR="$(dirname "$(realpath "../../../$(basename "${0}")")")"
HOST_GRPC_INSTALL=${ROOT_DIR}/install/host
KOS_GRPC_INSTALL=${ROOT_DIR}/install/kos
USE_SECURE_CONNECTION_VALUE=OFF
TARGET=""
CMAKE_TARGET=sim
JOBS=`nproc`

function PrintHelp () {
cat<<HELP

Script for building and running a server/client in KasperskyOS.

USAGE:

    ${0} <TARGET> [OPTIONS]

TARGET:

    'server' to build and run the server;
    'client' to build and run the client.

OPTIONS:

    -h, --help
        Help text.

    -s, --sdk PATH
        Path to the installed version of the KasperskyOS Community Edition SDK.
        The value specified in the -s option takes precedence over the value of the SDK_PREFIX environment variable.

    -p, --platform PLATFORM
        Target platform for the build. It can take one of the following values:
        'qemu' to build a KasperskyOS-based solution image named 'kos-qemu-image' that includes the KasperskyOS server/client
            and to run this solution on QEMU.
        'image' to build a KasperskyOS-based solution image named 'kos-image' that includes the KasperskyOS server/client.
            Prepare a bootable SD card and write 'kos-image' on it to run example on Raspberry Pi 4 B.
        'rpi' to build a file system image named 'rpi4kos.img' for a bootable SD card. The following is loaded into the file system image:
            'kos-image', U-Boot bootloader that starts the example, and the firmware for Raspberry Pi 4 B.
            Write the 'rpi4kos.img' image to the SD card with dd utility to run example on Raspberry Pi 4 B.
        Default value: qemu.

    -K, --kos-install PATH
        Path to directory where gRPC for KasperskyOS is installed.
        If not specified, the default path ${KOS_GRPC_INSTALL} will be used.

    -H, --host-install PATH
        Path to the directory where gRPC for the host is installed.
        If not specified, the default path ${HOST_GRPC_INSTALL} will be used.

    -S, --secure
        Use of a secure connection. When specified, SSL/TLS authentication will be used.

    -j, --jobs N
        Number of jobs for parallel build. If not specified, the default value ${JOBS} will be used.
HELP
}

# Parse command line options.
while [ -n "${1}" ]; do
    case "${1}" in
    server | client) TARGET="${1}"
        ;;
    -h | --help) PrintHelp
        exit 0;;
    -s | --sdk) SDK_PREFIX="${2}"
        shift;;
    -p | --platform)
        case "${2}" in
            qemu)  CMAKE_TARGET=sim ;;
            image) CMAKE_TARGET=kos-image ;;
            rpi)   CMAKE_TARGET=sd-image ;;
            *) echo "Invalid platform: ${2}."; PrintHelp; exit 1;;
        esac
        shift;;
    -j | --jobs) JOBS="${2}"
        shift ;;
    -H | --host-install) HOST_GRPC_INSTALL="${2}"
        shift ;;
    -K | --kos-install) KOS_GRPC_INSTALL="${2}"
        shift ;;
    -S | --secure) USE_SECURE_CONNECTION_VALUE=ON
        ;;
    *) echo "Unknown option -'${1}'."
        PrintHelp
        exit 1;;
    esac
    shift
done

if [ -z "${SDK_PREFIX}" ] || [ ! -e "${SDK_PREFIX}" ]; then
    echo "Path to the installed KasperskyOS SDK is not specified."
    PrintHelp
    exit 1
fi

if [ -z "${TARGET}" ]; then
    echo "TARGET is not specified."
    PrintHelp
    exit 1
fi

if [ -z "${HOST_GRPC_INSTALL}" ] || [ ! -e "${HOST_GRPC_INSTALL}" ]; then
    echo "Path to gRPC install directory for the host is not specified."
    PrintHelp
    exit 1
fi

if [ -z "${KOS_GRPC_INSTALL}" ] || [ ! -e "${KOS_GRPC_INSTALL}" ]; then
    echo "Path to gRPC install directory for KasperskyOS is not specified."
    PrintHelp
    exit 1
fi

export LANG=C
export TARGET_ARCH="aarch64-kos"
export PKG_CONFIG=""
export PATH="$SDK_PREFIX/toolchain/bin:$PATH"

export BUILD_WITH_CLANG=
export BUILD_WITH_GCC=

TOOLCHAIN_SUFFIX=""

if [ "$BUILD_WITH_CLANG" == "y" ];then
    TOOLCHAIN_SUFFIX="-clang"
fi

if [ "$BUILD_WITH_GCC" == "y" ];then
    TOOLCHAIN_SUFFIX="-gcc"
fi

BUILD="${BUILD}/${TARGET}"

cmake -B "${BUILD}" -G "Unix Makefiles" \
      -D BOARD:STRING="RPI4_BCM2711" \
      -D BUILD_TARGET:STRING="${TARGET}" \
      -D GRPC_ROOT_DIR:STRING="${ROOT_DIR}" \
      -D USE_SECURE_CONNECTION:BOOL=$USE_SECURE_CONNECTION_VALUE \
      -D CMAKE_BUILD_TYPE:STRING=Debug \
      -D CMAKE_PREFIX_PATH="${HOST_GRPC_INSTALL}" \
      -D CMAKE_FIND_ROOT_PATH="${KOS_GRPC_INSTALL};${PREFIX_DIR}/sysroot-${TARGET_ARCH}" \
      -D CMAKE_TOOLCHAIN_FILE=$SDK_PREFIX/toolchain/share/toolchain-${TARGET_ARCH}${TOOLCHAIN_SUFFIX}.cmake \
      "${EXAMPLE_DIR}" && \
cmake --build "${BUILD}" -j ${JOBS} -t ${CMAKE_TARGET}
