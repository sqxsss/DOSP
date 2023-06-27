%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 10月 2022 9:38
%%%-------------------------------------------------------------------
-module(actorNeighbor).
-author("15147").
%% API
-export([get2DNeighborList/3,getLineNeighborList/3, getImp3DNeighborList/3, getRandomPoint/3, getImp3DNeighbor/2, pointOfNumber/2, neighborIn2DGrid/3, get2DNeighbor/2]).

get2DNeighborList(ActorList, Number, TwoDPointList) ->
  L = orddict:from_list(ActorList),
  List = get2DNeighbor(Number, TwoDPointList),
  lists:map(
    fun(K) ->
      {ok, PID} = orddict:find(K, L),
      {K, PID}
    end, List).

getLineNeighborList(Size, ActorList, Number) ->
  L = orddict:from_list(ActorList),
  case Number=:= 1 of
    true ->
      {ok, PID} = orddict:find(2, L),
      [{2, PID}];
    false ->
      case Number=:= Size of
        true ->
          {ok, PID} = orddict:find(Size-1, L),
          [{Size-1, PID}];
        false ->
          {ok, LID} = orddict:find(Number-1, L),
          {ok, RID} = orddict:find(Number+1, L),
          [{Number-1, LID},{Number+1, RID}]
      end
  end.

getImp3DNeighborList(ActorList, Number, TwoDPointList) ->
  L = orddict:from_list(ActorList),
  List = getImp3DNeighbor(Number, TwoDPointList),
  lists:map(
    fun(K) ->
      {ok, PID} = orddict:find(K, L),
      {K, PID}
    end, List).

pointOfNumber([F|R], Number) ->
  {K,V} = F,
  case V =:= Number of
    true ->
      K;
    false ->
      pointOfNumber(R, Number)
  end.

get2DNeighbor(Number, PointList) ->
  Point = pointOfNumber(PointList, Number),
  neighborIn2DGrid(PointList, Point, []).

getRandomPoint(PointList, NeighborList, Number) ->
  N = rand:uniform(length(PointList)),
  {K,V} = lists:nth(N, PointList),
  case lists:member(V, NeighborList) of
    true ->
      getRandomPoint(PointList, NeighborList, Number);
    false ->
      if V=/= Number -> V;
        true ->
          getRandomPoint(PointList, NeighborList, Number)
      end
  end.

getImp3DNeighbor(Number, PointList) ->
  Point = pointOfNumber(PointList, Number),
  NeighborList = neighborIn2DGrid(PointList, Point, []),
  RandomValue = getRandomPoint(PointList, NeighborList, Number),
  [RandomValue|NeighborList].

neighborIn2DGrid([], _, Result) ->
  Result;
neighborIn2DGrid([F|R], Point, Result) ->
  {X,Y} = Point,
  {{KX, KY},V} = F,
  if {KX,KY} =:= {X-1, Y} -> neighborIn2DGrid(R, Point, [V|Result]);
    {KX,KY} =:= {X+1, Y} -> neighborIn2DGrid(R, Point, [V|Result]);
    {KX,KY} =:= {X, Y-1} -> neighborIn2DGrid(R, Point, [V|Result]);
    {KX,KY} =:= {X, Y+1} -> neighborIn2DGrid(R, Point, [V|Result]);
    true -> neighborIn2DGrid(R, Point, Result)
  end.