# © 2022 AO Kaspersky Lab. All Rights Reserved

mkdir -p cmake/build
pushd cmake/build
cmake -DCMAKE_PREFIX_PATH=$HOME/.local ../..
cmake --build .

./GreeterClient $1
