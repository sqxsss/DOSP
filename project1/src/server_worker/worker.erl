%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 9月 2022 17:25
%%%-------------------------------------------------------------------
-module(worker).
-author("15147").
-record(info, {server, name = "", size = 0}).
%% server is the pid of server; name is the worker name;
%% size is the number of leading 0's; times is the number of assignments.

%% API
-export([mineWorker/2, loop/2, initWorker/3]).

mineWorker(Server, K) ->
  %% this function is used to mine and send the coin to server.
  {InputString, HashString} = hashCheck:createCheck(K),
  Server ! {coin, InputString, HashString, self()}.

%% this function is to recursion N = work unit times (mine N coins) and then finish the job,
%% since 'serverWork' will not finish, the number of N will not change
loop(I = #info{}, 0) ->
  I#info.server ! {finished, I#info.name};
loop(I = #info{}, Num) ->
  receive
    start ->
      %% start message is sent when the worker is created and let it to start working,
      %% and it only works while creating a new process.
%%      io:format("worker ~s starts mining with size ~b ~n", [I#info.name, I#info.size]),
      mineWorker(I#info.server, I#info.size),
      case string:equal(I#info.name, "serverWork") of
        true ->
          loop(I, Num);
        false ->
          loop(I, Num-1)
      end;
    {coin, ok} ->
      %% this message works the same function as above, but it works during the mission
      mineWorker(I#info.server, I#info.size),
      case string:equal(I#info.name, "serverWork") of
        true ->
          loop(I, Num);
        false ->
          loop(I, Num-1)
      end
  end.


initWorker(Server, Name, K) ->
  %% 10 is the default work unit, it can be changed to any number
  loop(I = #info{server = Server, name = Name, size = K}, 10).