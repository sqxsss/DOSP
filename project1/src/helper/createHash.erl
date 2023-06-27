%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 9月 2022 9:42
%%%-------------------------------------------------------------------
-module(createHash).
-author("15147").

%% API
-export([randomString/2, randomStringSize/0, convertStringToHash/1, create/0]).

%% random create a string which size is from 5 - 8
randomStringSize() ->
  Size = rand:uniform(4) + 4,
  Size.

%% create a random string, character is from 32' ' to 126'~';
%% add the name of one group member as prefix
randomString(0, L) ->
  string:concat("qinxuan",L);
randomString(N, L) ->
  X = rand:uniform(94) + 32,
  randomString(N-1, [X | L]).

%% convert the string to hash string with 16*4 characters
convertStringToHash(InputString) ->
  <<Integer:256>> = crypto:hash(sha256, InputString),
  HashString = io_lib:format("~64.16.0b", [Integer]),
  {InputString,HashString}.

create() ->
  Size = randomStringSize(),
  Str = randomString(Size, []),
  convertStringToHash(Str).