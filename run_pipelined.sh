#!/bin/bash
./test.sh $1
cd build
./SingleCoreTest
cd ..
if arch | grep -q x86_64 && uname -s | grep -q  Linux; then
    echo "detected intel 64bit linux"
    cat build/output.log | tools/intelx86_64_linux/spike-dasm > pipelined.log
elif arch | grep -q arm64 && uname -s | grep -q  Darwin; then
    echo "detected arm64 mac"
    cat build/output.log | tools/aarch64_mac/spike-dasm > pipelined.log
elif arch | grep -q i386 && uname -s | grep -q  Darwin; then
    echo "detected intel mac"
    cat build/output.log | tools/intel_mac/spike-dasm > pipelined.log
else
    echo "unsupported architecture, fallback to unfiltered mode"
    cat build/output.log | tools/spike-dasm > pipelined.log
fi
