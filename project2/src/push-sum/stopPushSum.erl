%%%-------------------------------------------------------------------
%%% @author romain
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 10月 2022 11:32 PM
%%%-------------------------------------------------------------------
-module(stopPushSum).
-author("romain").

%% API
-export([stopAll/1]).

stopAll(StartTime) ->
  receive
    over ->
      EndTime = erlang:monotonic_time() / 1000000,
      TotalTime = EndTime - StartTime,
      io:format("Push-Sum Done.~n"),
      io:format("Total time used: ~f ms ~n", [TotalTime]),
      erlang:halt()
  end,
  stopAll(StartTime).
