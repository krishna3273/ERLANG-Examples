-module('20171196_2').
-import(file, [open/2, close/1, read/2,write/2]).
-import(io, [fwrite/2,fwrite/3]).
-import(maps, [put/3,get/2,keys/1,new/0]).
-export([main/1]).


write_result(Distances,Curr_vertex,Num_vertices,Output_file_name) when Num_vertices>=Curr_vertex ->
    {_, Output_file} = open(Output_file_name,[append]),
    if Num_vertices-1>=Curr_vertex-> 
        fwrite(Output_file,"~p ~p~n",[Curr_vertex,get(Curr_vertex,Distances)]);
    true->
        fwrite(Output_file,"~p ~p",[Curr_vertex,get(Curr_vertex,Distances)])
    end,
    close(Output_file),
    write_result(Distances,Curr_vertex+1,Num_vertices,Output_file_name);

write_result(_,_,_,_)->
    ok.

init_map(Map, S, Val, Len) when Len > 0 ->
    init_map(put(Len, Val, Map), S, Val, Len-1);

init_map(Map,S,_,_) ->
    if S >=0 ->
        put(S,0,Map);
    true ->
        Map
    end.

update_single_edge(Distances,Curr_edge) ->
    X=lists:nth(1,Curr_edge),
    Y=lists:nth(2,Curr_edge),
    W=lists:nth(3,Curr_edge),
    X_dist = get(X,Distances),
    Y_dist = get(Y,Distances),
    if Y_dist > X_dist + W ->
        put(Y,X_dist + W,Distances);
    true ->
        Distances
    end.

update_distances(Edge_list,Distances) when length(Edge_list)>0 ->
    [Curr_edge|RemList]=Edge_list,
    Distances_new = update_single_edge(Distances,Curr_edge),
    update_distances(RemList,Distances_new);

update_distances(_,Distances) ->
    Distances.

update_vertex_dist(Map,First_map,Second_map,Keys) when length(Keys)>0->
    [Key|Rem]=Keys,
    D_first = get(Key,First_map),
    D_second = get(Key,Second_map),
    if D_first > D_second ->
        Dist=D_second;
    true->
        Dist=D_first
    end,
    update_vertex_dist(put(Key,Dist,Map),First_map,Second_map,Rem);

update_vertex_dist(Map,First_map,Second_map,Keys) ->
    Map.

merge_data(First,Rem) when length(Rem)>0->
    Keys = keys(First),
    [Rem_First|Rem_new]=Rem,
    Updated_dist_curr=update_vertex_dist(new(),First,Rem_First,Keys),
    merge_data(Updated_dist_curr,Rem_new);

merge_data(Map,[]) ->
    Map.

single_source_shortest_path(Data,Distances,P,Len) when Len > 0 ->
    Curr_pid = self(),
    Process_pid_list = [spawn_link(fun() -> Curr_pid  ! {self(), update_distances(get(X,Data),Distances)} end) || X <- lists:seq(1, P) ],
    DistancesList = [ receive {Pid, R} -> R end || Pid <- Process_pid_list ],
    [First|Rem] = DistancesList,
    Distances_new = merge_data(First,Rem),
    single_source_shortest_path(Data,Distances_new,P,Len-1);

single_source_shortest_path(_,Distances,_,_) ->
    Distances.

split_data(Edge_list, P, Num_size, Curr_proc, Data_divided) when P > 1 ->
    % io:fwrite("~p~n",[Curr_proc]),
    {First,Rem} = lists:split(Num_size,Edge_list),
    
    split_data(Rem,P-1,Num_size,Curr_proc+1,
        put(Curr_proc,First,Data_divided));

split_data(Edge_list,P, Num_size,Curr_proc,Data_divided) when P==1->
    put(Curr_proc,Edge_list,Data_divided).


%Base Case(This function fills the values of input variables required)
fill(Inp,M,N,P,S,Edge_list) when length(Inp)==0->
    [M,N,P,S,Edge_list];
%Other Cases
fill(Inp,M,N,P,S,Edge_list) when length(Inp)>0->
    Len= length(Inp),
    [First|Rem]=Inp,
    List = string:lexemes(First, " "),
    % fwrite("List is of length is ~p and the list is ~p,Len=~p~n",[length(List),List,Len]),
    case length(List) of
        1->
            Temp = list_to_integer(lists:nth(1,List)),
            if Len == 1 -> 
                fill(Rem,M,N,P,Temp,Edge_list);
            true ->
                fill(Rem,M,N,Temp,S,Edge_list)
            end;
        2 ->
            N_actual = list_to_integer(lists:nth(1,List)),
            M_actual = list_to_integer(lists:nth(2,List)),
            fill(Rem,M_actual,N_actual,P,S,Edge_list);
        3 ->
            X = list_to_integer(lists:nth(1,List)),
            Y= list_to_integer(lists:nth(2,List)),
            W = list_to_integer(lists:nth(3,List)),
            Edge_list_new=Edge_list++[[X,Y,W],[Y,X,W]],
            fill(Rem,M,N,P,S, Edge_list_new)
    end.
main(Args) ->
    [Input_file_name, Output_file_name] = Args,
    {_, Output_file} = open(Output_file_name, [write]),
	close(Output_file),
    {_, File} = open(Input_file_name,[read]),
    {_, Input_data} = read(File,5000*100*8),
    % io:fwrite("~p~n",[string:lexemes(Input_data, [[$\r,$\n]])]),
    [M,N,P,S,Edge_list] = fill(string:lexemes(Input_data, [[$\r,$\n]]),0,0,0,0,[]),
    % io:fwrite("N=~p~n",[N]),
    Data_divided = split_data(Edge_list,P,floor(2*M/P),1,new()),
    

    Init_dist = 100000000,
    Distances = init_map(new(),S,Init_dist,N),
    Distances_final = single_source_shortest_path(Data_divided,Distances,P,N),
    
    write_result(Distances_final,1,N,Output_file_name).
