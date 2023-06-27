%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 9月 2022 15:04
%%%-------------------------------------------------------------------
-module(getInput).
-author("15147").

%% API
-export([getNumberofWorkers/0, getNumberofZeros/0,getCommand/0]).

getNumberofZeros() ->
  EnteredString = io:get_line("Enter the required number of leading 0's>"),
  TempString = string:substr(EnteredString, 1, string:length(EnteredString)-1),  %% delete the \n from the input string
  Data = case string:to_integer(TempString) of
           {error, _} ->
             io:format("Please enter the correct number! ~n"),
             getNumberofZeros();
           {Integer, _} ->
             Integer
  end.

getNumberofWorkers() ->
  EnteredString = io:get_line("Enter the number of workers>"),
  TempString = string:substr(EnteredString, 1, string:length(EnteredString)-1),  %% delete the \n from the input string
  Data = case string:to_integer(TempString) of
           {error, _} ->
             io:format("Please enter the correct number! ~n"),
             getNumberofWorkers();
           {Integer, _} ->
             Integer
         end.

getCommand() ->  %% add new worker; shutdown all
  EnteredString = io:get_line("Enter>"),
  TempString = string:substr(EnteredString, 1, string:length(EnteredString)-1),
  SplitedList = string:split(TempString, " "),
  if length(SplitedList) =/= 2 -> io:format("Please enter the correct command!");
    true -> ok
  end,
  {First, Second} = {lists:nth(1, SplitedList), lists:nth(2, SplitedList)},
  Command = case string:equal(First, "shutdown") of
              true ->
                shutdown;
              false ->
                {First, Second}
            end.

