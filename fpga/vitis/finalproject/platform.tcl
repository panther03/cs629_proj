# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /shared/EPFL/CS629/cs629_proj/fpga/vitis/finalproject/platform.tcl
# 
# OR launch xsct and run below command.
# source /shared/EPFL/CS629/cs629_proj/fpga/vitis/finalproject/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {finalproject}\
-hw {/home/julien/EPFL/CS629/cs629_proj/fpga/TopBD_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {/shared/EPFL/CS629/cs629_proj/fpga/vitis}

platform write
platform generate -domains 
platform active {finalproject}
platform config -updatehw {/home/julien/EPFL/CS629/cs629_proj/fpga/TopBD_wrapper.xsa}
platform generate
