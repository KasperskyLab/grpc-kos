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

export PROJECT_NAME=gRPC
export KOS_DIR="$(dirname "$(realpath "${0}")")"
export ROOT_DIR="$(dirname "${KOS_DIR}")"
export BUILD="${ROOT_DIR}/build/kos_tests"
export HOST_GRPC_INSTALL="${ROOT_DIR}/install/host"
export GENERATED_DIR="${BUILD}/generated"
export TEST_LOGS_DIR="${BUILD}/logs"
export FAILED_TESTS="${TEST_LOGS_DIR}/failed_tests"
export TEST_TARGET_PREFIX="kos-qemu-image-"
export TEST_TARGET_SUFFIX="-sim"
export TEST_TIMEOUT=3000
export JOBS=`nproc`
export CMAKE_PID=
export ALL_TESTS=
export TESTS=
export INTERRUPTED=NO

if [ -z "${TARGET}" ]; then
    echo "TARGET environment variable is not set."
    echo "Default target: aarch64-kos."
    export TARGET="aarch64-kos"
fi

export LANG=C
export PKG_CONFIG=""

export BUILD_WITH_CLANG=
export BUILD_WITH_GCC=

TOOLCHAIN_SUFFIX=""

if [ "${BUILD_WITH_CLANG}" == "y" ]; then
    TOOLCHAIN_SUFFIX="-clang"
fi

if [ "${BUILD_WITH_GCC}" == "y" ]; then
    TOOLCHAIN_SUFFIX="-gcc"
fi

KillQemu () {
    PID_TO_KILL=$(pgrep qemu-system.*)
    kill $PID_TO_KILL 2>/dev/null
}

TrapKillQemu () {
    KillQemu
    INTERRUPTED=YES
}

PrintHelp () {
cat<<HELP

Script for running ${PROJECT_NAME} unit tests on QEMU.

USAGE:

    ${0} [OPTIONS]

OPTIONS:

    -h, --help
        Help text.

    -s, --sdk PATH
        Path to the installed version of the KasperskyOS Community Edition SDK.
        The path must be set using either the value of the SDK_PREFIX environment variable or the -s option.
        The value specified in the -s option takes precedence over the value of the SDK_PREFIX environment variable.

    -l, --list
        List of tests that can be run.

    -n, --name TEST
        Test name to execute. The parameter can be repeated multiple times.
        If not specified, all tests will be executed.

    -t, --timeout SEC
        Time, in seconds, allotted to start and execute a single test case.
        Default value is ${TEST_TIMEOUT} seconds.

    -o, --out PATH
        Path where the results of the test run will be stored.
        If not specified, the results will be stored in the ${TEST_LOGS_DIR} directory.

    -j, --jobs N
        Number of jobs for parallel build.
        If not specified, the default value obtained from the nproc command is used.

    -H, --host-install PATH
        Path to the directory where gRPC for the host is installed.
        If not specified, the default path ${HOST_GRPC_INSTALL} will be used.
HELP
}

