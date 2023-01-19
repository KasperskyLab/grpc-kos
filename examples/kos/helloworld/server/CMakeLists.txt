# © 2022 AO Kaspersky Lab. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required (VERSION 3.12)

project(GreeterServer)

if(KOS)

    # Initialize CMake library for KasperskyOS SDK.
    include (platform)
    initialize_platform ()

    # Add Doxygen documentation
    include (platform/doxygen)
    add_project_documentation_main_target ()

    # Tools for using NK parser.
    include (platform/nk)

    nk_build_edl_files (HelloWorld_server_edl_files NK_MODULE "helloworld" EDL "resources/GreeterServer.edl")
    
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

add_executable (GreeterServer
                "src/main.cc"
                "src/greeter_service_impl.h"
                "src/greeter_service_impl.cc")

target_compile_features (GreeterServer PRIVATE cxx_std_17)

target_link_libraries(GreeterServer
    helloworld_grpc_proto
    utility_lib)

if(KOS)

    target_link_libraries(GreeterServer
        ${vfs_CLIENT_LIB}
        ${CMAKE_THREAD_LIBS_INIT})

    add_dependencies (GreeterServer HelloWorld_server_edl_files)
    add_subdirectory (einit)

else()

    foreach(_file ca.pem server1.pem server1.key)

        add_custom_command(
                TARGET GreeterServer POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${SSL_SERTIFICATE_DIR}/${_file}
                        ${CMAKE_CURRENT_BINARY_DIR}/${_file})

    endforeach()

endif()
