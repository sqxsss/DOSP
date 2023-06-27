%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 10月 2022 8:46
%%%-------------------------------------------------------------------
-module(gossipActor).
-author("15147").
-record(state, {neighborList,size, number, rumor = "", supervisor, count = 0, sID}).

%% API
-export([sendRumor/1, loopActor/1, initActor/3]).

sendRumor(S = #state{}) ->
  N = rand:uniform(S#state.size),
  case N =:= S#state.number of
    true ->
      sendRumor(S);
    false ->
      {K, PID} = lists:nth(N, orddict:to_list(S#state.neighborList)),
      PID ! {rumor, S#state.rumor},
      sendRumor(S)
  end.

loopActor(S = #state{}) ->
  receive
    {rumor, Rumor} ->
      case S#state.count+1 =:= 4 of
        true ->
          S#state.supervisor ! {closed, S#state.number},
%%              io:format("actor ~b finished~n", [S#state.number]),
          exit(S#state.sID, kill);
        false ->
          case S#state.count =:= 0 of
            true ->
              SID = spawn_link(gossipActor, sendRumor, [S]),
              loopActor(S#state{count = 1, sID = SID});
            false ->
              NewCount = S#state.count + 1,
              io:format("actor ~b receive ~b times ~n", [S#state.number, NewCount]),
              loopActor(S#state{count = NewCount})
          end
      end;
    {neighbor, NeighborList} ->
%%      io:format("get neightbor ~b in actor ~b ~n", [orddict:size(orddict:from_list(NeighborList)), S#state.number]),
      loopActor(S#state{neighborList = orddict:from_list(NeighborList), size = orddict:size(orddict:from_list(NeighborList))})
    after 100000 ->
      io:format("delay actor ~b finished~n", [S#state.number]),
      S#state.supervisor ! {closed, S#state.number},
      if S#state.sID =/= undefined -> exit(S#state.sID, kill);
        true ->
          finished
      end
  end.


initActor(Supervisor, Num, Rumor) ->
%%  io:format("create actor ~b ~n", [Num]).
  loopActor(S = #state{supervisor = Supervisor, number = Num, rumor = Rumor, neighborList = orddict:new()}).
