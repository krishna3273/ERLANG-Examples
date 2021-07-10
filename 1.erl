-module('20171196_1').
-export([main/1,forward/3, start_send/3,start/4 ]).

forward(ID, Prev_Process_pid, Output_file_name) ->
	receive
		{Token, Sender_id} ->
			if 
				Prev_Process_pid == 0 ->
					PID_to_send = whereis(process_0_pid);
				true ->
					PID_to_send = Prev_Process_pid
			end,
			{ok, Output_file} = file:open(Output_file_name, [append]),
			io:fwrite(Output_file, "Process ~p received token ~p from process ~p ~n", [ID, Token, Sender_id]),
			file:close(Output_file),
			PID_to_send ! {Token, ID}
	end.

start_send(Token, Prev_Process_pid, Output_file_name) ->
	if 
		Prev_Process_pid == 0 ->
			PID_to_send = whereis(process_0_pid);
		true ->
			PID_to_send = Prev_Process_pid
	end,
	PID_to_send ! {Token, 0},
	receive
		{Token, Sender_id} ->
			{_, Output_file} = file:open(Output_file_name, [append]),
			io:fwrite(Output_file, "Process ~p received token ~p from process ~p ~n", [0, Token, Sender_id]),
			file:close(Output_file)
	end.


start(Curr_Process, Token, Prev_Process_pid, Output_file_name) ->
	if
		Curr_Process == 0 ->
			Curr_Pid = spawn('20171196_1', start_send, [Token, Prev_Process_pid, Output_file_name]),
			register(process_0_pid, Curr_Pid);
		Curr_Process > 0 ->
			Curr_Pid = spawn('20171196_1', forward, [Curr_Process, Prev_Process_pid, Output_file_name])
	end,
	if 
		Curr_Process > 0  ->
			start(Curr_Process - 1, Token,Curr_Pid, Output_file_name);
		true ->
			ok
	end.


main(Args) ->
	[Input_file_name, Output_file_name] = Args,
	{_, Input_file} = file:open(Input_file_name, [read]),
	{_, Input_data} = file:read(Input_file,204800),
	[P, T] = string:tokens(Input_data, " "),
	{Num_Process, _} = string:to_integer(P),
	{Token, _} = string:to_integer(T),
	% io:fwrite("~w ~w~n", [Num_Process, Token]).
	%Clearing the contents of previous runs
	{_, Output_file} = file:open(Output_file_name, [write]),
	file:close(Output_file),
	Curr_Process = Num_Process - 1,
	start(Curr_Process, Token, 0, Output_file_name).	
	

	


