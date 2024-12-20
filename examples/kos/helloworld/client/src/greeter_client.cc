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

#include "greeter_client.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using helloworld::Greeter;
using helloworld::HelloReply;
using helloworld::HelloRequest;

GreeterClient::GreeterClient(std::shared_ptr<Channel> channel)
    : m_stub(Greeter::NewStub(channel))
{    
}

// Assembles the client's payload, sends it and presents the response back
// from the server.
std::string GreeterClient::SayHello(const std::string& user)
{
    // Data we are sending to the server.
    HelloRequest request;
    request.set_name(user);

    // Container for the data we expect from the server.
    HelloReply reply;

    // Context for the client. It could be used to convey extra information to
    // the server and/or tweak certain RPC behaviors.
    ClientContext context;

    // The actual RPC.
    const Status status = m_stub->SayHello(&context, request, &reply);

    // Act upon its status.
    if (status.ok()) 
    {
        return reply.message();
    }
    else
    {
        std::string msg = "RPC failed (";
        msg += std::to_string(status.error_code());
        msg += ") ";
        msg += status.error_message();

        return msg;
    }
}
