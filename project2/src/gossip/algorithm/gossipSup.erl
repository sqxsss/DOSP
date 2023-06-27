%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 10月 2022 8:45
%%%-------------------------------------------------------------------
-module(gossipSup).
-author("15147").
-record(data, {actorList, rumor = "", topology, size, twoDList}).

%% API
-export([loopActors/2, loop/1, tellNeighbor/2, start/2]).

loopActors(D, 0) ->
  D;
loopActors(D=#data{}, Num) ->
  AID = spawn_link(gossipActor, initActor, [self(), Num, D#data.rumor]),
  NewActorList = orddict:store(Num, AID, D#data.actorList),
  loopActors(D#data{actorList = NewActorList}, Num-1).

tellNeighbor(D, 0) ->
  N = rand:uniform(orddict:size(D#data.actorList)),
%%  io:format("start at actor ~b ~n", [N]),
  {K, PID} = lists:nth(N, orddict:to_list(D#data.actorList)),
  PID ! {rumor, D#data.rumor},
  statistics(wall_clock);
tellNeighbor(D=#data{}, Num) ->
  {ok, PID} = orddict:find(Num, D#data.actorList),
  case D#data.topology of
    full ->
      PID ! {neighbor, D#data.actorList};
    twoD ->
      PID ! {neighbor, actorNeighbor:get2DNeighborList(D#data.actorList, Num, D#data.twoDList)};
    line ->
      PID ! {neighbor, actorNeighbor:getLineNeighborList(D#data.size, D#data.actorList, Num)};
    imp3D ->
      PID ! {neighbor, actorNeighbor:getImp3DNeighborList(D#data.actorList, Num, D#data.twoDList)}
  end,
  tellNeighbor(D, Num-1).

loop(D = #data{}) ->
  receive
    {closed, N} ->
%%      io:format("actors ~b left ~n", [orddict:size(D#data.actorList)-1]),
      case orddict:size(D#data.actorList)-1 =:=0 of
        false ->
          {ok, PID} = orddict:find(N, D#data.actorList),
          exit(PID, kill),
          loop(D#data{actorList = orddict:erase(N, D#data.actorList)});
        true ->
          io:format("FINISHED! ~n"),
          {_,Time2} = statistics(wall_clock),
          Run_time = Time2,
          io:format("real time: ~p ms\n", [Run_time])
      end
  end,
  exit(kill).

start(Size, Topology) ->
%%  io:format("get init size ~b and topology ~s ~n", [Size, Topology]).
  TwoDPointList = '2DGrid':init2DGrid(Size),
  UpdatedD = loopActors(D = #data{actorList = orddict:new(), rumor = "hello", topology = Topology, size = Size, twoDList = TwoDPointList}, Size),
  tellNeighbor(UpdatedD, Size),
  loop(UpdatedD).
