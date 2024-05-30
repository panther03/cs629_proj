## Building/Running

`make` builds all Bluespec programs in `hw/tb/` by default, and synthesizes `hw/top/TopCore.bsv` to Verilog. `NineCoreNoCTest` is the main module with the 9 cores hooked up with a NoC. Use `make NineCoreNocTest` to build this one specifically.

### Bluesim

Use `./run_multicore.sh dotproduct_9c32` to run `sw/progs/src/dotproduct_9c.c` (after calling `make` in `sw/progs`.) 

### Verilator

Run `make` in `fpga/tb`. By default the dotproduct_9c_hw is run; this can be overriden using `PROGRAM=` on the command line. Running under Verilator, the Verilog verson is essentialy the same as the NineCoreNoCTest, though it is hooked up to a UART, which is how printing can be done in synthesizable hardware.

### FPGA synthesis

`fpga/proj` has a Quartus project and makefile for an FPGA I tried to test on, but unfortunately the 9 cores  design doesn't fit on this FPGA (85k LUT). Nonetheless, you can use `make` in this folder to attempt building.

### Misc notes 
note: to use different defines, pass `DEFINES=` to the makefile as follows

```make DualCoreTest DEFINES="-D CACHE_ENABLE" -B```
(`-B` re-executes the rule everytime)

note that if you want to change the flags for the dependencies, you need to run `make clean` so bluespec compiles them again as well