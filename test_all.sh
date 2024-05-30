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

echo "Testing matmul32"
./test.sh matmul32
cd build
timeout 120 ./SingleCoreTest
cd ..

echo "Testing matmul2"
./test.sh matmul232
cd build
timeout 120 ./SingleCoreTest
cd ..


echo "Testing dotproduct (single core)"
./test.sh dotproduct32
cd build
timeout 120 ./SingleCoreTest
cd ..

echo "Testing dotproduct_5c32"
./test.sh dotproduct_5c32
cd build
timeout 120 ./FiveCoreTest
cd ..

echo "Testing dotproduct_9c32"
./test.sh dotproduct_9c32
cd build
timeout 120 ./NineCoreNoCTest
cd ..

echo "Testing dividesort32 (single core)"
./test.sh dividesort32
cd build
timeout 120 ./SingleCoreTest
cd ..

echo "Testing dividesort_9c32"
./test.sh dividesort_9c32
cd build
timeout 120 ./NineCoreNoCTest
cd ..