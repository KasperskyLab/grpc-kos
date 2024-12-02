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

###
# Helper function to create GTest unit test with test generator.
# Arguments:
#   TEST_TARGET   - exacutable target that represents test.
#   ARGS          - tests command line arguments.
#   ENV_VARIABLES - environment variables that will be set while test runs.
#   FILES         - files that will be added to test kos-image.
#   FILES_TO_COPY - list of string that has format "path_to_files_need_by_test:path_where_it_should_be_placed".
#   DEPENDS_ON    - extra programs that test depends on.
function(add_gtest_target TEST_TARGET)
  set(MULTI_VAL_ARGS FILES FILES_TO_COPY ENV_VARIABLES ARGS DEPENDS_ON)
  cmake_parse_arguments(TEST "" "" "${MULTI_VAL_ARGS}" ${ARGN})

  get_entity_name(${TEST_TARGET} TEST_ENTITY_NAME)
  message(STATUS "TEST_NAME=${TEST_ENTITY_NAME}")
  generate_edl_file(${TEST_ENTITY_NAME})
  nk_build_edl_files(${TEST_TARGET}_edl_files EDL ${EDL_FILE})
  add_dependencies(${TEST_TARGET} ${TEST_TARGET}_edl_files)
  target_link_libraries(${TEST_TARGET} ${vfs_CLIENT_LIB})
  set_target_properties(${TEST_TARGET}
    PROPERTIES
      ${vfs_ENTITY}_REPLACEMENT ""
      DEPENDS_ON_ENTITY "${TEST_DEPENDS_ON}"
  )

  ## Usefull for debug
  #target_compile_options(${TEST_TARGET} PRIVATE -O0)
  #target_compile_definitions(${TEST_TARGET} PRIVATE LOG_VERBOSITY=LOG_TRACE)
  #set_target_properties(${TEST_TARGET} PROPERTIES LINK_FLAGS "-no-pie -Ttext 0x00800000")

  unset(vfs_ENTITY)
  generate_kos_test(
    ENTITY_NAME ${TEST_ENTITY_NAME}
    TARGET_NAME ${TEST_TARGET}
    TEST_TYPE gtest
    ARGUMENTS ${TEST_ARGS}
    VARIABLES ${TEST_ENV_VARIABLES}
    WITH_NETWORK ON
    ENTITY_HAS_VFS YES
    FILES ${TEST_FILES}
    FILES_TO_COPY ${TEST_FILES_TO_COPY}
  )
endfunction()
