%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 9月 2022 19:25
%%%-------------------------------------------------------------------
-module(client).
-author("15147").

%% API
-export([loopInput/0, start/0]).

loopInput() ->
  %% deal with the input of add new worker and shutdown
  case getInput:getCommand() of
    {Name, ServerIPAddress} ->
      serverID ! {add, Name, ServerIPAddress},
      loopInput();
    shutdown ->
      serverID ! shutdown
  end.


start() ->
  register(serverID, spawn(server, start, [])),
  %% get server ip address and print it
  {ok, Name} = getInetInfo:getHostName(),
  IpAddress = getInetInfo:getIpString(Name),
  serverID ! {ip, IpAddress},
  io:format("server started, address: ~s~n", [IpAddress]),

  %% enter the required 0's first
  Zeros = getInput:getNumberofZeros(),
  serverID ! {get, Zeros, self()},
  %% enter the number of workers you want to work at the same time
  Workers = getInput:getNumberofWorkers(),
  serverID ! {start, Workers},

  loopInput().
