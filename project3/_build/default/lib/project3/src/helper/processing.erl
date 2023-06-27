%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 10月 2022 14:13
%%%-------------------------------------------------------------------
-module(processing).
-author("15147").
-record(proc, {nodeNum}).

%% API
-export([getClosestPowerNum/2, modulo/2]).

getClosestPowerNum(Num, K) ->
  case math:pow(2,K)>= Num of
    true ->
      case math:pow(2, K-1) < Num of
        true ->
          K;
        false ->
          getClosestPowerNum(Num, K-1)
      end;
    false ->
      getClosestPowerNum(Num, K+1)
  end.

modulo(Id, Num) ->
  if Id =< Num ->
    Id;
    true ->
      Id - Num
  end.