ParsArguments () {
    local LIST_TESTS=""

    while [ -n "${1}" ]; do
        case "${1}" in
        -h | --help) PrintHelp
            exit 0;;
        -l | --list) LIST_TESTS=YES;;
        -s | --sdk) SDK_PREFIX="${2}"
            shift;;
        -n | --name) TESTS="${TESTS} ${2}"
            shift ;;
        -t | --timeout) TEST_TIMEOUT="${2}"
            shift ;;
        -o | --out) TEST_LOGS_DIR="${2}";
            shift ;;
        -j | --jobs) JOBS="${2}";
            shift ;;
        -H | --host-install) HOST_GRPC_INSTALL="${2}"
            shift ;;
        *) echo "Unknown option - '${1}'."
            PrintHelp
            exit 1;;
        esac
        shift
    done

    if [ -z "${HOST_GRPC_INSTALL}" ]; then
        echo "Installation path for gRPC on the host is not specified."
        PrintHelp
        exit 1
    fi

    # HOST_GRPC_INSTALL must be absolute path.
    if [[ "${HOST_GRPC_INSTALL}" != /* ]]; then
        HOST_GRPC_INSTALL="${PWD}/${HOST_GRPC_INSTALL}"
    fi

    if [ -z "${SDK_PREFIX}" ]; then
        echo "Path to KasperskyOS SDK is not specified."
        PrintHelp
        exit 1
    fi

    export PATH="${SDK_PREFIX}/toolchain/bin:${PATH}"

    if [ ! -z "${LIST_TESTS}" ]; then
        PrintTestNames
        exit 0
    fi
}

Generate () {

    # Build host grpc if not already exists.
    if [ ! -e "${HOST_GRPC_INSTALL}" ]; then
        echo "gRPC for the host will be built and installed to the ${HOST_GRPC_INSTALL} directory."
        "${KOS_DIR}"/host-build.sh -i "${HOST_GRPC_INSTALL}" -j ${JOBS}
    fi

    cmake -B "${BUILD}" -G "Unix Makefiles" \
          -D CMAKE_BUILD_TYPE:STRING=Debug \
          -D CMAKE_TOOLCHAIN_FILE=$SDK_PREFIX/toolchain/share/toolchain-$TARGET.cmake \
          -D CMAKE_FIND_ROOT_PATH="${HOST_GRPC_INSTALL};${PREFIX_DIR}/sysroot-${TARGET};" \
          -D ABSL_PROPAGATE_CXX_STD=ON \
          -D RE2_BUILD_TESTING=OFF \
          -D protobuf_BUILD_TESTS=OFF \
          -D gRPC_BUILD_TESTS=ON \
          -D gRPC_BUILD_CSHARP_EXT=OFF \
          -D gRPC_BUILD_GRPC_CPP_PLUGIN=OFF \
          -D gRPC_BUILD_GRPC_NODE_PLUGIN=OFF \
          -D gRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF \
          -D gRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
          -D gRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF \
          -D gRPC_BUILD_GRPC_RUBY_PLUGIN=OFF \
          "${ROOT_DIR}"

     if [ $? -ne 0 ]; then
         echo "Can't generate make files.";
         rm -rf "${BUILD}"
         exit 1
     fi
}

ListTests () {
    [ ! -e ${BUILD} ] && Generate
    ALL_TESTS=$("cmake" --build ${BUILD} --target help | \
                grep -wo ${TEST_TARGET_PREFIX}.*${TEST_TARGET_SUFFIX} | \
                sed "s|${TEST_TARGET_PREFIX}\(.*\)${TEST_TARGET_SUFFIX}|\1|")
    if [ -z "${ALL_TESTS}" ]; then
        echo "No test targets found - nothing to do."
        exit 0
    fi
}

PrintTestNames () {
    ListTests
    echo "Tests available:"
    echo "${ALL_TESTS}" | sed 's/\s\+/\n/g' | sort | sed 's/^/  /'
}

GetTests () {
    ListTests
    if [ -z "${TESTS}" ]; then
        TESTS="${ALL_TESTS}"
    else
        TESTS=$(echo "${TESTS}" | sed 's/ /\n/g' | sort | uniq)
        for TEST in ${TESTS}; do
            if ! echo "${ALL_TESTS}" | grep -q "${TEST}"; then
                echo "Unknown test: ${TEST}."
                exit 1;
            fi
        done
    fi
}

SetupEnvironment () {
    # TEST_LOGS_DIR should be a full path, no matter relative or absolute.
    if [[ "${TEST_LOGS_DIR}" != /* ]]; then
        TEST_LOGS_DIR="${PWD}/${TEST_LOGS_DIR}"
    fi

    if [ -e "${TEST_LOGS_DIR}" ]; then
        rm -rf "${TEST_LOGS_DIR}"
    fi

    mkdir -p ${TEST_LOGS_DIR} &> /dev/null

    if [ -e "${FAILED_TESTS}" ]; then
        rm -rf "${FAILED_TESTS}"
    fi
}

RunTests () {

    # Run all specified tests.
    for TEST in ${TESTS}; do

        TEST_LOG="${TEST_LOGS_DIR}/${TEST}.result"
        TEST_TARGET=${TEST_TARGET_PREFIX}${TEST}${TEST_TARGET_SUFFIX}
        FAILED=YES

        # Build test.
        "cmake" --build ${BUILD} --target ${TEST_TARGET} -j ${JOBS} &> ${TEST_LOG} &
        CMAKE_PID=`echo $!`

        TEST_FINISHED_NORMAL=NO
        while IFS= read -t ${TEST_TIMEOUT} -r STR; do
            echo ${STR}
            if [[ ${STR} == *"ALL-KTEST-FINISHED"* || ${STR} == *"FAILED TEST"* ]]; then
                TEST_FINISHED_NORMAL=YES
                break;
            fi
        done < <(tail -F -n +1 --pid="${CMAKE_PID}" "${TEST_LOG}" 2>/dev/null)
        if [[ ${TEST_FINISHED_NORMAL} == NO ]]; then
            echo "FAILED TEST ${TEST}: finished by timeout!"
        fi
        KillQemu

        # Check if the test really failed.
        RUNNING=$(grep -Eor '\[=+\] Running [0-9]+ tests?' "${TEST_LOG}" | grep -Eo '[0-9]+')
        PASSED=$(grep -Eor '\[  PASSED  \] [0-9]+ tests?' "${TEST_LOG}" | grep -Eo '[0-9]+')
        SKIPPED=$(grep -Eor '\[  SKIPPED \] [0-9]+ tests?' "${TEST_LOG}" | grep -Eo '[0-9]+')
        [ ! -z "$SKIPPED" ] && PASSED="$((PASSED + SKIPPED))"

        if [ ! -z "$RUNNING" ] && [ ! -z "$PASSED" ] && [ $RUNNING -eq $PASSED ]; then
              FAILED=NO
        else
              echo "  ${TEST}" >> "${FAILED_TESTS}"
        fi

        # Cleanup.
        if [ "${FAILED}" == NO ]; then
           rm -rf "${BUILD}"/"${TEST}"*
           TEST=${TEST^}
           rm -rf "${GENERATED_DIR}"/*_"${TEST//_}"/*
           rm -rf "${BUILD}"/.build-id/*
        fi

        # Break if interrupted.
        if [ "${INTERRUPTED}" == YES ]; then
          exit 1;
        fi
    done
}

PrintResult () {
    if [ -e "${FAILED_TESTS}" ]; then
        echo "Some tests have failed. See logs for more details."
        echo "List of failed tests can be found at ${FAILED_TESTS}."
        echo "Failed tests:"
        cat "${FAILED_TESTS}"
    else
        echo "All tests are passed."
    fi
}

# Main.
trap TrapKillQemu EXIT QUIT TERM HUP INT PIPE
ParsArguments $@
GetTests
SetupEnvironment
RunTests
PrintResult
