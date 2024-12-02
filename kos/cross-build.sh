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

PROJECT_NAME=gRPC
KOS_DIR="$(dirname "$(realpath "${0}")")"
ROOT_DIR="$(dirname "${KOS_DIR}")"
BUILD="${ROOT_DIR}/build/kos"
BUILD_HOST="${BUILD}/host"
BUILD_KOS="${BUILD}/kos"
INSTALL="${ROOT_DIR}/install"
INSTALL_HOST="${INSTALL}/host"
INSTALL_KOS="${INSTALL}/kos"
JOBS=`nproc`

PrintHelp () {
cat<<HELP

Script for building and installing ${PROJECT_NAME} for KasperskyOS.

USAGE:

    ${0} [OPTIONS]

OPTIONS:

    -h, --help
        Help text.

    -s, --sdk PATH
        Path to the installed version of the KasperskyOS Community Edition SDK.
        The path must be set using either the value of the SDK_PREFIX environment variable or the -s option.
        The value specified in the -s option takes precedence over the value of the SDK_PREFIX environment variable.

    -i, --install PATH
        Path to directory where ${PROJECT_NAME} for KasperskyOS will be installed.
        If not specified, the default path ${INSTALL_KOS} will be used.
        The value specified in the -i option takes precedence over the value of the INSTALL_PREFIX environment variable.

    -H, --host-install PATH
        Path to the directory where gRPC for the host is installed.
        If not specified, the default path ${INSTALL_HOST} will be used.

    -j, --jobs N
        Number of jobs for parallel build.
        If not specified, the default value ${JOBS} will be used.
HELP
}

# Parse command line options.
while [ -n "${1}" ]; do
    case "${1}" in
    -h | --help) PrintHelp
        exit 0;;
    -s | --sdk) SDK_PREFIX="${2}"
        shift;;
    -i | --install) INSTALL_PREFIX="${2}"
        shift;;
    -j | --jobs) JOBS="${2}"
        shift ;;
    -H | --host-install) HOST_INSTALL_PREFIX="${2}"
        shift ;;
    *) echo "Unknown option -'${1}'."
        PrintHelp
        exit 1;;
    esac
    shift
done

if [ -z "${SDK_PREFIX}" ]; then
    echo "Path to installed KasperskyOS SDK is not specified."
    PrintHelp
    exit 1
fi

export PATH="${SDK_PREFIX}/toolchain/bin:${PATH}"

if [ -z "${HOST_INSTALL_PREFIX}" ]; then
    export HOST_INSTALL_PREFIX="${INSTALL_HOST}"
    if [ ! -e "${HOST_INSTALL_PREFIX}" ]; then
      "${KOS_DIR}"/host-build.sh -i "${HOST_INSTALL_PREFIX}" -j ${JOBS}
      [ $? -ne 0 ] && echo "Host build failed!" && exit 1
  fi
fi

# HOST_INSTALL_PREFIX must be absolute path.
if [[ "${HOST_INSTALL_PREFIX}" != /* ]]; then
    HOST_INSTALL_PREFIX="${PWD}/${HOST_INSTALL_PREFIX}"
fi

if [ -z "${TARGET}" ]; then
    echo "Target platform is not specified, try to autodetect..."
    TARGETS=($(ls -d "${SDK_PREFIX}"/sysroot-* | sed 's|.*sysroot-\(.*\)|\1|'))
    if [ ${#TARGETS[@]} -gt 1 ]; then
        echo "More than one target platform found: ${TARGETS[*]}."
        echo "Use TARGET environment variable to specify exact platform."
        exit 1
    fi

    export TARGET=${TARGETS[0]}
    echo "Platform ${TARGET} will be used."
fi

if [ -z "${INSTALL_PREFIX}" ]; then
    export INSTALL_PREFIX="${INSTALL_KOS}"
    echo "Installation path of gRPC for KasperskyOS is not specified."
    echo "Default path ${INSTALL_PREFIX} will be used."
fi

export LANG=C
export PKG_CONFIG=""
export BUILD_WITH_CLANG=
export BUILD_WITH_GCC=

TOOLCHAIN_SUFFIX=""

if [ "${BUILD_WITH_CLANG}" == "y" ];then
    TOOLCHAIN_SUFFIX="-clang"
fi

if [ "${BUILD_WITH_GCC}" == "y" ];then
    TOOLCHAIN_SUFFIX="-gcc"
fi

cmake -G "Unix Makefiles" -B "${BUILD}" \
      -D CMAKE_BUILD_TYPE:STRING=Debug \
      -D CMAKE_INSTALL_PREFIX:STRING="${INSTALL_PREFIX}" \
      -D CMAKE_FIND_ROOT_PATH="${HOST_INSTALL_PREFIX};${PREFIX_DIR}/sysroot-${TARGET}" \
      -D CMAKE_TOOLCHAIN_FILE="${SDK_PREFIX}/toolchain/share/toolchain-${TARGET}${TOOLCHAIN_SUFFIX}.cmake" \
      -D ABSL_PROPAGATE_CXX_STD=ON \
      -D RE2_BUILD_TESTING=OFF \
      -D protobuf_BUILD_TESTS=OFF \
      -D protobuf_BUILD_PROTOC_BINARIES=OFF \
      -D gRPC_BUILD_TESTS=OFF \
      -D gRPC_BUILD_CSHARP_EXT=OFF \
      -D gRPC_BUILD_GRPC_CPP_PLUGIN=OFF \
      -D gRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF \
      -D gRPC_BUILD_GRPC_NODE_PLUGIN=OFF \
      -D gRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF \
      -D gRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
      -D gRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF \
      -D gRPC_BUILD_GRPC_RUBY_PLUGIN=OFF \
      "${ROOT_DIR}" && \
cmake --build "${BUILD}" -j ${JOBS} --target install
