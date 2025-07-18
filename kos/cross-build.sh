#!/usr/bin/env bash
#
# © 2025 AO Kaspersky Lab
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

set -e

PROJECT_NAME=gRPC
KOS_DIR="$(dirname "$(realpath "${0}")")"
ROOT_DIR="$(dirname "${KOS_DIR}")"

BUILD="${ROOT_DIR}/build/kos"
BUILD_HOST="${BUILD}/host"
BUILD_KOS="${BUILD}/kos"
DEFAULT_INSTALL_PREFIX="${ROOT_DIR}/install"
INSTALL_HOST="${DEFAULT_INSTALL_PREFIX}/host"
INSTALL_KOS="${DEFAULT_INSTALL_PREFIX}/kos"
JOBS=1
DEFAULT_BUILD_TYPE=Debug

function PrintHelp() {
cat<<HELP

Build and install ${PROJECT_NAME} for KasperskyOS.

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
        Path to the directory where ${PROJECT_NAME} for KasperskyOS will be installed.
        If not specified, the default path ${INSTALL_KOS} will be used.
        The value specified in the -i option takes precedence over the value of the INSTALL_PREFIX environment variable.

    -H, --host-install PATH
        If this directory does not exist, gRPC for the host will be built and installed to this directory automatically.
        If not specified, the default path ${INSTALL_HOST} will be used.

    -j, --jobs N
        Number of jobs for parallel build.
        If not specified, the default value ${JOBS} will be used.

    --build-type TYPE
        Set build type: release or debug.
        Default build type is $(echo -n ${DEFAULT_BUILD_TYPE} | tr '[:upper:]' '[:lower:]').
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
    -H | --host-install) HOST_INSTALL_PREFIX="${2}"
        shift;;
    -j | --jobs) JOBS="${2}"
        shift;;
    --build-type)
        case "${2}" in
        release) BUILD_TYPE=Release
            shift;;
        debug) BUILD_TYPE=Debug
            shift;;
        *) echo "Unknown build type - '${2}'."
            PrintHelp
            exit 1;;
        esac;;
    *) echo "Unknown option - '${1}'."
        PrintHelp
        exit 1;;
    esac
    shift
done

if [ -z "${SDK_PREFIX}" ]; then
    echo "Path to the installed KasperskyOS SDK is not specified."
    PrintHelp
    exit 1
fi

if [ -z "${TARGET_PLATFORM}" ]; then
    echo "Target platform is not specified. Try to autodetect..."
    TARGET_PLATFORMS=($(ls -d "${SDK_PREFIX}"/sysroot-* | sed 's|.*sysroot-\(.*\)|\1|'))
    if [ ${#TARGET_PLATFORMS[@]} -gt 1 ]; then
        echo "More than one target platform found: ${TARGET_PLATFORMS[*]}."
        echo "Reinstall SDK or remove extra sysroot-* directories."
        exit 1
    fi

    export TARGET_PLATFORM=${TARGET_PLATFORMS[0]}
    echo "Platform ${TARGET_PLATFORM} will be used."
fi

if [ -z "${INSTALL_PREFIX}" ]; then
    export INSTALL_PREFIX="${INSTALL_KOS}"
    echo "Install path is not specified."
    echo "Use default install path - ${INSTALL_PREFIX}."
fi

if [ -z "${HOST_INSTALL_PREFIX}" ]; then
    export HOST_INSTALL_PREFIX="${INSTALL_HOST}"
    echo "Host install path is not specified."
    echo "Use default host install path - ${HOST_INSTALL_PREFIX}."
fi

# HOST_INSTALL_PREFIX must be absolute path.
if [[ "${HOST_INSTALL_PREFIX}" != /* ]]; then
    HOST_INSTALL_PREFIX="${PWD}/${HOST_INSTALL_PREFIX}"
fi

if [ -z "${BUILD_TYPE}" ]; then
    export BUILD_TYPE=${DEFAULT_BUILD_TYPE}
    echo "Use default build type - ${BUILD_TYPE}."
fi

export LANG=C
export PKG_CONFIG=""
export PATH="${SDK_PREFIX}/toolchain/bin:${PATH}"

TOOLCHAIN_SUFFIX="-clang"

if [ ! -e "${HOST_INSTALL_PREFIX}" ]; then
    echo "Host gRPC directory ${HOST_INSTALL_PREFIX} does not exist."
    echo "Starting host gRPC build..."
    "${KOS_DIR}"/host-build.sh -i "${HOST_INSTALL_PREFIX}" -j ${JOBS}
    if [ $? -ne 0 ]; then
        echo "Host build failed!"
        exit 1
    fi
else
    echo "Host gRPC directory ${HOST_INSTALL_PREFIX} exists."
    echo "Skipping host gRPC build."
fi

"${SDK_PREFIX}/toolchain/bin/cmake" -G "Unix Makefiles" -B "${BUILD}" \
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
      -D gRPC_ZLIB_PROVIDER=package \
      -D CMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
      -D CMAKE_INSTALL_PREFIX:STRING="${INSTALL_PREFIX}" \
      -D CMAKE_FIND_ROOT_PATH="${HOST_INSTALL_PREFIX};${PREFIX_DIR}/sysroot-${TARGET_PLATFORM}" \
      -D CMAKE_TOOLCHAIN_FILE="${SDK_PREFIX}/toolchain/share/toolchain-${TARGET_PLATFORM}${TOOLCHAIN_SUFFIX}.cmake" \
      "${ROOT_DIR}" && "$SDK_PREFIX/toolchain/bin/cmake" --build "${BUILD}" -j${JOBS} --target install
