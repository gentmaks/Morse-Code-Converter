##====================================================================
## Morse Code Converter Constraints file
## Authors: Gent Maksutaj, Papa Yaw Owusu Nti
##====================================================================

##====================================================================
## External_Clock_Port
##====================================================================
## This is a 100 MHz external clock
set_property PACKAGE_PIN W5 [get_ports clk_ext_port]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_ext_port]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_ext_port]

##====================================================================
## LED_ports
##====================================================================
## LED 0 (RIGHT MOST LED)
set_property PACKAGE_PIN U16 [get_ports led_ext_port]					
	set_property IOSTANDARD LVCMOS33 [get_ports led_ext_port]

##====================================================================
## Buttons
##====================================================================
## CENTER BUTTON
set_property PACKAGE_PIN U18 [get_ports reset_ext_port]						
	set_property IOSTANDARD LVCMOS33 [get_ports reset_ext_port]

##====================================================================
## Pmod Header JA
##====================================================================
##Sch name = JA1
set_property PACKAGE_PIN J1 [get_ports speaker_ext_port]					
	set_property IOSTANDARD LVCMOS33 [get_ports speaker_ext_port]

##====================================================================
## USB-RS232 Interface
##====================================================================
set_property PACKAGE_PIN B18 [get_ports RsRx_ext_port]						
	set_property IOSTANDARD LVCMOS33 [get_ports RsRx_ext_port]

##====================================================================
## Implementation Assist
##====================================================================	
## These additional constraints are recommended by Digilent, DO NOT REMOVE!
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
