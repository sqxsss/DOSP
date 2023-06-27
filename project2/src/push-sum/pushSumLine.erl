%%%-------------------------------------------------------------------
%%% @author romain
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 10月 2022 3:58 PM
%%%-------------------------------------------------------------------
-module(pushSumLine).
-author("romain").

%% API
-export([start/2]).
-export([getRandNeighbor/1]).
-export([createPushSumNode/1]).
-export([sendPushSum/1]).
-export([pushSumNodeRun/3]).

start(NodeNum, Algo) ->
  if
    Algo == "Push-Sum" ->
      createPushSumNode(NodeNum),
      sendPushSum(NodeNum)
  end.

getRandNeighbor(T) ->
  rand:seed(erlang:phash2([node()]),
    erlang:monotonic_time(),
    erlang:unique_integer()),
  rand:uniform(T).

createPushSumNode(0) ->
  done;
createPushSumNode(NodeNum) when NodeNum > 0 ->
  Pid = spawn(pushSumFull, pushSumNodeRun, [NodeNum, 1, 0]),
  Name = list_to_atom("node" ++ integer_to_list(NodeNum)),
  register(Name, Pid),
  createPushSumNode(NodeNum - 1).

sendPushSum(NodeNum) ->
  StartTime = erlang:monotonic_time() / 1000000,
  register(stopPushSum, spawn(stopPushSum, stopAll, [StartTime])),
  StartRumor = rand:uniform(NodeNum),
  Name = list_to_atom("node" ++ integer_to_list(StartRumor)),
  Pid = whereis(Name),
  Pid ! {0, 1, NodeNum}.

pushSumNodeRun(S, W, Round) ->
  if
    Round == 3 ->
      whereis(stopPushSum) ! over;
    true ->
      done
  end,

  receive
    {S_sent, W_sent, CurNode} ->
      Delta = (S + S_sent) / (W + W_sent) - S / W,
      Potential = getRandNeighbor(2),
      if
        Potential == 2 ->
          NextNode = CurNode + 1;
        true ->
          NextNode = CurNode - 1
      end,
      NeighborName = list_to_atom("node" ++ integer_to_list(NextNode)),
      NeighborPid = whereis(NeighborName),
      NeighborPid ! {S / 2, W / 2, NextNode},
      if
        abs(Delta) < 0.0000000001 ->
          pushSumNodeRun((S + S_sent) / 2, (W + W_sent) / 2, Round + 1);
        true ->
          pushSumNodeRun((S + S_sent) / 2, (W + W_sent) / 2, 0)
      end
  end.
