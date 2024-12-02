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

#pragma once

#include "helloworld.grpc.pb.h"

#include <grpcpp/grpcpp.h>

#include <memory>
#include <string>

class GreeterClient
{
public:
    explicit GreeterClient(std::shared_ptr<grpc::Channel> channel);

    // Assembles the client's payload, sends it and presents the response back
    // from the server.
    std::string SayHello(const std::string& user);

private:
    std::unique_ptr<helloworld::Greeter::Stub> m_stub;
};
