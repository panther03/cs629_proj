TARGETS := SingleCoreTest DualCoreTest FiveCoreTest RouterTestBench DualCoreRouterTest NineCoreNoCTest
TARGETSV := TopCore

.DEFAULT_GOAL := all
.PHONY: clean $(TARGETS) $(TARGETSV)

$(TARGETS): 
	make -f generic.mk BINARY_NAME=$@

$(TARGETSV): 
	make -f generic.mk BINARY_NAME=$@ verilog

clean:
	rm -rf build/
#	find . -name "*.so" -type f -delete
#	find . -name "*.sched" -type f -delete
#	find . -name "*.bo" -type f -delete
#	find . -name "*.ba" -type f -delete

all: clean $(TARGETS)
