%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 10月 2022 14:27
%%%-------------------------------------------------------------------
-module(starter).
-author("15147").

%% API
-export([getInput/0, createNodes/3, start/0]).

getInput() ->
  EnteredString = io:get_line("Enter>"),
  TempString = string:substr(EnteredString, 1, string:length(EnteredString)-1),
  SplitedList = string:tokens(TempString, " "),
  if length(SplitedList) =/= 3 -> io:format("Please enter the correct command!");
    true -> ok
  end,
  {lists:nth(2, SplitedList), lists:nth(3, SplitedList)}.

createNodes(Size, K, Req) ->
  M = processing:getClosestPowerNum(Size, 0),
  case K =< Size of
    true ->
      Rname = string:concat("n", integer_to_list(K)),
      if K =:= 1 ->
        register(list_to_atom(Rname), spawn(node, create, [Rname, M, Size, Req]));
        true ->
          T = string:concat("n", integer_to_list(K-1)),
          register(list_to_atom(Rname), spawn(node, join, [T, Rname, M, Size, Req]))
      end,
      createNodes(Size, K + 1, Req);
    false ->
      ok
  end.

start() ->
  {NodeNum, NodeReq} = getInput(),
  M = processing:getClosestPowerNum(list_to_integer(NodeNum), 0),
  register(sumMachine, spawn(countAverageHop, count, [list_to_integer(NodeNum),list_to_integer(NodeReq)])),
  createNodes(list_to_integer(NodeNum), 1, list_to_integer(NodeReq)).

