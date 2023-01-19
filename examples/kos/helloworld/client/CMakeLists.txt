# © 2022 AO Kaspersky Lab. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required (VERSION 3.12)

project (GreeterClient)

if(KOS)

  # Initialize CMake library for KasperskyOS SDK.
  include (platform)
  initialize_platform ()

  # Add Doxygen documentation
  include (platform/doxygen)
  add_project_documentation_main_target ()

  # Tools for using NK parser.
  include (platform/nk)

  nk_build_edl_files (HelloWorld_client_edl_files NK_MODULE "helloworld" EDL "resources/GreeterClient.edl")
    
  # Add a package for working with the virtual file system.
  find_package (vfs REQUIRED)
  include_directories (${vfs_INCLUDE})

  # Add a package with the Dhcpcd program implementation.
  find_package (rump REQUIRED COMPONENTS DHCPCD_ENTITY)
  include_directories (${rump_INCLUDE})

  # Add package with VFS program implementations.
  find_package (precompiled_vfs REQUIRED)
  include_directories (${precompiled_vfs_INCLUDE})

  find_package (Threads REQUIRED)

endif()

# The location of SSL certifates for secure connection
set (SSL_SERTIFICATE_DIR "${CMAKE_SOURCE_DIR}/../../../../src/core/tsi/test_creds")

add_subdirectory("../libraries" ${CMAKE_CURRENT_BINARY_DIR}/libraries)

add_executable (GreeterClient
                "src/main.cc"
                "src/greeter_client.h"
                "src/greeter_client.cc")

target_compile_features (GreeterClient PRIVATE cxx_std_17)

target_link_libraries(GreeterClient
    helloworld_grpc_proto
    utility_lib)

if(KOS)

  target_link_libraries(GreeterClient ${vfs_CLIENT_LIB})

  add_dependencies (GreeterClient HelloWorld_client_edl_files)
  add_subdirectory (einit)

else()

    add_custom_command(
            TARGET GreeterClient POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
                    ${SSL_SERTIFICATE_DIR}/ca.pem
                    ${CMAKE_CURRENT_BINARY_DIR}/ca.pem)

endif()
