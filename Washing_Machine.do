vlib work
vlog Washing_Machine.v Washing_Machine_tb.v +cover -covercells
vsim -voptargs=+acc work.Washing_Machine_tb -cover
add wave -position insertpoint \
    sim:/Washing_Machine_tb/clk_tb \
    sim:/Washing_Machine_tb/rst_n_tb \
    sim:/Washing_Machine_tb/start_tb \
    sim:/Washing_Machine_tb/double_wash_tb \
    sim:/Washing_Machine_tb/dry_wash_tb \
    sim:/Washing_Machine_tb/time_pause_tb \
    sim:/Washing_Machine_tb/done_tb

add wave *

add wave /Washing_Machine_tb/DUT/assert__Reset_To_IDLE
add wave /Washing_Machine_tb/DUT/assert__Done_Only_In_IDLE
add wave /Washing_Machine_tb/DUT/assert__IDLE_To_FILL_WATER
add wave /Washing_Machine_tb/DUT/assert__Double_Wash_Transition
add wave /Washing_Machine_tb/DUT/assert__Timeout_Correctness
add wave /Washing_Machine_tb/DUT/assert__Steam_Clean_Behavior
add wave /Washing_Machine_tb/DUT/assert__Time_Pause_Functionality

coverage save Washing_Machine.ucdb -onexit

run -all