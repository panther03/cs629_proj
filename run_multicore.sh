#!/bin/bash
./test.sh $1
cd build
# ./DualCoreTest
# ./DualCoreRouterTest
./DualCoreNoCTest
cd ..