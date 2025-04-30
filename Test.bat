setlocal enabledelayedexpansion

:: exp_ID
set i_architecture=[-5 -4;-5 -2;-5 -1;-5 8;-5 12;-5 14;-4 -3;-4 -1;-4 9;-4 13;-4 15;-3 -2;-3 -1;-3 4;-3 6;-3 7;-2 -1;-2 1;-2 3;-2 5;-2 11;-1 2;-1 5;-1 10]
set i_full_duplex=true
set i_bandwidth=12.5
::----------------------------------------->byte/us
set i_msg_length=[500 1500]
::----------------------------------------->bytes
:: i_max_link_load = 10 to 90 %
set i_periodic=100
::----------------------------------------->%
set i_jitter_transmission=0
::----------------------------------------->%
set i_jitter_reception=20
::----------------------------------------->%
set i_deadline=75
::----------------------------------------->%
set i_hard_real_time=100
::----------------------------------------->%
set i_max_period=[2000 4000 8000 16000 32000 64000]
::----------------------------------------->us
set i_max_offset=[0 0]
::----------------------------------------->us
set i_jitter_transmission_range=[0 0]
::----------------------------------------->us
set i_max_inter_arr_time=0
::----------------------------------------->us
set i_jitter_reception_range=20
::----------------------------------------->us
set i_deadline_range=[0.5 1 2]
::----------------------------------------->us
set num_queues=3
FOR /L %%A IN (10,5,90) DO (
	set /a i_num_messages=%%A*15
	FOR /L %%B IN (1,1,100) DO (
		matlab -wait -nosplash -nodesktop -r "Network_generator(%%A%%B,%i_architecture%,%i_full_duplex%,!i_num_messages!,%i_bandwidth%,%i_msg_length%,%%A,%i_periodic%,%i_jitter_transmission%,%i_jitter_reception%,%i_deadline%,%i_hard_real_time%,%i_max_period%,%i_max_offset%,%i_jitter_transmission_range%,%i_max_inter_arr_time%,%i_jitter_reception_range%,%i_deadline_range%); quit();"
		matlab -wait -nosplash -nodesktop -r "Mapping_tool(%%A%%B); quit();"
		START /W TSN_HeuristicScheduler.exe %%A%%B STHS_input.txt %num_queues%
		matlab -wait -nosplash -nodesktop -r "AVB_analysis_input_generator(%%A%%B); quit();"
		START /W AVB_analysis.exe %%A%%B
	)
)
endlocal