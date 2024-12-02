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

add_library(utility_lib
  CommandLineArg.h
  CommandLineArg.cc
  FileUtility.h
  FileUtility.cc
)

target_compile_features(utility_lib PRIVATE cxx_std_17)
target_include_directories(utility_lib PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
