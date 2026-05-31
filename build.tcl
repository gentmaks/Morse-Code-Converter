#-------------------------------------------------------------------------------
# build.tcl - generate the Morse Code Converter Vivado .xpr project
# Run from the repo root:  vivado -mode batch -source build.tcl   (or ./build.sh)
#-------------------------------------------------------------------------------
create_project -force morse_code_converter ./build/morse_code_converter -part xc7a35tcpg236-1

add_files [glob ./src/subs/*.vhd]
add_files ./src/morse_code_converter.vhd
add_files -fileset sim_1 [glob ./src/tb/*.vhd]
add_files -fileset constrs_1 [glob ./constraints/*.xdc]

set_property top morse_code_converter [get_filesets sources_1]
update_compile_order -fileset sources_1
