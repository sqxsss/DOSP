%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 9月 2022 11:33
%%%-------------------------------------------------------------------
-module(hashCheck).
-author("15147").

%% API
-export([getPrefix/2,checkPrefix/2, createCheck/1]).

getPrefix(0,S) ->
  S;
getPrefix(K, S) ->
  getPrefix(K-1, string:concat("0", S)).


checkPrefix(HashString, Prefix) ->
  case string:prefix(HashString, Prefix) of
    nomatch ->
      false;
    _ ->
      true
  end.

%% use the prefix to check if the hash string has at least K numbers of 0 as prefix.
createCheck(K)->
  {InputString, HashString} = createHash:create(),
  case checkPrefix(HashString, getPrefix(K, "")) of
    true ->
      {InputString, HashString};
    false ->
      createCheck(K)
  end.