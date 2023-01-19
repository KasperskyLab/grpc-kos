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
 * © 2022 AO Kaspersky Lab. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 * 
 */

#include "greeter_client.h"
#include "CommandLineArg.h"
#include "FileUtility.h"

#include <grpcpp/grpcpp.h>

#ifdef __KOS__
#include <kos_net.h>
#endif

#include <chrono>
#include <iostream>
#include <thread>
#include <string>

using grpc::Channel;

namespace
{
    const std::string AppNameTag = "[GreeterClient] ";
}

std::shared_ptr<grpc::ChannelCredentials> GetSecureCredentials()
{
#ifdef __KOS__
    const std::string cacert = FileUtility::ReadFile("/romfs/ca.pem");
#else
    const std::string cacert = FileUtility::ReadFile("./ca.pem");
#endif

    grpc::SslCredentialsOptions ssl_opts;
    ssl_opts.pem_root_certs = cacert;

    return grpc::SslCredentials(ssl_opts);
}

std::shared_ptr<grpc::Channel> CreateChannel(const std::string& target, const bool isSecure)
{
    if(isSecure)
    {
        auto channelCredentials = GetSecureCredentials();

        // Add this arg since the test certificates use a different name
        grpc::ChannelArguments args;
        args.SetString(GRPC_SSL_TARGET_NAME_OVERRIDE_ARG, "foo.test.google.fr");

        return grpc::CreateCustomChannel(target, channelCredentials, args); 
    }
    else
    {
        return grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
    }
}

int main(int argc, char** argv)
{
    std::cout << AppNameTag << "starting..." << std::endl;

    bool useSecureConnection = false;

#ifdef __KOS__
    std::string targetEndpoint = "10.0.2.2:50051"; // use QEMU address
#else
    std::string targetEndpoint = "localhost:50051";
#endif

    try
    {
        // Instantiate the client. It requires a channel, out of which the actual RPCs
        // are created. This channel models a connection to an endpoint specified by
        // "--target=" and "--secure" arguments.

        const std::string arg_secure("--secure");
        const std::string arg_target("--target");

        // check command line args
        for(auto i = 1; i < argc; i++)
        {
            if(CommandLineArg::TryParse(arg_secure, argv[i], useSecureConnection))
            {
                continue;
            }
            
            if(CommandLineArg::TryParse(arg_target, argv[i], targetEndpoint))
            {
                continue;
            }

            throw std::runtime_error("The only acceptable arguments are\n" +
                arg_secure + "\n" +
                arg_target);
        }

#ifdef __KOS__
        std::cout << AppNameTag << "waiting for network..." << std::endl;
        if (!wait_for_network())
        {
            std::cout << AppNameTag << "Error: Wait for network failed!" << std::endl;
            return EXIT_FAILURE;
        }
#endif

        //LogMessage() << "target: " << targetEndpoint;
        std::cout << AppNameTag << "target: " << targetEndpoint << std::endl;
        std::cout << AppNameTag << "using secure connection: " <<
            std::boolalpha << useSecureConnection << std::endl;

        auto channel = CreateChannel(targetEndpoint, useSecureConnection);
    
        GreeterClient greeter(channel);

#ifdef __KOS__
        const std::string user("KasperskyOS world");
#else
        const std::string user("world");
#endif

        for(auto i = 0; i < 20000; i++)
        {
            std::cout << AppNameTag << "send request " << i+1 << std::endl;

            const auto reply = greeter.SayHello(user);

            std::cout << AppNameTag << "received: " << reply << std::endl;

            std::this_thread::sleep_for(std::chrono::seconds(2));
        }

        return EXIT_SUCCESS;
    }
    catch(const std::runtime_error& e)
    {
        std::cout << AppNameTag << "Error: " <<  e.what() << std::endl;
        return EXIT_FAILURE;
    } 
}
