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

project(client)

# Set the SSL_CERTS variable to the full name of the CA's public key file,
# that will be used to verify certificate signatures.
set(SSL_CERTS "${SSL_CERTIFICATE_DIR}/ca.pem")

add_executable(GreeterClient
  src/main.cc
  src/greeter_client.h
  src/greeter_client.cc
)

target_compile_features(GreeterClient PRIVATE cxx_std_17)

target_link_libraries(GreeterClient
  helloworld_grpc_proto
  utility_lib
)

if(KOS)
  nk_build_edl_files(HelloWorld_client_edl_files
    NK_MODULE "helloworld"
    EDL "${RESOURCES}/edl/GreeterClient.edl"
  )

  add_dependencies(GreeterClient HelloWorld_client_edl_files)

  target_link_libraries(GreeterClient ${vfs_CLIENT_LIB})

  set(MAIN_TASK GreeterClient PARENT_SCOPE)
  set(SSL_CERTS ${SSL_CERTS}  PARENT_SCOPE)
else()
  add_custom_command(TARGET GreeterClient POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${SSL_CERTS} ${CMAKE_CURRENT_BINARY_DIR}
  )
endif()
