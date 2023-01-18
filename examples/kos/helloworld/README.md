## HelloWorld Example

### Description
gRPC HelloWorld C++ example adapted for KaspeskyOS.
The example shows client-server interaction via secure (using SSL/TLS authentication) or insecure RPC channel.
The example directory contains 3 sub-directories:
- **client** - the source code of client (GreeterClient)
- **server** - the source code of server (GreeterServer)
- **libraries** - shared libraries used by client and server

### Prerequisites
Before you begin, ensure that you have met the following requirements:
- You have Ubuntu or Debian GNU/Linux as host environment
- You have installed KasperskyOS Community Edition SDK
- You have built and installed gRPC for host environment
- You have built and installed gRPC for KasperskyOS

For installation instructions, please see INSTALL.md in the root directory.

### Usage
Both 'client' and 'server' directories contain scripts to build and run the resulting images:
- build.sh for Linux (host OS)
- cross-build.sh for KasperskyOS

The scripts were written with the following assumptions:
- the version of KasperskyOS Community Edition is 1.1.1.13
- gRPC is installed in ~/.local directory
- gRPC for KasperskyOS is installed in ~/.local/kos directory

##**Case 1** Linux server - KaspreskyOS client (insecure communication)

Build and run the server:
```
$ cd server
$ ./build.sh
```
Wait for server to start listening:
```
[GreeterServer] listening on 0.0.0.0:50051
```

From a different terminal, build and run the client:
```
$ cd client
$ ./cross-build.sh
```
At the end you will get the output:
```
[GreeterClient] received: Hello KasperskyOS world
```

##**Case 2** KaspreskyOS server - Linux client (insecure communication)

Build and run the server:
```
$ cd server
$ ./cross-build.sh
```
Wait for server to start listening:
```
[GreeterServer] listening on 0.0.0.0:50051
```

From a different terminal, build and run the client:
```
$ cd client
$ ./build.sh
```
At the end you will get the output:
```
[GreeterClient] received: KOS-Hello world
```

##**Case 3** Linux server - KaspreskyOS client (secure communication)

Build and run the server:
```
$ cd server
$ ./build.sh --secure
```
Wait for server to start listening:
```
[GreeterServer] listening on 0.0.0.0:50051
```

From a different terminal, build and run the client:
```
$ cd client
$ ./cross-build.sh --secure
```
At the end you will get the output:
```
[GreeterClient] received: Hello KasperskyOS world
```

##**Case 4** KaspreskyOS server - Linux client (secure communication)

Build and run the server:
```
$ cd server
$ ./cross-build.sh --secure
```
Wait for server to start listening:
```
[GreeterServer] listening on 0.0.0.0:50051
```

From a different terminal, build and run the client:
```
$ cd client
$ ./build.sh --secure
```
At the end you will get the output:
```
[GreeterClient] received: KOS-Hello world
```

© 2022 AO Kaspersky Lab
