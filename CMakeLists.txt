# © 2026 AO Kaspersky Lab
# Licensed under the MIT License

cmake_minimum_required (VERSION 3.29)

project (grpc-kos LANGUAGES C CXX)

include (FetchContent)

# Override default options for KasperskyOS gRPC builds.
option (RE2_BUILD_TESTING                  "Build RE2 tests"                     OFF)
option (protobuf_BUILD_PROTOC_BINARIES     "Build libprotoc and protoc compiler" ON)
option (gRPC_BUILD_TESTS                   "Build gRPC tests"                    OFF)
option (gRPC_BUILD_GRPC_CSHARP_PLUGIN      "Build C# plugin"                     OFF)
option (gRPC_BUILD_GRPC_NODE_PLUGIN        "Build Node plugin"                   OFF)
option (gRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN "Build Objective-C plugin"            OFF)
option (gRPC_BUILD_GRPC_PHP_PLUGIN         "Build PHP plugin"                    OFF)
option (gRPC_BUILD_GRPC_PYTHON_PLUGIN      "Build Python plugin"                 OFF)
option (gRPC_BUILD_GRPC_RUBY_PLUGIN        "Build Ruby plugin"                   OFF)
option (gRPC_INSTALL                       "Generate installation target"        ON)

set (gRPC_CARES_PROVIDER    "download" CACHE STRING "Provider of c-ares library")
set (gRPC_SSL_PROVIDER      "download" CACHE STRING "Provider of ssl library")
set (gRPC_PROTOBUF_PROVIDER "download" CACHE STRING "Provider of protobuf library")
set (gRPC_ABSL_PROVIDER     "download" CACHE STRING "Provider of absl library")

if (KOS)
    set (gRPC_ZLIB_PROVIDER "package" CACHE STRING "ZLIB provider for gRPC")
endif ()

# Configure the source location and patch application for gRPC.
# The official gRPC repository.
set (GIT_REPOSITORY https://github.com/grpc/grpc.git)
# Specific version to fetch.
set (GIT_TAG        v1.71.0)
# Apply KasperskyOS adaptation patch after downloading.
set (GIT_PATCH      ${CMAKE_CURRENT_LIST_DIR}/KasperskyOS-CE-adaptation.patch)
set (PATCH_COMMAND  git apply ${GIT_PATCH})
set (GIT_SUBMODULES third_party/envoy-api
                    third_party/googleapis
                    third_party/opencensus-proto
                    third_party/opentelemetry
                    third_party/opentelemetry-cpp
                    third_party/protoc-gen-validate
                    third_party/re2
                    third_party/xds
                    third_party/zlib)

# Prevent redundant patch application on subsequent builds.
if (GRPC_POPULATED)
    # Library has already been fetched — skip patching to avoid conflicts.
    set (PATCH_COMMAND)
else ()
    message (STATUS "Downloading grpc ${GIT_TAG}")
endif ()

# Declare the external dependency with patch configuration.
FetchContent_Declare (grpc
                      GIT_REPOSITORY ${GIT_REPOSITORY}
                      GIT_TAG        ${GIT_TAG}
                      GIT_SHALLOW    YES
                      GIT_SUBMODULES ${GIT_SUBMODULES}
                      PATCH_COMMAND  ${PATCH_COMMAND})

# Execute the download and integration of gRPC into the build system.
FetchContent_MakeAvailable (grpc)

# Cache the population state to optimize subsequent builds.
set (GRPC_POPULATED ${grpc_POPULATED} CACHE INTERNAL "")
