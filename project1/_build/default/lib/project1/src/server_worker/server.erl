%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 9月 2022 9:41
%%%-------------------------------------------------------------------
-module(server).
-author("15147").
-record(state, {client, dataSet, worker, size = 0, ip="", hasOutput = 0, countTime = 0}).
%% client -> client pid; dataSet -> a list store all the hash string being found;
%% worker -> a list store all the workers; size -> the required number of 0's;
%% ip -> server ip address; hasOutput -> 0 - not output the first result string, 1 - has;
%% countTime -> 0 - not output the cpu time and real time, 1 - has;

%% the reason to use the countTime is that the server needs to have one worker working all the time,
%% but what we need is the time while several processes are working together.

%% API
-export([createWorker/2, loopMessage/1, start/0,loopWorkers/2]).

createWorker(Name, S = #state{}) ->
  %% this function is used to create a worker process;
  %% and send start message to let the worker start mining
  WID = spawn_link(worker, initWorker, [self(), Name, S#state.size]),
  WID ! start,
  WID.

%% this function is used to use recursion to create a large number of workers at the same time;
loopWorkers(S, 0) ->
  S#state.worker;
loopWorkers(S=#state{}, Num) ->
  %% 'serverWork' is the worker mine for the server while there is no other server, it will keep mining all the time
  WorkerName = case Num =:= 1 of
                 true ->
                   "serverWork";
                 false ->
                   string:concat("serverWork", integer_to_list(Num))
               end,
  WID = createWorker(WorkerName, S),
  NewWorker = orddict:store(WorkerName, WID, S#state.worker),
  loopWorkers(S#state{worker = NewWorker}, Num-1).

loopMessage(S = #state{}) ->
  %% this function is used to receive messages from both client and all the workers
  receive
    {ip, Address} ->
      %% get server ip address and store it
      loopMessage(S#state{ip = Address});
    {add, Name, ServerIPAddress} ->
      %% add a new worker named 'Name'
      case orddict:find(Name, S#state.worker) of
        %% check if the Name has existed
        {ok, _} ->
          io:format("The worker name has existed~n"),
          loopMessage(S);
        error ->
          case string:equal(ServerIPAddress, S#state.ip) of
            %% check if the ip address of the server is correct
            false ->
              io:format("can't find server ~s~n", [ServerIPAddress]),
              loopMessage(S);
            true ->
              WID = createWorker(Name, S),
              io:format("new worker added ~n"),
              NewWorker = orddict:store(Name, WID, S#state.worker),
              loopMessage(S#state{worker = NewWorker, countTime = 0})
          end
      end;
    {get, K, CID} ->
      %% store the number of required 0's and client pid
      loopMessage(S#state{size = K, client = CID});
    {start, WorkerNum} ->
      %% create 'WorkerNum' number of new workers at the same time;
      %% start counting the cpu time and real time
      statistics(runtime),
      statistics(wall_clock),

      WorkerList = loopWorkers(S, WorkerNum),
      loopMessage(S#state{worker = WorkerList});
    {coin, InputString, HashString, WID} ->
      %% receive messages containing coin mined from workers, and update the dataset
      NewDataSet = case orddict:find(InputString, S#state.dataSet) of
                     error ->
                       WriteFormat = string:concat(string:concat(InputString, " "), HashString),
                       case S#state.hasOutput =:= 0 of
                         true -> io:format("~s ~n", [WriteFormat]);
                         false -> ok
                       end,
                       file:write_file("data.txt", io_lib:fwrite("~s\n", [WriteFormat]), [append]),
                       orddict:store(InputString, WriteFormat, S#state.dataSet);
                     {ok, _} ->
                       S#state.dataSet
                   end,

%%      io:format("~b strings, ~b workers ~n", [orddict:size(S#state.dataSet), orddict:size(S#state.worker)]),
      case orddict:size(S#state.worker) > 1 of
        %% if all workers except serverWork have finished job,
        %% print out the cpu time, real time as well as the ratio;
        %% there is still one worker 'serverWork' keep working,
        %% so that even though there is no other workers the server can keep mining
        true ->
          WID ! {coin, ok},
          loopMessage(S#state{dataSet = NewDataSet, hasOutput = 1});
        false ->
          case S#state.countTime =:= 0 of
            false -> ok;
            true ->
              io:format("FINISHED! ~n"),
              {_,Time} = statistics(runtime),
              {_,Time2} = statistics(wall_clock),

              timer:sleep(1000),
              CPU_time = Time / 1000,
              Run_time = Time2 / 1000,
              Time3 = CPU_time / Run_time,
              io:format("CPU time: ~p seconds\n", [CPU_time]),
              io:format("real time: ~p seconds\n", [Run_time]),
              io:format("Ratio is ~p \n", [Time3])
          end,

          WID ! {coin, ok},
          loopMessage(S#state{dataSet = NewDataSet, countTime = 1})
      end;
    {finished, Name} ->
      %% worker finished the mission assigned to him
%%      io:format("work finished ~s~n", [Name]),
      loopMessage(S#state{worker = orddict:erase(Name, S#state.worker)});
    shutdown ->
      %% shutdown the server as well as all the workers
      io:format("server closed~n"),
      exit(shutdown)
  end.

start() ->
  loopMessage(#state{dataSet = orddict:new(), worker = orddict:new()}).