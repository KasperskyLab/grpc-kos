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

cmake_minimum_required(VERSION 3.25)

project(hello_world)

# Set the variable SSL_CERTIFICATE_DIR to the directory path where the SSL certificates are located.
set(SSL_CERTIFICATE_DIR "${GRPC_ROOT_DIR}/src/core/tsi/test_creds")
set(RESOURCES "${CMAKE_SOURCE_DIR}/resources")

if(KOS)
  # Include and initialize the CMake library named platform.
  include(platform)
  initialize_platform()

  # Include the CMake library named doxygen for documentation of source texts.
  include(platform/doxygen)
  add_project_documentation_main_target()

  # Include the CMake library named nk for working with the NK compiler (nk-gen-c).
  include(platform/nk)

  # Include the vfs package with VFS libraries.
  find_package(vfs REQUIRED)
  include_directories(${vfs_INCLUDE})

  # Search for the rump package and load its DHCPCD_CLIENT_LIB component.
  find_package(rump REQUIRED COMPONENTS DHCPCD_ENTITY)
  include_directories(${rump_INCLUDE})

  # Include the vfs package with VFS executable files.
  find_package(precompiled_vfs REQUIRED)
  include_directories(${precompiled_vfs_INCLUDE})

  find_package(Threads REQUIRED)
endif()

add_subdirectory(libraries)

if(NOT BUILD_TARGET)
  message(FATAL_ERROR "BUILD_TARGET not specified.")
endif()

message(STATUS "Building ${BUILD_TARGET}")
add_subdirectory(${BUILD_TARGET})

if(KOS)
  add_subdirectory(einit)
endif()
