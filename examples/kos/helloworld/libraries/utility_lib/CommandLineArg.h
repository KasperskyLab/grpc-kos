//
// © 2022 AO Kaspersky Lab. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//

#pragma once

#include <string>

namespace CommandLineArg {

bool TryParse(const std::string& argName, const std::string& argText, bool& value);
bool TryParse(const std::string& argName, const std::string& argText, std::string& value);

} // namespace CommandLineArg

