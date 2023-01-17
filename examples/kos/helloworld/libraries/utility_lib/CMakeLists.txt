# © 2022 AO Kaspersky Lab. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

add_library(utility_lib
    CommandLineArg.h
    CommandLineArg.cc
    FileUtility.h
    FileUtility.cc)

target_compile_features (utility_lib PRIVATE cxx_std_17)
target_include_directories(utility_lib PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")

