vlib work
vlog Washing_Machine.v Washing_Machine_tb.v +cover -covercells
vsim -voptargs=+acc work.Washing_Machine_tb -cover


add wave *

add wave /Washing_Machine_tb/DUT/assert__Reset_To_IDLE
add wave /Washing_Machine_tb/DUT/assert__Done_Only_In_IDLE
add wave /Washing_Machine_tb/DUT/assert__IDLE_To_FILL_WATER
add wave /Washing_Machine_tb/DUT/assert__IDLE_To_STEAM_CLEAN
add wave /Washing_Machine_tb/DUT/assert__Double_Wash_Transition
add wave /Washing_Machine_tb/DUT/assert__Timeout_Fill_Water
add wave /Washing_Machine_tb/DUT/assert__Timeout_Wash_Rinse
add wave /Washing_Machine_tb/DUT/assert__Timeout_Spin
add wave /Washing_Machine_tb/DUT/assert__Timeout_Dry_Steam
add wave /Washing_Machine_tb/DUT/assert__Time_Pause_Functionality
add wave /Washing_Machine_tb/DUT/assert__Error_State_Restore
add wave /Washing_Machine_tb/DUT/assert__Error_Counter_Restore
add wave /Washing_Machine_tb/DUT/assert__Steam_Clean_Behavior


coverage save Washing_Machine.ucdb -onexit

run -all
