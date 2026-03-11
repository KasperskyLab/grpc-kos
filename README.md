# KasperskyOS adaptation patch for gRPC

This project provides an adaptation patch for
[gRPC® (Google Remote Procedure Call)](https://github.com/grpc/grpc), enabling its use in
KasperskyOS-based solutions. The project is based on the
[1.48.0](https://github.com/grpc/grpc/tree/v1.48.0) version.

gRPC is a high-performance framework for developing distributed systems. It uses HTTP/2 and
[Protocol Buffers (Protobuf™)](https://github.com/google/protobuf) as the underlying protocols for
data exchange between clients and servers.

For additional details on KasperskyOS, including its limitations and known issues, please refer to
the [KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.4&customization=KCE&helpid=community_edition).

## Table of contents
- [KasperskyOS adaptation patch for gRPC](#kasperskyos-adaptation-patch-for-grpc)
  - [Table of contents](#table-of-contents)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building and installing](#building-and-installing)
      - [Protoc compiler](#protoc-compiler)
      - [Build gRPC for Linux host operating system](#build-grpc-for-linux-host-operating-system)
      - [Build gRPC for KasperskyOS](#build-grpc-for-kasperskyos)
  - [Usage](#usage)
  - [Trademarks](#trademarks)
  - [Contributing](#contributing)
  - [Licensing](#licensing)

## Getting started

### Prerequisites

1. Confirm that your host system meets all the
[System requirements](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.4&customization=KCE&helpid=system_requirements)
listed in the KasperskyOS Community Edition Developer's Guide.
1. [Install](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.4&customization=KCE&helpid=sdk_install_and_remove)
the KasperskyOS Community Edition SDK version 1.4. You can download it for free from
[os.kaspersky.com](https://os.kaspersky.com/development/).
1. Copy the source files of this adaptation patch to your local project directory.
1. Source the SDK setup script to configure the build environment. This exports the `KOSCEDIR`
  environment variable, which points to the SDK installation directory:
   ```sh
   source /opt/KasperskyOS-Community-Edition-<platform>-<version>/common/set_env.sh
   ```

### Building and installing

The KasperskyOS-adapted version of gRPC is built using the CMake build system, which is provided in
the KasperskyOS Community Edition SDK. When you develop a KasperskyOS-based solution, use the
[recommended structure of project directories](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.4&customization=KCE&helpid=cmake_using_sdk_cmake)
to simplify the use of CMake scripts.

In order to use gRPC for KasperskyOS and the host, it is necessary to install gRPC on both
platforms. It is recommended to use the same gRPC version for KasperskyOS and other platforms.

#### Protoc compiler

By default, gRPC uses protocol buffers. You will need the `protoc` compiler to generate stub server
and client code.

If you compile gRPC from source, the build system will automatically try to compile the `protoc`
compiler. This will happen if you have recursively cloned the repository and it detects that the
`protoc` compiler has not been installed on your system yet.

#### Build gRPC for Linux host operating system

gRPC is cross-compiled on the host where the KasperskyOS Community Edition SDK is installed. To
compile `*.proto` files and use gRPC plugins, it is necessary to first build and install gRPC for
the host. The `protoc` compiler (used to compile `*.proto` files) must be built with the host
toolchain. This is because the `protoc` will be run on the host when building solutions for
KasperskyOS.

To build and install gRPC for the host, execute the following commands:
```sh
cmake -B build/host \
      -D CMAKE_INSTALL_PREFIX=~/.local/share/kos/$(basename $KOSCEDIR)/toolchain
cmake --build build/host -j`nproc` --target install
```

Set `CMAKE_INSTALL_PREFIX` to your preferred installation path. For compatibility with the
[gRPC example](https://github.com/KasperskyLab/kos-ce-extra/tree/master/examples/grpc), we recommend
setting the `CMAKE_INSTALL_PREFIX` to `~/.local/share/kos/$(basename $KOSCEDIR)/toolchain`.

#### Build gRPC for KasperskyOS

To build and install gRPC for KasperskyOS, execute the following commands:

```sh
cmake -B build/kos \
      -D CMAKE_TOOLCHAIN_FILE=$KOSCEDIR/toolchain/share/toolchain-aarch64-kos.cmake \
      -D CMAKE_SYSTEM_PREFIX_PATH=~/.local/share/kos/$(basename $KOSCEDIR)/toolchain \
      -D CMAKE_INSTALL_PREFIX=~/.local/share/kos/$(basename $KOSCEDIR)/sysroot-aarch64-kos
cmake --build build/kos -j`nproc` --target install
```

Set `CMAKE_INSTALL_PREFIX` to your preferred installation path. To ensure the build system can
locate the host gRPC dependencies, point `CMAKE_SYSTEM_PREFIX_PATH` to the directory where you
installed gRPC for the host.

[⬆ Back to Top](#table-of-contents)

## Usage

To integrate the KasperskyOS-adapted gRPC into your solution, first build and install
it for the [host](#build-grpc-for-linux-host-operating-system) and
[KasperskyOS](#build-grpc-for-kasperskyos).

For a practical implementation of using gRPC in KasperskyOS, refer to the
[gRPC example](https://github.com/KasperskyLab/kos-ce-extra/tree/master/examples/grpc) in the
`KasperskyLab/kos-ce-extra` repository, which demonstrates this exact workflow.

## Trademarks

Registered trademarks and endpoint marks are the property of their respective owners.

AIX is a trademark of International Business Machines Corporation, registered in many jurisdictions
worldwide.

Android, Google, and PROTOBUF are trademarks of Google LLC.

Apache is either a registered trademark or a trademark of the Apache Software Foundation in the
United States and/or other countries.

Apple, macOS, and Objective-C are trademarks of Apple Inc.

Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc. in the United
States and/or other countries. Docker, Inc. and other parties may also have trademark rights in
other terms used herein.

FreeBSD is a registered trademark of The FreeBSD Foundation.

GITHUB is a trademark of GitHub, Inc., registered in the United States and other countries.

GRPC is a registered trademark of The Linux Foundation in the United States and other countries.

Linux is the registered trademark of Linus Torvalds in the U.S. and other countries.

Python is a trademark or registered trademark of the Python Software Foundation.

Raspberry Pi is a trademark of the Raspberry Pi Foundation.

Solaris is a registered trademark of Oracle and/or its affiliates.

UNIX is a registered trademark in the United States and other countries, licensed exclusively
through X/Open Company Limited.

Visual Studio, Win32, and Windows are trademarks of the Microsoft group of companies.

## Contributing

Only KasperskyOS-specific changes can be approved. See [CONTRIBUTING.md](CONTRIBUTING.md) for
detailed instructions on code contribution.

## Licensing

This project is licensed under the terms of the MIT license. See [LICENSE](LICENSE) for more information.

This project comprises publication(s) intended to be used with [gRPC library](https://github.com/grpc/grpc/tree/v1.48.0) ( “Upstream Project”).
The Upstream Project is licensed and distributed under its own license terms, which are separate from the terms of this project.
Nothing in this repository is intended to modify, replace, supersede, or relicense the Upstream Project or any of its components.

© 2026 AO Kaspersky Lab
