# KasperskyOS modification of gRPC

gRPC® (Google Remote Procedure Call) is a high-performance framework for developing distributed systems.
It uses HTTP/2 and [Protocol Buffers (Protobuf™)](https://github.com/google/protobuf) as the underlying
protocols for data exchange between clients and servers.

This project is an adaptation of gRPC for KasperskyOS. It is based on the original version of
[grpc 1.48.0](https://github.com/grpc/grpc/tree/v1.48.0) and includes an example that demonstrates its
use in KasperskyOS.

For additional details on KasperskyOS, including its limitations and known issues, please refer to the
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_community_edition).

## Table of contents
- [KasperskyOS modification of gRPC](#kasperskyos-modification-of-grpc)
  - [Table of contents](#table-of-contents)
  - [Overview](#overview)
    - [Repository status](#repository-status)
    - [Interface](#interface)
    - [Surface API](#surface-api)
      - [Synchronous vs. asynchronous](#synchronous-vs-asynchronous)
  - [Streaming](#streaming)
  - [Protocol](#protocol)
    - [Abstract gRPC protocol](#abstract-grpc-protocol)
    - [Implementation over HTTP/2](#implementation-over-http2)
    - [Flow control](#flow-control)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building and installing](#building-and-installing)
      - [Protoc compiler](#protoc-compiler)
      - [Build gRPC for Linux host operation system](#build-grpc-for-linux-host-operation-system)
      - [Build gRPC for KasperskyOS](#build-grpc-for-kasperskyos)
      - [Tests](#tests)
  - [Usage](#usage)
- [Trademarks](#trademarks)
- [Contributing](#contributing)
- [Licensing](#licensing)

## Overview

Remote Procedure Calls (RPCs) provide a useful abstraction for building distributed applications and services.
The libraries in this repository provide a concrete implementation of the gRPC protocol, layered over HTTP/2.
These libraries enable communication between clients and servers using any combination of the supported languages.

### Repository status

This repository contains source code for gRPC libraries for multiple languages written on top of shared C core library
[./src/core](src/core), but the KasperskyOS adaptation is realized only for C++.

| Language                | Source                              | Status  | KasperskyOS adaptation |
|-------------------------|-------------------------------------|---------|------------------------|
| Shared C [core library] | [src/core](src/core)                | 1.8     |       Yes              |
| C++                     | [src/cpp](src/cpp)                  | 1.8     |       Yes              |

### Interface

Developers using gRPC typically start with the description of an RPC service (a collection of methods),
and generate client and server side interfaces which they use on the client-side and implement on the server side.

By default, gRPC uses Protocol Buffers as the gRPC Interface Definition Language (IDL) for describing both the service interface
and the structure of the payload messages. It is possible to use other alternatives if desired.

### Surface API

Starting from an interface definition in a `*.proto` file, gRPC provides Protocol Compiler plugins that generate Client- and
Server-side APIs. gRPC users typically call into these APIs on the Client side and implement the corresponding API on the server side.

#### Synchronous vs. asynchronous

Synchronous RPC calls, that block until a response arrives from the server,
are the closest approximation to the abstraction of a procedure call that RPC aspires to.

On the other hand, networks are inherently asynchronous and in many scenarios,
it is desirable to have the ability to start RPCs without blocking the current thread.

The gRPC programming surface in most languages comes in both synchronous and asynchronous flavors.

[⬆ Back to Top](#Table-of-contents)

## Streaming

gRPC supports streaming semantics, where either the client or the server (or both) sends a stream of messages on a single RPC call.
The most general case is Bidirectional Streaming where a single gRPC call establishes a stream where both the client and the server
can send a stream of messages to each other. The streamed messages are delivered in the order they were sent.

## Protocol

The [gRPC protocol](doc/PROTOCOL-HTTP2.md) specifies the abstract requirements for communication between clients and servers.
A concrete embedding over HTTP/2 completes the picture by fleshing out the details of each of the required operations.

### Abstract gRPC protocol

A gRPC comprises of a bidirectional stream of messages, initiated by the client. In the client-to-server direction,
this stream begins with a mandatory `Call Header`, followed by optional `Initial-Metadata`, followed by zero or more `Payload Messages`.
The server-to-client direction contains an optional `Initial-Metadata`, followed by zero or more `Payload Messages` terminated
with a mandatory `Status` and optional `Status-Metadata` (or `Trailing-Metadata`).

### Implementation over HTTP/2

The abstract gRPC protocol is implemented over [HTTP/2](https://http2.github.io/).
gRPC bidirectional streams are mapped to HTTP/2 streams.
The contents of `Call Header` and `Initial Metadata` are sent as HTTP/2 headers and subject to HPACK compression.
`Payload Messages` are serialized into a byte stream of length prefixed gRPC frames
which are then fragmented into HTTP/2 frames at the sender and reassembled at the receiver.
`Status` and `Trailing-Metadata` are sent as HTTP/2 trailing headers (or trailers).

### Flow control

gRPC inherits the flow control mechanisms in HTTP/2 and uses them
to enable fine-grained control of the amount of memory used for buffering in-flight messages.

[⬆ Back to Top](#Table-of-contents)

## Getting started

### Prerequisites

1. [Install](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_sdk_install_and_remove)
KasperskyOS Community Edition SDK. You can download the latest version of the KasperskyOS Community Edition for free from
[os.kaspersky.com](https://os.kaspersky.com/development/). The minimum required version of KasperskyOS Community Edition SDK is 1.2.
For more information, see [System requirements](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_system_requirements).
1. Clone gRPC for KasperskyOS repository to your project directory (to reduce cloning time you can use `--depth 1` option):
    ```sh
     $ git clone --recurse-submodules --shallow-submodules https://github.com/KasperskyLab/grpc-kos.git
    ```

### Building and installing

gRPC is built using the CMake build system, which is provided in the KasperskyOS Community Edition SDK.
In order to use gRPC for KasperskyOS and the host, it is necessary to install gRPC on both platforms.
It is recommended to use the same gRPC version for KasperskyOS and other platforms.

#### Protoc compiler

By default, gRPC uses protocol buffers, you will need the `protoc` compiler to generate stub server and client code.

If you compile gRPC from source, the Makefile will automatically try to compile the `protoc` compiler from the
[./third_party](third_party) directory. This will happen if you have recursively cloned the repository and it detects
that the `protoc` compiler has not installed on your system yet.

#### Build gRPC for Linux host operation system

The gRPC is cross-compiled on the host where the KasperskyOS Community Edition SDK is installed.
To compile `*.proto` files and use gRPC plugins, it is necessary to first build and install gRPC for the host.
The `protoc` compiler (used to compile `*.proto` files) must be built with the host toolchain.
This is because the `protoc` will be run on the host when building solutions for KasperskyOS.

To build and install gRPC for the host, go to the `./kos` directory and execute the [`host-build.sh`](./kos/host-build.sh) script.
The environment variable `INSTALL_PREFIX` specifies the installation path of gRPC for the host.
If not specified, gRPC for the host will be installed in the `./install/host` directory.

Syntax for using the `host-build.sh` script:
```sh
$ host-build.sh [-i INSTALL_PREFIX]
```
The parameter `-i, --install-prefix INSTALL_PREFIX` specifies the installation path of gRPC for the host.
The value specified in this parameter takes precedence over the value of the `INSTALL_PREFIX` environment variable.

By default, the build type is set to `Debug`, the build libraries are static,
and the build path is set to `./build/host`. To change this, edit the `host-build.sh` script as needed.

For example:
```sh
$ ./host-build.sh
```

You also can build gRPC for corresponding host [manually](BUILDING.md).

[⬆ Back to Top](#Table-of-contents)

#### Build gRPC for KasperskyOS

To build and install gRPC for KasperskyOS, go to the `./kos` directory and execute the [`cross-build.sh`](./kos/cross-build.sh) script.
There are environment variables that affect the build and installation of the libraries:

* `SDK_PREFIX` specifies the path to the installed version of the KasperskyOS Community Edition SDK.
* `INSTALL_PREFIX` specifies the installation path of gRPC for KasperskyOS.
If not specified, the libraries will be installed in the `./install/kos` directory.
* `TARGET` specifies the target platform. If not specified, the platform will be determined automatically.

Syntax for using the `cross-build.sh` script:

`$ SDK_PREFIX=/opt/KasperskyOS-Community-Edition-<version> [TARGET="aarch64-kos"] ./cross-build.sh [-h] [-s PATH] [-i PATH] [-H PATH] [-j N]`,

where:

* `version`

  Latest version number of the [KasperskyOS Community Edition SDK](https://os.kaspersky.com/development/).
* `-h, --help`

  Help text.
* `-s, --sdk PATH`

  Path to the installed version of the KasperskyOS Community Edition SDK.
The path must be set using either the value of the `SDK_PREFIX` environment variable or the `-s` option.
The value specified in the `-s` option takes precedence over the value of the `SDK_PREFIX` environment variable.
* `-i, --install PATH`

  Path to directory where gRPC for KasperskyOS will be installed. If not specified, the default path `./install/kos` will be used.
The value specified in the `-i` option takes precedence over the value of the `INSTALL_PREFIX` environment variable.
* `-H, --host-install PATH`

  Path to the directory where gRPC for the host is installed. If not specified, the default path `./install/host` will be used.
* `-j, --jobs N`

  Number of jobs for parallel build. If not specified, the default value obtained from the `nproc` command is used.

By default, the build type is set to `Debug`, the build libraries are static,
and the build path is set to `./build/kos`. To change this, edit the `cross-build.sh` script as needed.

For CMake build system to find gRPC for KasperskyOS, make sure that the directory where the libraries were installed
is listed in the `CMAKE_FIND_ROOT_PATH` environment variable.

The `cross-build.sh` script builds only runtime libraries.
The host `protoc` compiler and `gRPC plugin` are used to generate source files from `*.proto` files.

[⬆ Back to Top](#Table-of-contents)

#### Tests

The C++ gRPC tests have been adapted to run on KasperskyOS.
The CMake files for building the tests are located in the [`./test/kos`](test/kos/cmake/) directory.
The tests have the following limitations:

* Some tests are disabled. See the list at
[./test/kos/cmake/grpc_cpp_disabled_tests.cmake](test/kos/cmake/grpc_cpp_disabled_tests.cmake).
* Death tests not supported on KasperskyOS.
* Some tests are skipped. See the list at [./test/kos/cmake/tests.cmake](test/kos/cmake/tests.cmake).
* Flaky tests:
  * `streaming_throughput_test`
  * `async_end2end_test`
  * `cli_call_test`
  * `client_interceptors_end2end_test`
  * `context_allocator_end2end_test`
  * `delegating_channel_test`
  * `google_c2p_resolver_test`
  * `grpc_authz_end2end_test`
  * `service_config_end2end_test`
  * `shutdown_test`
  * `xds_credentials_end2end_test`
* C++ unit tests for KasperskyOS are currently available only for QEMU.

Tests use an out-of-source build. The build tree is situated in the generated `./build/kos_tests` directory.
For each test suite, a separate image will be created. As it can be taxing on disk space, the tests will run sequentially.

To build and run the tests, go to the `./kos` directory and execute the [`run-tests.sh`](./kos/run-tests.sh) script.
There are environment variables that affect the build and installation of the tests:

* `SDK_PREFIX` specifies the path to the installed version of the KasperskyOS Community Edition SDK.
* `TARGET` specifies the target platform. (Currently only the `aarch64-kos` platform is supported.)

Syntax for using the `run-tests.sh` script:

`$ SDK_PREFIX=/opt/KasperskyOS-Community-Edition-<version> [TARGET="aarch64-kos"] ./run-tests.sh [--help] [-s PATH] [--list] [-n TEST_1] ... [-n TEST_N] [-t SEC] [-o PATH] [-j N] [-H PATH]`,

where:

* `version`

  Latest version number of the [KasperskyOS Community Edition SDK](https://os.kaspersky.com/development/).
* `-h, --help`

  Help text.
* `-s, --sdk PATH`

  Path to the installed version of the KasperskyOS Community Edition SDK.
The path must be set using either the value of the `SDK_PREFIX` environment variable or the `-s` option.
The value specified in the `-s` option takes precedence over the value of the `SDK_PREFIX` environment variable.
* `-l, --list`

  List of tests that can be run.
* `-n, --name TEST`

  Test name to execute. The parameter can be repeated multiple times.
If not specified, all tests will be executed.
* `-t, --timeout SEC`

  Time, in seconds, allotted to start and execute a single test case. Default value is 3000 seconds.
* `-o, --out PATH`

  Path where the results of the test run will be stored. If not specified, the results will be stored in the `./build/kos_tests/logs` directory.
* `-j, --jobs N`

  Number of jobs for parallel build. If not specified, the default value obtained from the `nproc` command is used.
* `-H, --host-install PATH`

  Path to the directory where gRPC for the host is installed. If not specified, the default path `./install/host` will be used.

[⬆ Back to Top](#Table-of-contents)

## Usage

When you develop a KasperskyOS-based solution, use the
[recommended structure of project directories](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_cmake_using_sdk_cmake)
to simplify usage of CMake scripts.

For more on using gRPC in KasperskyOS, see the [README.md](./examples/kos/helloworld/README.md) file for the project's example.

# Trademarks

Registered trademarks and endpoint marks are the property of their respective owners.

gRPC is a registered trademark of The Linux Foundation in the United States and other countries.

GoogleTest, Protobuf are a trademark of Google LLC.

Linux is the registered trademark of Linus Torvalds in the U.S. and other countries.

Raspberry Pi is a trademark of the Raspberry Pi Foundation.

# Contributing

Only KasperskyOS-specific changes can be approved. See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed instructions on code contribution.

# Licensing

This project is licensed under the terms of the Apache License 2.0 license. See [LICENSE](LICENSE) for more information.

[⬆ Back to Top](#Table-of-contents)

© 2024 AO Kaspersky Lab
