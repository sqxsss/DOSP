%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 10月 2022 18:16
%%%-------------------------------------------------------------------
-module(countAverageHop).
-author("15147").
-record(state, {timeSum = 0, nodeSize, request, count = 0}).

%% API
-export([loop/1, count/2]).

loop(S=#state{}) ->
  receive
    {found, Time} ->
%%      io:format("received ~n"),
      NewSum = S#state.timeSum + Time,
      NewCount = S#state.count + 1,
      if NewCount >= (S#state.nodeSize-1) * S#state.request ->
        Result = NewSum / ((S#state.nodeSize-1) * S#state.request),
        io:format("Average hops for a message: ~f ~n", [Result]);
        true ->
          loop(S#state{timeSum = NewSum, count = NewCount})
      end
  end.

count(NodeSize, Request) ->
  loop(S=#state{nodeSize = NodeSize, request = Request}).