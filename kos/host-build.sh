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
BUILD="${ROOT_DIR}/build/host"
INSTALL="${ROOT_DIR}/install/host"
JOBS=`nproc`

PrintHelp () {
cat<<HELP

Script for building and installing ${PROJECT_NAME} for a host.

USAGE:

    ${0} [OPTIONS]

OPTIONS:

    -h, --help
        Help text.

    -i, --install PATH
        Path to directory where ${PROJECT_NAME} for the host will be installed.
        If not specified, the default path ${INSTALL} will be used.
        The value specified in the -i option takes precedence over the value of the INSTALL_PREFIX environment variable.

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
    -i | --install) INSTALL_PREFIX="${2}"
        shift ;;
    -j | --jobs) JOBS="${2}"
        shift ;;
    *) echo "Unknown option -'${1}'."
        PrintHelp
        exit 1;;
    esac
    shift
done

if [ -z "${INSTALL_PREFIX}" ]; then
    INSTALL_PREFIX="${INSTALL}"
fi

# Build protobuf on the host to use it as part of the toolchain.
cmake -B "${BUILD}" \
      -D CMAKE_BUILD_TYPE:STRING=Debug \
      -D CMAKE_INSTALL_PREFIX:STRING="${INSTALL_PREFIX}" \
      -D gRPC_INSTALL=ON \
      -D gRPC_BUILD_TESTS=OFF \
      -D ABSL_PROPAGATE_CXX_STD=ON \
      "${ROOT_DIR}" && \
cmake --build "${BUILD}" -j${JOBS} --target install
