#!/bin/bash
# head -n -1 test/build/$1.hex > mem.mem
if [[ $OSTYPE == 'darwin'* ]]; then
	echo 'macOS'
	sed '$ d' sw/progs/build/$1.hex > build/mem.mem
else
	head -n -1 sw/progs/build/$1.hex > build/mem.mem
fi
cp hw/mem/*.mem build/
python3 tools/arrange_mem.py
