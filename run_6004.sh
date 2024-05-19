#!/bin/bash
cp risc_v_tests/build/$1.vmh ./mem.vmh
python3 tools/arrange_mem.py
cd ./build/
./TopPipelined
cd ..
if arch | grep -q x86_64 && uname -s | grep -q  Linux; then
    echo "detected intel 64bit linux"
    cat output.log | tools/intelx86_64_linux/spike-dasm > pipelined.log
elif arch | grep -q arm64 && uname -s | grep -q  Darwin; then
    echo "detected arm64 mac"
    cat output.log | tools/aarch64_mac/spike-dasm > pipelined.log
elif arch | grep -q i386 && uname -s | grep -q  Darwin; then
    echo "detected intel mac"
    cat output.log | tools/intel_mac/spike-dasm > pipelined.log
else
    echo "unsupported architecture, fallback to unfiltered mode"
    cat output.log | tools/spike-dasm > pipelined.log
fi