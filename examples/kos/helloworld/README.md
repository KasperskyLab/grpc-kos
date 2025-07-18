# Hello World example

This solution is a modification of the gRPC HelloWorld C++ example, adapted specifically for KasperskyOS.
The example showcases four distinct scenarios of interaction between a client and a server,
facilitated through either a secure Remote Procedure Call (RPC) channel,
which employs Secure Sockets Layer (SSL)/Transport Layer Security (TLS) authentication, or an insecure RPC channel:

* Scenario 1: Insecure communication between a Linux server and a KasperskyOS client
* Scenario 2: Insecure communication between a KasperskyOS server and a Linux client
* Scenario 3: Secure communication between a Linux server and a KasperskyOS client
* Scenario 4: Secure communication between a KasperskyOS server and a Linux client

## Table of contents
- [Hello World example](#hello-world-example)
  - [Table of contents](#table-of-contents)
  - [Solution overview](#solution-overview)
    - [List of programs](#list-of-programs)
    - [General scenario](#general-scenario)
    - [Initialization description](#initialization-description)
    - [Security policy description](#security-policy-description)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building and running the example](#building-and-running-the-example)
      - [QEMU](#qemu)
        - [Scenarios 1 and 3](#scenarios-1-and-3)
        - [Scenarios 2 and 4](#scenarios-2-and-4)
      - [Hardware](#hardware)
        - [Scenarios 1 and 3](#scenarios-1-and-3-1)
        - [Scenarios 2 and 4](#scenarios-2-and-4-1)
      - [CMake input files](#cmake-input-files)
  - [Usage](#usage)
    - [Scenario 1](#scenario-1)
    - [Scenario 2](#scenario-2)
    - [Scenario 3](#scenario-3)
    - [Scenario 4](#scenario-4)

## Solution overview

### List of programs

* `GreeterClient`—Program serves as the client in different scenarios, acting as the KasperskyOS client in scenarios 1 and 3,
and as the Linux client in scenarios 2 and 4.
* `GreeterServer`—Program serves as the server that implements a gRPC service in different scenarios, acting as the KasperskyOS server
in scenarios 2 and 4, and as the Linux server in scenarios 1 and 3.
* `VfsNet`—Program that is used for working with the network.
* `Dhcpcd`—DHCP client implementation program that gets network interface parameters from an external DHCP server in the background and
passes them to the virtual file system.
* `DNetSrv`—Driver for working with network cards.
* `VfsSdCardFs`—Program that supports the SD card file system.
* `BlobContainer`—Program that loads dynamic libraries used by other programs into shared memory.
* `SDCard`—SD card driver.
* `EntropyEntity`—Random number generator.
* `BSP`—Driver for configuring pin multiplexing parameters (pinmux).
* `Ntpd`—Program that sets and maintains the system time of day in synchronism with Internet standard time servers.
* `Bcm2711MboxArmToVc`—Driver for working with the VideoCore (VC6) coprocessor via mailbox technology for Raspberry Pi 4 B.

### General scenario

This is a general scenario that showcases how the client and server interact with each other by exchanging
requests and responses using the gRPC protocol:

1. The server is launched and starts listening on the specified address for incoming connections.
The server can be run in secure mode by providing the `--secure` command line argument.
In secure mode, it uses SSL/TLS for secure communication with the client.
1. The client is launched and creates a channel to connect to the server specified by the `--target` command line argument.
The client can be run in secure mode by providing the `--secure` command line argument.
In secure mode, it uses SSL/TLS for secure communication with the server.
1. The client sends requests to the server using a `SayHello()` method and waits for the response.
1. The server receives the request from the client, processes it by adding a prefix to the name in the request,
and returns a response with the prefix.
1. The client receives the response from the server and displays it in the standard output.
The client repeats this process 20,000 times with a 2-second interval between each request.
1. Once the interaction is completed, both the client and the server close the connection and terminate their execution.

[⬆ Back to Top](#table-of-contents)

### Initialization description

<details><summary>Statically created IPC channels that are used in all scenarios</summary>

* `kl.bc.BlobContainer` → `kl.VfsSdCardFs`
* `kl.VfsSdCardFs` → `kl.drivers.SDCard`
* `kl.VfsSdCardFs` → `kl.EntropyEntity`
* `kl.VfsSdCardFs` → `kl.bc.BlobContainer`
* `kl.VfsNet` → `kl.EntropyEntity`
* `kl.VfsNet` → `kl.drivers.DNetSrv`
* `kl.VfsNet` → `kl.bc.BlobContainer`
* `kl.rump.Dhcpcd` → `kl.VfsNet`
* `kl.rump.Dhcpcd` → `kl.VfsSdCardFs`
* `kl.rump.Dhcpcd` → `kl.bc.BlobContainer`
* `kl.drivers.SDCard` → `kl.drivers.BSP`
* `kl.drivers.SDCard` → `kl.bc.BlobContainer`
* `kl.EntropyEntity` → `kl.bc.BlobContainer`
* `kl.drivers.DNetSrv` → `kl.drivers.Bcm2711MboxArmToVc`
* `kl.drivers.DNetSrv` → `kl.bc.BlobContainer`
* `kl.drivers.BSP` → `kl.bc.BlobContainer`
* `kl.drivers.Bcm2711MboxArmToVc` → `kl.bc.BlobContainer`
* `kl.Ntpd` → `kl.VfsSdCardFs`
* `kl.Ntpd` → `kl.VfsNet`

</details>

<details><summary>Statically created IPC channels that are used only in scenarios 1 and 3</summary>

* `helloworld.GreeterClient` → `kl.VfsSdCardFs`
* `helloworld.GreeterClient` → `kl.VfsNet`
* `helloworld.GreeterClient` → `kl.bc.BlobContainer`

</details>

<details><summary>Statically created IPC channels that are used only in scenarios 2 and 4</summary>

* `helloworld.GreeterServer` → `kl.VfsSdCardFs`
* `helloworld.GreeterServer` → `kl.VfsNet`
* `helloworld.GreeterServer` → `kl.bc.BlobContainer`

</details>

The [`./einit/src/client.init.yaml.in`](einit/src/client.init.yaml.in) and the
[`./einit/src/server.init.yaml.in`](einit/src/server.init.yaml.in) templates are used to automatically generate part of the solution
initialization description file `init.yaml`. For more information about the `init.yaml.in` template file, see the
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=cmake_yaml_templates).

[⬆ Back to Top](#table-of-contents)

### Security policy description

The [`./einit/src/security.psl.in`](einit/src/security.psl.in) template is used to automatically generate part of the `security.psl` file
using CMake tools. The `security.psl` file contains part of a solution security policy description.
For more information about the `security.psl` file, see
[Describing a security policy for a KasperskyOS-based solution](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=ssp_descr).

[⬆ Back to Top](#table-of-contents)

## Getting started

### Prerequisites

1. To install [KasperskyOS Community Edition SDK](https://os.kaspersky.com/development/)
and run examples on a hardware platform, make sure you meet all the
[System requirements](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=system_requirements)
listed in the KasperskyOS Community Edition Developer's Guide.
    * Add the path to the KasperskyOS SDK toolchain to the PATH environment variable `export PATH=/opt/KasperskyOS-Community-Edition-<SDK-version>/toolchain/bin:$PATH`.
1. You have built and installed gRPC for Linux host operation system.
1. You have built and installed gRPC for KasperskyOS.
1. If you have previously built the example, delete the `./build` directory with artifacts from the previous build.
1. You have installed NTP for Linux host operation system.

[⬆ Back to Top](#table-of-contents)

### Building and running the example

The example is built using the CMake build system, which is provided in the KasperskyOS Community Edition SDK.
In the directory with the example there are two scripts:

* `build.sh` for building and running images in Linux;
* `cross-build.sh` for building and running images in KasperskyOS.

Syntax for using the `build.sh` script:

`$ ./build.sh <TARGET> [-H PATH] [-S] [-j N_JOBS] [-h]`,

where:

* `TARGET`

  Type of program to be built: `server` for building the server or `client` for building the client.
* `-H, --host-install PATH`

  Path to the directory where gRPC for the host is installed. If not specified, the default path `<root_directory>/install/host` will be used,
where `root_directory` is the root directory containing the project's source files.
* `-S, --secure`

  Parameter specifies the use of a secure connection. When specified, SSL/TLS authentication will be used.
* `-j, --jobs N_JOBS`

  Number of jobs for parallel build. If not specified, the default value obtained from the `nproc` command is used.
* `-h, --help`

  Help text.

Syntax for using the `cross-build.sh` script:

`$ ./cross-build.sh <TARGET> [-s PATH] [-p PLATFORM] [-K PATH] [-H PATH] [-S] [-j N_JOBS] [-h]`,

where:

* `TARGET`

  Type of program to be built: `server` for building the server or `client` for building the client.
* `-s, --sdk PATH`

  Path to the installed version of the KasperskyOS Community Edition SDK.
The value specified in the `-s` option takes precedence over the value of the `SDK_PREFIX` environment variable.
* `-p, --platform PLATFORM`

  Target platform for the build. It can take one of the following values:

  * `qemu` to build a KasperskyOS-based solution image named `kos-qemu-image` that includes the KasperskyOS server/client
and to run this solution on QEMU.
  * `image` to build a KasperskyOS-based solution image named `kos-image` that includes the KasperskyOS server/client.
This image is for running on supported hardware.
  * `sdimage` to create a file system image for a bootable device for hardware. The following is loaded into the file system image:
`kos-image`, U-Boot bootloader that starts the example, and the firmware for supported hardware.
* `-K, --kos-install PATH`

  Path to directory where gRPC for KasperskyOS is installed. If not specified, the default path `<root_directory>/install/kos` will be used,
where `root_directory` is the root directory containing the project's source files.
* `-H, --host-install PATH`

  Path to the directory where gRPC for the host is installed. If not specified, the default path `<root_directory>/install/host` will be used.
* `-S, --secure`

  Parameter specifies the use of a secure connection.
* `-j, --jobs N_JOBS`

  Number of jobs for parallel build. If not specified, the default value obtained from the `nproc` command is used.
* `-h, --help`

  Help text.

For more information, see the section
[Building the examples](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=building_sample_programs)
in the KasperskyOS Community Edition Online Help.

#### QEMU

##### Scenarios 1 and 3

Running `build.sh` builds the host and runs the Linux server.

Running `cross-build.sh` creates the `kos-qemu-image` solution image that includes the KasperskyOS client.
This image is located in the `<root_directory>/build/example_kos/build/kos/client/einit` directory.
The `cross-build.sh` script both builds the solution on QEMU and runs it.

##### Scenarios 2 and 4

Running `cross-build.sh` creates the `kos-qemu-image` solution image that includes the KasperskyOS server.
This image is located in the `<root_directory>/build/example_kos/build/kos/server/einit` directory.
The `cross-build.sh` script both builds the solution on QEMU and runs it.

Running `build.sh` builds the host and runs the Linux client.

For more information, see the section
[Running examples on QEMU](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=running_sample_programs_qemu)
in the KasperskyOS Community Edition Online Help.

#### Hardware

Before reading this section, it is recommended that you read the following sections in the KasperskyOS Community Edition Online Help:
1. Preparing the required hardware platform and bootable SD card:
    * [Raspberry Pi 4 B](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=preparing_sd_card_rpi)
    * [Radxa ROCK 3A](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=preparing_sd_card_radxa)
1. Running the example:
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=running_sample_programs_rpi)

**Note:** Scenarios 3 and 4 demonstrate secure connections between server and client.
gRPC uses ssl-encryption that requires NTP to get current time.
For private networks or when external NTP services are unavailable, external NTP services can be replaced by a local NTP service running on the host.

Before creating a KasperskyOS-based solution, update the following configuration file:
   `<root_directory>/examples/kos/helloworld/resources/hdd/etc/ntp.conf`.
The `ntp.conf` file should contain the following line:
   `server host_ip_address`
Where `host_ip_address' is the ip address of the host running the NTP server.

##### Scenarios 1 and 3

Running `build.sh` builds the host and runs the Linux server.

Running `cross-build.sh` with `-p image` option creates the `kos-image` KasperskyOS-based solution image that includes the KasperskyOS client.
This image is located in the `<root_directory>/build/example_kos/build/kos/client/einit` directory.

1. Check if the correct server IP address is specified in the "targetEndpoint" variable in client/src/main.cc. By default it is set to 10.0.2.2, which is the default IP address for QEMU.
1. Prepare the required hardware platform and bootable SD card by following the instructions in the KasperskyOS Community Edition Online Help:
    * [Raspberry Pi 4 B](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=preparing_sd_card_rpi)
    * [Radxa ROCK 3A](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=preparing_sd_card_radxa)
1. Copy the `kos-image` to the bootable SD card.
1. Connect the bootable SD card to the hardware.
1. Supply power to the hardware and wait for the example to run.

Running `cross-build.sh` with `-p sdimage` option creates the `hdd.img` file system image for a bootable SD card.
This image is located in the `<root_directory>/build/example_kos/build/kos/client` directory.

1. To copy the `hdd.img` bootable SD card image to the SD card, connect the SD card to the computer and run the following command:

    `$ sudo dd bs=64k if=build/example_kos/build/kos/client/hdd.img of=/dev/sd[X] conv=fsync`,

    where `[X]` is the final character in the name of the SD card block device.

1. Connect the bootable SD card to the hardware.
1. Supply power to the hardware and wait for the example to run.

##### Scenarios 2 and 4

Running `cross-build.sh` with `-p image` option creates the `kos-image` KasperskyOS-based solution image that includes the KasperskyOS server.
This image is located in the `<root_directory>/build/example_kos/build/kos/server/einit` directory.

1. Prepare the required hardware platform and bootable SD card by following the instructions in the KasperskyOS Community Edition Online Help:
    * [Raspberry Pi 4 B](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=preparing_sd_card_rpi)
    * [Radxa ROCK 3A](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=preparing_sd_card_radxa)
1. Copy the `kos-image` to the bootable SD card.
1. Connect the bootable SD card to the hardware.
1. Supply power to the hardware and wait for the example to run.

Running `cross-build.sh` with `-p sdimage` option creates the `hdd.img` file system image for a bootable SD card.
This image is located in the `<root_directory>/build/example_kos/build/kos/server` directory.

1. To copy the `hdd.img` bootable SD card image to the SD card, connect the SD card to the computer and run the following command:

    `$ sudo dd bs=64k if=build/example_kos/build/kos/server/hdd.img of=/dev/sd[X] conv=fsync`,

    where `[X]` is the final character in the name of the SD card block device.

1. Connect the bootable SD card to the hardware.
1. Supply power to the hardware and wait for the example to run.

Running `build.sh` builds the host and runs the Linux client.

#### CMake input files

* [./client/CMakeLists.txt](client/CMakeLists.txt)

  CMake commands for building the `GreeterClient` program.
* [./einit/CMakeLists.txt](einit/CMakeLists.txt)

  CMake commands for building the `Einit` program and the solution image.
* [./libraries/CMakeLists.txt](libraries/CMakeLists.txt)
  [./libraries/hello_world_proto/CMakeLists.txt](libraries/hello_world_proto/CMakeLists.txt)
  [./libraries/utility_lib/CMakeLists.txt](libraries/utility_lib/CMakeLists.txt)

  CMake commands for building the shared libraries used by the `GreeterClient` and the `GreeterServer` programs.
* [./server/CMakeLists.txt](server/CMakeLists.txt)

  CMake commands for building the `GreeterServer` program.
* [./CMakeLists.txt](CMakeLists.txt)

  CMake commands for building the solution.

[⬆ Back to Top](#table-of-contents)

## Usage

### Scenario 1

1. To build and run the Linux server, execute the following command:
    ```
    $ ./build.sh server
    ```
1. Wait for the standard output to display that the server has started listening:
    ```
    ...
    [GreeterServer] starting...
    [GreeterServer] using secure connection: false
    [GreeterServer] listening on 0.0.0.0:50051
    ```
1. To build and run the KasperskyOS client, execute the following command from a separate terminal:
    ```
    $ ./cross-build.sh client
    ```
1. The standard output should display a count of messages sent and their corresponding responses:
    ```
    ...
    [GreeterClient] starting...
    [GreeterClient] waiting for network...
    [GreeterClient] target: 10.0.2.2:50051
    [GreeterClient] using secure connection: false
    [GreeterClient] send request 1
    [GreeterClient] received: Hello KasperskyOS world
    [GreeterClient] send request 2
    [GreeterClient] received: Hello KasperskyOS world
    ...
    ```

### Scenario 2

1. To build and run the KasperskyOS server, execute the following command:
    ```
    $ ./cross-build.sh server
    ```
1. Wait for the standard output to display that the server has started listening:
    ```
    ...
    [GreeterServer] starting...
    [GreeterServer] using secure connection: false
    [GreeterServer] listening on 0.0.0.0:50051
    ```
1. To build and run the Linux client, execute the following command from a separate terminal:
    ```
    $ ./build.sh client
    ```
1. The standard output should display a count of messages sent and their corresponding responses:
    ```
    ...
    [GreeterClient] starting...
    [GreeterClient] target: localhost:50051
    [GreeterClient] using secure connection: false
    [GreeterClient] send request 1
    [GreeterClient] received: KOS-Hello world
    [GreeterClient] send request 2
    [GreeterClient] received: KOS-Hello world
    ...
    ```

 ### Scenario 3

1. To build and run the Linux server, execute the following command:
    ```
    $ ./build.sh server --secure
    ```
1. Wait for the standard output to display that the server has started listening:
    ```
    ...
    [GreeterServer] starting...
    [GreeterServer] using secure connection: true
    [GreeterServer] listening on 0.0.0.0:50051
    ```
1. To build and run the KasperskyOS client, execute the following command from a separate terminal:
    ```
    $ ./cross-build.sh client --secure
    ```
1. The standard output should display a count of messages sent and their corresponding responses:
    ```
    ...
    [GreeterClient] starting...
    [GreeterClient] waiting for network...
    [GreeterClient] target: 10.0.2.2:50051
    [GreeterClient] using secure connection: true
    [GreeterClient] send request 1
    [GreeterClient] received: Hello KasperskyOS world
    [GreeterClient] send request 2
    [GreeterClient] received: Hello KasperskyOS world
    ...
    ```

### Scenario 4

1. To build and run the KasperskyOS server, execute the following command:
    ```
    $ ./cross-build.sh server --secure
    ```
1. Wait for the standard output to display that the server has started listening:
    ```
    ...
    [GreeterServer] starting...
    [GreeterServer] using secure connection: true
    [GreeterServer] listening on 0.0.0.0:50051
    ```
1. To build and run the Linux client, execute the following command from a separate terminal:
    ```
    $ ./build.sh client --secure
    ```
1. The standard output should display a count of messages sent and their corresponding responses:
    ```
    ...
    [GreeterClient] starting...
    [GreeterClient] target: localhost:50051
    [GreeterClient] using secure connection: true
    [GreeterClient] send request 1
    [GreeterClient] received: KOS-Hello world
    [GreeterClient] send request 2
    [GreeterClient] received: KOS-Hello world
    ...
    ```

[⬆ Back to Top](#table-of-contents)

© 2025 AO Kaspersky Lab
