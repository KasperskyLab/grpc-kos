// © 2022 AO Kaspersky Lab. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

#include "FileUtility.h"

#include <fstream>
#include <sstream>

namespace FileUtility {

std::string ReadFile(const std::string& filename)
{
    std::ifstream file;
    file.open(filename);

    if (!file.is_open())
    {
        std::stringstream ss;
        ss << "File not found: " << filename;

        throw std::runtime_error(ss.str());
    }

    std::stringstream ss;

    ss << file.rdbuf();

    file.close();

    return ss.str();
}

} // namespace FileUtility
