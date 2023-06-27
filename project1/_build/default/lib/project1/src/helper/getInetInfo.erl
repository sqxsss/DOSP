%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 9月 2022 18:51
%%%-------------------------------------------------------------------
-module(getInetInfo).
-author("15147").

%% API
-export([getHostName/0,getIpAddress/1, tup2list/1, getIpString/1]).

getHostName() ->
  inet:gethostname().

%% get ipv4 address, while is a tuple like {0,0,0,1}
getIpAddress(Hostname) ->
  {ok, {hostent, Name, Aliases, Addrtype, Length, Addr_list}} = inet:gethostbyname(Hostname),
  lists:nth(1, Addr_list).

%% this function is used to convert tuple to list.
tup2list(Tuple) -> tup2list(Tuple, 1, tuple_size(Tuple)).

tup2list(Tuple, Pos, Size) when Pos =< Size ->
  Integ = element(Pos,Tuple),
  [integer_to_list(Integ)| tup2list(Tuple, Pos+1, Size)];
tup2list(_Tuple,_Pos,_Size) -> [].

%% this function is used to get the ipv4 address and covert it into "0.0.0.1" format.
getIpString(Hostname) ->
  Tuple = getIpAddress(Hostname),
  string:join(getInetInfo:tup2list(Tuple), ".").
