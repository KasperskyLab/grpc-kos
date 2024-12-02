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
BUILD=${EXAMPLE_DIR}/build/host
ROOT_DIR="$(dirname "$(realpath "../../../$(basename "${0}")")")"
HOST_GRPC_INSTALL=${ROOT_DIR}/install/host
TARGET=""
SECURE_CONNECTION_OPTION=""
JOBS=`nproc`

function PrintHelp() {
cat<<HELP

Script for building and running a server/client in a Linux host operating system.

USAGE:

    ${0} <TARGET> [OPTIONS]

TARGET:

    'server' to build and run the server;
    'client' to build and run the client.

OPTIONS:

    -h, --help
        Help text.

    -H, --host-install PATH
        Path to the directory where gRPC for the host is installed. If not specified, the default path ${HOST_GRPC_INSTALL} will be used.

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
    -j | --jobs) JOBS="${2}"
        shift ;;
    -H | --host-install) HOST_GRPC_INSTALL="${2}"
        shift ;;
    -S | --secure) SECURE_CONNECTION_OPTION="--secure"
        ;;
    *) echo "Unknown option -'${1}'."
        PrintHelp
        exit 1;;
    esac
    shift
done

if [ -z "${TARGET}" ]; then
    echo "TARGET is not specified."
    PrintHelp
    exit 1
fi

if [ -z "${HOST_GRPC_INSTALL}" ] || [ ! -e "${HOST_GRPC_INSTALL}" ]; then
    echo "Path to gRPC install directоry for the host is not specified."
    PrintHelp
    exit 1
fi

BUILD="${BUILD}/${TARGET}"
EXECUTABLE="Greeter$(echo ${TARGET} | sed -E 's|(.)(.*)|\u\1\2|')"

cmake -B "${BUILD}" \
      -D BUILD_TARGET:STRING="${TARGET}" \
      -D GRPC_ROOT_DIR:STRING="${ROOT_DIR}" \
      -D CMAKE_PREFIX_PATH="${HOST_GRPC_INSTALL}" \
      "${EXAMPLE_DIR}" && \
cmake --build "${BUILD}" -j ${JOBS} && \
pushd ${BUILD}/${TARGET} && \
./${EXECUTABLE} ${SECURE_CONNECTION_OPTION} && \
popd
