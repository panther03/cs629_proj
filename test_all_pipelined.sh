#!/bin/bash

echo "Testing add"
./test.sh add32
cd build
timeout 5 ./SingleCoreTest
cd ..

echo "Testing and"
./test.sh and32
cd build
timeout 5 ./SingleCoreTest
cd ..

echo "Testing or"
./test.sh or32
cd build
timeout 5 ./SingleCoreTest
cd ..

echo "Testing sub"
./test.sh sub32
cd build
timeout 5 ./SingleCoreTest
cd ..

echo "Testing xor" 
./test.sh xor32
cd build
timeout 5 ./SingleCoreTest
cd ..

echo "Testing hello"
./test.sh hello32
cd build
timeout 5 ./SingleCoreTest
cd ..

echo "Testing mul"
./test.sh mul32
cd build
timeout 5 ./SingleCoreTest
cd ..

echo "Testing reverse"
./test.sh reverse32
cd build
timeout 15 ./SingleCoreTest
cd ..

echo "Testing thelie"
./test.sh thelie32
cd build
timeout 25 ./SingleCoreTest
cd ..

echo "Testing thuemorse"
./test.sh thuemorse32
cd build
timeout 25 ./SingleCoreTest
cd ..

echo "Testing multicore32"
./testMC.sh multicore32
cd build
timeout 120 ./SingleCoreTest
cd ..

echo "Testing matmulmulti32"
./testMC.sh matmulmulti32
cd build
timeout 120 ./SingleCoreTest
cd ..

echo "Testing buffer32"
./testMC.sh buffer32
cd build
timeout 120 ./SingleCoreTest
cd ..



