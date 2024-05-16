#!/bin/bash
# head -n -1 test/build/$1.hex > mem.vmh
if [[ $OSTYPE == 'darwin'* ]]; then
	echo 'macOS'
	sed '$ d' sw/smt//build/$1.hex > build/mem.vmh
else
	head -n -1 sw/smt/build/$1.hex > build/mem.vmh
fi
cp hw/mem/*.vmh build/
python3 tools/arrange_mem.py