#!/usr/bin/env sh

mkdir build || exit
cd build  || exit
cmake -G Ninja .. \
    -DGEN_DOCS=OFF \
    -DBUILD_TESTS=OFF \
    -DENABLE_COVERAGE=OFF \
    -DENABLE_IWYU=OFF \
    -DENABLE_CPPLINT=OFF \
    -DENABLE_CLANGTIDY=OFF \
    -DENABLE_DAFUR_LINK=OFF \
    -DENABLE_TAGS=OFF \
    -DCMAKE_SYSTEM_PROCESSOR=__i386__ \
    -DCMAKE_C_FLAGS=-m32 \
    -DCMAKE_CXX_FLAGS=-m32 \ke
    -DCMAKE_EXE_LINKER_FLAGS=-m32 \
    -DCMAKE_MODULE_LINKER_FLAGS=-m32 \
    -DCMAKE_SHARED_LINKER_FLAGS=-m32 \
    -DBUILD_32=ON

sudo ninja all || exit
sudo ninja rebuild_cache || exit
sudo ninja package || exit
