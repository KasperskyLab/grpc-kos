# If you are in a hurry

For language-specific installation instructions for gRPC runtime, please
refer to these documents:

 * [C++](examples/cpp): Currently to install gRPC for C++, you need to build from source using this instruction.
 * Other languages are not adapted for KasperskyOS. However, you can use it for Windows, Linux, macOS:
    + [C#](src/csharp): NuGet package `Grpc`
    + [Go](https://github.com/grpc/grpc-go): `go get google.golang.org/grpc`
    + [Java](https://github.com/grpc/grpc-java) Use JARs from Maven Central Repository
    + [Node](src/node): `npm install grpc`
    + [Objective-C](src/objective-c) Add `gRPC-ProtoRPC` dependency to podspec
    + [PHP](src/php): `pecl install grpc`
    + [Python](src/python/grpcio): `pip install grpcio`
    + [Ruby](src/ruby): `gem install grpc`


# Pre-requisites

## KasperskyOS

For a default build and use, you need to install the KasperskyOS Community Edition SDK  on your system. The latest version of the SDK can be downloaded from this [link](https://os.kaspersky.com/development/).
The gRPC source code has been checked on the KasperskyOS Community Edition SDK version 1.1.0.

## Compiler `protoc`

By default gRPC uses [protocol buffers](https://github.com/google/protobuf),
you will need the `protoc` compiler to generate stub server and client code.

If you compile gRPC from source: the Makefile will
automatically try to compile the `protoc` in the third_party if you cloned the
repository recursively and it detects that you don't already have it
installed.

# Build and Install from Source for KasperskyOS

For build and installation you need to run the script:

```sh
 $ git clone --recurse-submodules --depth 1 --shallow-submodules https://github.com/KasperskyLab/grpc-kos.git
 $ cd grpc-kos
 $ ./cross-build-kos.sh
```

# Build and Install from Source for Linux, macOS, Windows

Please, refer the corresponding instructions of the grpc version 1.48.
