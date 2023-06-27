%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 10月 2022 17:29
%%%-------------------------------------------------------------------
-module('2DGrid').
-author("15147").
-record(grid, {points, size}).

%% API
-export([form/1,form2DGrid/7, init2DGrid/1]).

form(G=#grid{}) ->
  form2DGrid(G#grid{points = orddict:store({0,0}, 1, G#grid.points)}, right, 1, 1, {0,0}, 1, G#grid.size).

form2DGrid(G=#grid{},Direction, 0, Round, {X,Y}, Number, Size) ->
  case Direction of
    right ->
      form2DGrid(G,down, Round, Round, {X,Y}, Number, Size);
    down ->
      form2DGrid(G,left, Round+1, Round+1, {X,Y}, Number, Size);
    left ->
      form2DGrid(G,up, Round, Round, {X,Y}, Number, Size);
    up ->
      form2DGrid(G,right, Round+1, Round+1, {X,Y}, Number, Size)
  end;
form2DGrid(G=#grid{},Direction, Count, Round, {X,Y}, Number, Size) ->
  case Number < Size of
    false ->
      G#grid.points;
    true ->
      case Direction of
        right ->
          NewPoint = {X+1,Y},
          form2DGrid(G#grid{points = orddict:store(NewPoint, Number+1, G#grid.points)},Direction, Count-1, Round, NewPoint, Number+1, Size);
        down ->
          NewPoint = {X,Y-1},
          form2DGrid(G#grid{points = orddict:store(NewPoint, Number+1, G#grid.points)},Direction, Count-1, Round, NewPoint, Number+1, Size);
        left ->
          NewPoint = {X-1,Y},
          form2DGrid(G#grid{points = orddict:store(NewPoint, Number+1, G#grid.points)},Direction, Count-1, Round, NewPoint, Number+1, Size);
        up ->
          NewPoint = {X,Y+1},
          form2DGrid(G#grid{points = orddict:store(NewPoint, Number+1, G#grid.points)},Direction, Count-1, Round, NewPoint, Number+1, Size)
      end
  end.

init2DGrid(Size) ->
  form(G =#grid{points = orddict:new(), size = Size}).