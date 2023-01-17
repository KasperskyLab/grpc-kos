# Copyright 2018 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# cmake build file for C++ helloworld example.
# Assumes protobuf and gRPC have been installed using cmake.
# See cmake_externalproject/CMakeLists.txt for all-in-one cmake build
# that automatically builds all the dependencies before building helloworld.
#
# © 2022 AO Kaspersky Lab. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#

# gRPC common
include(../../../../cpp/cmake/common.cmake)

# Proto file
get_filename_component(helloworld_proto "../../../../protos/helloworld.proto" ABSOLUTE)
get_filename_component(helloworld_proto_path "${helloworld_proto}" PATH)

set(GENERATED_FILES_LOCATION "${CMAKE_CURRENT_BINARY_DIR}")

# Generated sources
set(helloworld_proto_srcs "${GENERATED_FILES_LOCATION}/helloworld.pb.cc")
set(helloworld_proto_hdrs "${GENERATED_FILES_LOCATION}/helloworld.pb.h")
set(helloworld_grpc_srcs "${GENERATED_FILES_LOCATION}/helloworld.grpc.pb.cc")
set(helloworld_grpc_hdrs "${GENERATED_FILES_LOCATION}/helloworld.grpc.pb.h")

add_custom_command(
      OUTPUT "${helloworld_proto_srcs}" "${helloworld_proto_hdrs}" "${helloworld_grpc_srcs}" "${helloworld_grpc_hdrs}"
      COMMAND ${_PROTOBUF_PROTOC}
      ARGS --grpc_out "${GENERATED_FILES_LOCATION}"
        --cpp_out "${GENERATED_FILES_LOCATION}"
        -I "${helloworld_proto_path}"
        --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
        "${helloworld_proto}"
      DEPENDS "${helloworld_proto}")

# helloworld_grpc_proto
add_library(helloworld_grpc_proto
  ${helloworld_grpc_srcs}
  ${helloworld_grpc_hdrs}
  ${helloworld_proto_srcs}
  ${helloworld_proto_hdrs})

# Include generated *.pb.h files
target_include_directories(helloworld_grpc_proto PUBLIC "${GENERATED_FILES_LOCATION}")

target_link_libraries(helloworld_grpc_proto
  ${_REFLECTION}
  ${_GRPC_GRPCPP}
  ${_PROTOBUF_LIBPROTOBUF})
