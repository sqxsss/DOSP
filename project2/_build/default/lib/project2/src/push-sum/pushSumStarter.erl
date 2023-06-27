%%%-------------------------------------------------------------------
%%% @author romain
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 10月 2022 3:04 AM
%%%-------------------------------------------------------------------
-module(pushSumStarter).
-author("romain").

%% API
-export([start/3]).

start(NodeNum, TopoType, Algo) ->
  if
    TopoType == "Full" ->
      pushSumFull:start(NodeNum, Algo);
    TopoType == "Line" ->
      pushSumLine:start(NodeNum, Algo);
    true ->
      done
  end.
