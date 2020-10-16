#!/usr/bin/env sh

builddir=build
options=-DCMAKE_CXX_FLAGS=-m32

rm -rf ${builddir}
mkdir -p "${builddir}"
cd ${builddir} || exit

cmake ${options} ..
make
# sudo make install
