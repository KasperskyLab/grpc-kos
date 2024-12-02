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

project(server)

# The location of SSL certifates for secure connection
set(SSL_CERTS
  "${SSL_CERTIFICATE_DIR}/ca.pem"
  "${SSL_CERTIFICATE_DIR}/server1.pem"
  "${SSL_CERTIFICATE_DIR}/server1.key"
)

add_executable(GreeterServer
  src/main.cc
  src/greeter_service_impl.h
  src/greeter_service_impl.cc
)

target_compile_features(GreeterServer PRIVATE cxx_std_17)

target_link_libraries(GreeterServer
  helloworld_grpc_proto
  utility_lib
)

if(KOS)
  nk_build_edl_files(HelloWorld_server_edl_files
    NK_MODULE "helloworld"
    EDL "${RESOURCES}/edl/GreeterServer.edl"
  )
  add_dependencies(GreeterServer HelloWorld_server_edl_files)
  target_link_libraries(GreeterServer
    ${vfs_CLIENT_LIB}
    ${CMAKE_THREAD_LIBS_INIT}
  )
  set(MAIN_TASK GreeterServer PARENT_SCOPE)
  set(SSL_CERTS ${SSL_CERTS}  PARENT_SCOPE)
else()
  add_custom_command(TARGET GreeterServer POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${SSL_CERTS} ${CMAKE_CURRENT_BINARY_DIR}
  )
endif()
