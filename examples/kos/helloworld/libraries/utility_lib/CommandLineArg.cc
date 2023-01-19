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

#include "CommandLineArg.h"

#include <stdexcept>

namespace CommandLineArg {

constexpr auto Separator = '=';

bool TryParse(const std::string& argName, const std::string& argText, bool& value)
{
    if (argText.find(argName) == 0)
    {
        const auto nameSize = argName.size();

        if (argText.size() == nameSize)
        {
            value = true;
            return true;
        }

        if(argText[nameSize] == Separator)
        {
            throw std::runtime_error("The only correct argument syntax is " + argName);
        }
    }

    return false;
}

bool TryParse(const std::string& argName, const std::string& argText, std::string& value)
{
    if (argText.find(argName) == 0)
    {
        const size_t separatorPosition = argName.size();

        if (argText.size() > separatorPosition)
        {
            if((argText[separatorPosition] == Separator))
            {
                const size_t valuePosition = separatorPosition + 1;
                value = argText.substr(valuePosition);
                return true;
            }
        }
        else
        {
            throw std::runtime_error("The only correct argument syntax is " +
                argName + Separator + "argument_value");
        }
    }

    return false;
}

} // namespace CommandLineArg
