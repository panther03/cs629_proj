#set_location_assignment PIN_T22 -to clock12MHz
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clock50MHz
set_location_assignment PIN_AF14 -to clock50MHz

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to nReset
set_location_assignment PIN_AA14 -to nReset
#set_location_assignment PIN_AB11 -to biosBypass

# Here the none used signals of the add-on card are defined
# set_location_assignment PIN_V22 -to EspTxd
# set_location_assignment PIN_V21 -to EspRxd
# set_location_assignment PIN_W20 -to EspIO7
# set_location_assignment PIN_W21 -to EspIO6
# set_location_assignment PIN_W22 -to EspIO5
# set_location_assignment PIN_U22 -to EspIO4
# set_location_assignment PIN_P21 -to EspIO10
# set_location_assignment PIN_N21 -to GPIO3
# set_location_assignment PIN_N22 -to GPIO2
# set_location_assignment PIN_M20 -to GPIO1
# set_location_assignment PIN_M21 -to GPIO0
# set_location_assignment PIN_W19 -to SD2
# set_location_assignment PIN_T14 -to SD3
# set_location_assignment PIN_AA18 -to RtcMfp

# Here the sdc-file will be included
set_global_assignment -name SDC_FILE ../scripts/clocks_sdc.tcl

#set_location_assignment PIN_P22 -to TxD
#set_location_assignment PIN_N20 -to RxD

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to TxD
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to RxD
set_location_assignment PIN_AC23 -to TxD
set_location_assignment PIN_AE23 -to RxD


set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[4]
set_location_assignment PIN_V16 -to leds[0]
set_location_assignment PIN_W16 -to leds[1]
set_location_assignment PIN_V17 -to leds[2]
set_location_assignment PIN_V18 -to leds[3]
set_location_assignment PIN_W17 -to leds[4]