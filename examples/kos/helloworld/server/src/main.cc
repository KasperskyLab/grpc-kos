/*
 *
 * Copyright 2015 gRPC authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * © 2024 AO Kaspersky Lab
 * Licensed under the Apache License, Version 2.0 (the "License")
 */

#include "greeter_service_impl.h"
#include "CommandLineArg.h"
#include "FileUtility.h"

#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include <grpcpp/grpcpp.h>

#ifdef __KOS__
#include <kos_net.h>
#endif

#include <filesystem>
#include <iostream>
#include <memory>
#include <string>

namespace
{
    const std::string AppNameTag = "[GreeterServer] ";
}

std::shared_ptr<grpc::ServerCredentials> GetSecureCredentials()
{
#ifdef __KOS__
    const std::filesystem::path certDirectory = "/cert";
#else
    const std::filesystem::path certDirectory = "./";
#endif

    const std::string serverCA = FileUtility::ReadFile(certDirectory / "ca.pem");
    const std::string servercert = FileUtility::ReadFile(certDirectory / "server1.pem");
    const std::string serverkey = FileUtility::ReadFile(certDirectory / "server1.key");

    grpc::SslServerCredentialsOptions::PemKeyCertPair pkcp;
    pkcp.private_key = serverkey;
    pkcp.cert_chain = servercert;

    grpc::SslServerCredentialsOptions ssl_opts;
    ssl_opts.pem_root_certs = serverCA;
    ssl_opts.pem_key_cert_pairs.push_back(pkcp);

    return grpc::SslServerCredentials(ssl_opts);
}

void RunServer(const std::string& serverAddress, std::shared_ptr<grpc::ServerCredentials> credentials)
{
    GreeterServiceImpl service;

    grpc::EnableDefaultHealthCheckService(true);
    grpc::reflection::InitProtoReflectionServerBuilderPlugin();

    grpc::ServerBuilder builder;

    // Listen on the given address without any authentication mechanism.
    builder.AddListeningPort(serverAddress, credentials);
    // Register "service" as the instance through which we'll communicate with
    // clients. In this case it corresponds to an *synchronous* service.
    builder.RegisterService(&service);
    // Finally assemble the server.
    auto server{builder.BuildAndStart()};

    std::cout << AppNameTag << "listening on " << serverAddress << std::endl;

    // Wait for the server to shutdown. Note that some other thread must be
    // responsible for shutting down the server for this call to ever return.
    server->Wait();
}

int main(int argc, char** argv)
{
    std::cout << AppNameTag << "starting..." << std::endl;

    bool useSecureConnection = false;

    try
    {
        const std::string arg_secure("--secure");

        // check command line args
        for(int i = 1; i < argc; i++)
        {
            if(CommandLineArg::TryParse(arg_secure, argv[i], useSecureConnection))
            {
                continue;
            }
            
            throw std::runtime_error("The only acceptable argument is\n" +
                arg_secure);
        }
           
#ifdef __KOS__
        std::cout << AppNameTag << "waiting for network..." << std::endl;
        if (!wait_for_network())
        {
            std::cout << AppNameTag << "Error: Wait for network failed!" << std::endl;
            return EXIT_FAILURE;
        }
#endif

        constexpr auto ServerAddress = "0.0.0.0:50051";
        std::shared_ptr<grpc::ServerCredentials> credentials;
        
        if(useSecureConnection)
        {
            credentials = GetSecureCredentials();
        }
        else
        {
            credentials = grpc::InsecureServerCredentials();
        }

        std::cout << AppNameTag << "using secure connection: " << 
            std::boolalpha << useSecureConnection << std::endl;

        RunServer(ServerAddress, credentials);

        return EXIT_SUCCESS;
    }
    catch(const std::runtime_error& e)
    {
        std::cout << AppNameTag << "Error: " <<  e.what() << std::endl;
        return EXIT_FAILURE;
    }
}
