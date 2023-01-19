# © 2022 AO Kaspersky Lab. All Rights Reserved
# SPDX-License-Identifier: Apache-2.0

mkdir -p cmake/build
pushd cmake/build
cmake -DCMAKE_PREFIX_PATH=$HOME/.local ../..
cmake --build .

./GreeterServer $1
