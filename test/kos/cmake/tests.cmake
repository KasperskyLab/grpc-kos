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

# Initialize CMake library for KasperskyOS SDK.
include(platform)
initialize_platform(FORCE_STATIC)

# Tools for using NK parser.
include(platform/nk)

# Tools to generate project for unit tests on KasperskyOS
include(test-generator/test_generator)

# Add a package with the VFS program implementations.
find_package(vfs REQUIRED)
include_directories(${vfs_INCLUDE})

# Add a package with prebuilt VFS program implementations.
find_package(precompiled_vfs REQUIRED)

# Add a package with the Dhcpcd program implementation.
find_package(rump REQUIRED COMPONENTS DHCPCD_ENTITY)
include_directories(${rump_INCLUDE})

# Set additional properties for precompiled_vfsVfsSdCardFs program.
set_target_properties(${precompiled_vfsVfsSdCardFs}
  PROPERTIES
    EXTRA_ENV "
          VFS_FILESYSTEM_BACKEND: server:kl.VfsSdCardFs"
    EXTRA_ARGS "
          - -l
          - devfs /dev devfs 0
          - -l
          - romfs /etc romfs ro"
)

# Set additional properties for precompiled_vfsVfsNet program.
set_target_properties(${precompiled_vfsVfsNet}
  PROPERTIES
    EXTRA_ENV "
          VFS_FILESYSTEM_BACKEND: server:kl.VfsNet"
    EXTRA_ARGS "
          - -l
          - devfs /dev devfs 0
          - -l
          - romfs /etc romfs ro"
)

# Set additional properties for rump_DHCPCD_ENTITY program.
set_target_properties(${rump_DHCPCD_ENTITY}
  PROPERTIES
    ${vfs_ENTITY}_REPLACEMENT ""
    DEPENDS_ON_ENTITY "${precompiled_vfsVfsSdCardFs};${precompiled_vfsVfsNet}"
    EXTRA_ENV "
            VFS_FILESYSTEM_BACKEND: client{fs->net}:kl.VfsSdCardFs
            VFS_NETWORK_BACKEND: client:kl.VfsNet"
    EXTRA_ARGS "
            - '-4'
            - '-f'
            - /etc/dhcpcd.conf"
)

# Filtered tests:
#  No Ipv6 loopback on KasperskyOS:
#     AddressSortingTest.*Ipv6Loopback*,
#     ResolveAddressTest.LocalhostResultHasIPv6First
#  Death Tests are not supported on KasperskyOS:
#     *GrpcToolTest.NoCommand*
#     *GrpcToolTest.InvalidCommand*
#     *GrpcToolTest.HelpCommand*
#     *GrpcToolTest.TooFewArguments*
#     *GrpcToolTest.TooManyArguments*
#     *GrpcToolTest.CallCommandWithBadMetadata*
#  No HOME directory on KasperskyOS:
#     CredentialsTest.TestGetWellKnownGoogleCredentialsFilePath
#  KasperskyOS does not support SO_REUSEADDR and does not allow binding the same address and port twice:
#     ServerBuilderTest.CreateServerRepeatedPort
#  Too mach objects create VFS_SERVER_OCAP Error code 28 Quota exceeded:
#     PortSharingEnd2endTest.*
#     GrpcToolTest.*
#     AltsConcurrentConnectivityTest.*
#     ClientCallbackEnd2endTest.*
#     SingleBalancerTest.*
#  execv is not implemented on KasperskyOS:
#     HttpRequestTest.*
#     HttpsCliTest.*
#  Stack trace is not enabled on KasperskyOS:
#     ExamineStackTest.*
#  Flaky:
#     CancelDuringAresQuery.TestHitDeadlineAndDestroyChannelDuringAresResolutionWithZeroQueryTimeoutIsGraceful
#     ClientInterceptorsStreamingEnd2endTest.*
#     GrpcAuthzEnd2EndTest.*
#     IdleFilterStateTest.*
#     EchoTest.*
#     ServerBuilderTest.*
#     StreamsNotSeenTest.*
#     XdsCredentialsEnd2EndFallback*
string(JOIN : FILTERED_TESTS
  AddressSortingTest.*Ipv6Loopback*
  ResolveAddressTest.LocalhostResultHasIPv6First
  CredentialsTest.TestGetWellKnownGoogleCredentialsFilePath
  ServerBuilderTest.CreateServerRepeatedPort
  *PortSharingEnd2endTest.*
  HybridEnd2endTest.AsyncRequestStreamResponseStream_*
  CancelDuringAresQuery.TestHitDeadlineAndDestroyChannelDuringAresResolutionWithZeroQueryTimeoutIsGraceful
  ClientInterceptorsStreamingEnd2endTest.ServerStreamingHijackingTest
  HttpRequestTest.*
  HttpsCliTest.*
  GrpcToolTest.*
  *AsyncEnd2endTest*
  AltsConcurrentConnectivityTest.*
  ClientCallbackEnd2endTest.*
  ExamineStackTest.*
  SingleBalancerTest.*
  GrpcAuthzEnd2EndTest.*
  IdleFilterStateTest.*
  EchoTest.*
  ServerBuilderTest.*
  StreamsNotSeenTest.*
  XdsCredentialsEnd2EndFallback*
)

set(KOS_TEST_DIR "${CMAKE_SOURCE_DIR}/test/kos")

include(${KOS_TEST_DIR}/cmake/disabled_cpp_tests.cmake)
include(${KOS_TEST_DIR}/cmake/add_gtest.cmake)

function(add_tests_kos TESTS)
  foreach(TEST ${TESTS})
    if(NOT (${TEST} IN_LIST DISABLED_CXX_TESTS))
      add_gtest_target(${TEST}
        DEPENDS_ON ${precompiled_vfsVfsSdCardFs}
                   ${precompiled_vfsVfsNet}
                   ${rump_DHCPCD_ENTITY}
        ENV_VARIABLES VFS_FILESYSTEM_BACKEND=client:kl.VfsSdCardFs
                      VFS_NETWORK_BACKEND=client:kl.VfsNet
        ARGS --gtest_filter=-${FILTERED_TESTS}
        FILES ${KOS_TEST_DIR}/resources/etc/dhcpcd.conf
              ${KOS_TEST_DIR}/resources/etc/hosts
              ${KOS_TEST_DIR}/resources/etc/resolv.conf
        FILES_TO_COPY ${CMAKE_SOURCE_DIR}/src/core/tsi/test_creds:src/core/tsi
                      ${CMAKE_SOURCE_DIR}/test/core/security/authorization/test_policies:test/core/security/authorization
                      ${CMAKE_SOURCE_DIR}/test/core/tsi/test_creds:test/core/tsi
      )
    endif()
  endforeach()
endfunction()
