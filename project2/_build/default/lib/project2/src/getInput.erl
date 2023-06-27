%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 10月 2022 10:09
%%%-------------------------------------------------------------------
-module(getInput).
-author("15147").

%% API
-export([getCommand/0, startSup/0]).

getCommand() ->  %% add new worker; shutdown all
  EnteredString = io:get_line("Enter>"),
  TempString = string:substr(EnteredString, 1, string:length(EnteredString)-1),
  SplitedList = string:tokens(TempString, " "),
  if length(SplitedList) =/= 4 -> io:format("Please enter the correct command!");
    true -> ok
  end,
  {Size, Topology, Algorithm} = {lists:nth(2, SplitedList), lists:nth(3, SplitedList), lists:nth(4, SplitedList)},
  Num = list_to_integer(Size),
  case string:equal(Algorithm, "gossip") of
    true ->
      if Topology == "full" -> {Num, full, gossip};
        Topology == "2D" -> {Num, twoD, gossip};
        Topology == "line" -> {Num, line, gossip};
        Topology == "imp3D" -> {Num, imp3D, gossip};
        true ->
          io:format("Please enter the correct topology! ~n"),
          getCommand()
      end;
    false ->
      if Topology == "full" -> {Num, "Full", pushsum};
        Topology == "2D" -> {Num, "2D", pushsum};
        Topology == "line" -> {Num, "Line", pushsum};
        Topology == "imp3D" -> {Num, "imp3D", pushsum};
        true ->
          io:format("Please enter the correct topology! ~n"),
          getCommand()
      end
  end.

startSup() ->
  {Size, Topology, Algorithm} = getCommand(),
  case Algorithm of
    gossip ->
      spawn(gossipSup, start, [Size, Topology]);
    pushsum ->
      spawn(pushSumStarter, start, [Size, Topology, "Push-Sum"])
  end.