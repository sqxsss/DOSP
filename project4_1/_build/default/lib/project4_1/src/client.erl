%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 11月 2022 14:54
%%%-------------------------------------------------------------------
-module(client).
-author("15147").
-record(state, {userName = ""}).

%% API
-export([getCommand/0, start/0, loop/1,loopInit/0, processCommand/2]).

%%
%%  1. "connect", including register and reconncet; then "Please enter your user name >", the engine
%%  will handle if name does not exist -> register, if name exist -> reconnect.
%%  2. "quit", client process exit.
%%  3. "subscribe", subscribe to a user; then "Please enter the user you want to subscribe >", the engine
%%  will add the user to the list if the name is new.
%%  4. "send", start sending tweet; then "Please enter the tweet content>", after finishing the tweet,
%%  "Are you sure to send the tweet? Y/N >", enter Y to send the tweet to engine, enter N to cancel the tweet.
%%  5. "retweet", user want to retweet; then "Please enter the number of the tweet >", user does not need to
%%  enter the content of the tweet he wants to comment on, only needs the number; then "add your comment >", the
%%  engine will store the retweet the same as usual tweet, but shows differetly to the client.
%%
getCommand() ->
  EnteredString = io:get_line("Enter>"),
  Command = string:substr(EnteredString, 1, string:length(EnteredString)-1),
  case Command of
%%    "connect" ->
%%      UserName = io:get_line("Please enter user name>"),
%%      {connect, UserName};
    "quit" ->
      {quit};
    "subscribe" ->
      SubName = io:get_line("Please enter the user you want to subscribe>"),
      {subscribe, string:substr(SubName, 1, string:length(SubName)-1)};
    "send" ->
      Content = io:get_line("Please enter the tweet content>"),
      T = io:get_line("Are you sure to send the tweet? Y/N>"),
      case string:substr(T, 1, string:length(T)-1) of
        "Y" ->
          {send, {"", string:substr(Content, 1, string:length(Content)-1)}};
        "N" ->
          {canceled}
      end;
    "retweet" ->
      RetweetNumber = io:get_line("Please enter the id of the tweet>"),
      Comment = io:get_line("Please add your comment>"),
      T = io:get_line("Are you sure to send the tweet? Y/N>"),
      case string:substr(T, 1, string:length(T)-1) of
        "Y" ->
          {retweet, {string:substr(RetweetNumber, 1, string:length(RetweetNumber)-1), string:substr(Comment, 1, string:length(Comment)-1)}};
        "N" ->
          {canceled}
      end;
    "receive" ->
      Subscribe = io:get_line("Show the tweets you have subscribed? Y/N>"),
      Mentions = io:get_line("Show the tweets that mention you? Y/N>"),
      HashTags = io:get_line("Please enter the hashtags ('#' is not needed)>"),
      S = string:substr(Subscribe, 1, string:length(Subscribe)-1),
      M = string:substr(Mentions, 1, string:length(Mentions)-1),
      H = string:substr(HashTags, 1, string:length(HashTags)-1),
      {showTweet, {S, M, H}};
    _ ->
      {wrongCommand}
  end.

processCommand(S = #state{}, T) ->
  case T of
    {Command, P} ->
      case Command of
        subscribe ->
          {subscribe, P, S#state.userName, self()};
        send ->
          {send, P, S#state.userName, self()};
        retweet ->
          {send, P, S#state.userName, self()};
        showTweet ->
          {showTweet, P, S#state.userName, self()}
      end;
    {Command} ->
      case Command of
        quit ->
          {quit, S#state.userName, self()};
        canceled ->
          io:format("Canceled! ~n"),
          loop(S);
        wrongCommand ->
          io:format("Please enter the correct command! ~n"),
          loop(S)
      end
  end.

loop(S = #state{}) ->
  T = getCommand(),
  ProcessedC = processCommand(S, T),
  twitterEngine ! ProcessedC,
  receive
    {quit, ok} ->
      io:format("user disconnected! ~n");
    {subscribe, ok, SubName} ->
      io:format("subscribed ~s! ~n", [SubName]),
      loop(S);
    {subscribe, error} ->
      io:format("user does not exist! ~n"),
      loop(S);
    {send, ok, TID} ->
      io:format("send success, tweet id ~s! ~n", [TID]),
      loop(S);
    {send, error} ->
      io:format("user does not exist! ~n"),
      loop(S);
    {showTweet, TweetList} ->
      Function = fun(Elem) ->
        printReceivedTweets(Elem),
        io:format("---------------------------------------- ~n") end,
      lists:foreach(Function, TweetList),
      loop(S)
  end.

printReceivedTweets(Tweet) ->
  {Poster, TID, Contents, RetweetContents} = Tweet,
  io:format("~p tweeted <~s> : ~s ~n", [Poster, TID, Contents]),
  Function = fun(Elem) ->
    {ID, C} = Elem,
    io:format("  retweet on <~s> : ~s ~n", [ID, C]) end,
  lists:foreach(Function, RetweetContents).

loopInit() ->
  timer:sleep(100),
  UserName = io:get_line("Please enter user name to connect>"),
  N = string:substr(UserName, 1, string:length(UserName)-1),
  twitterEngine ! {connect, N, self()},
  receive
    {connect, ok} ->
      io:format("Welcome ~s! ~n", [N]);
    {connect, existed} ->
      io:format("user has already connected! ~n"),
      loopInit();
    {connect, login} ->
      io:format("Welcome back ~s! ~n", [N])
  end,

  twitterEngine ! {showTweet, {"Y", "Y", ""}, N, self()},
  receive
    {showTweet, TweetList} ->
      Function = fun(Elem) ->
        printReceivedTweets(Elem),
        io:format("---------------------------------------- ~n") end,
      lists:foreach(Function, TweetList)
  end,
  loop(S=#state{userName = N}).

start() ->
  spawn('twitterEngine@DESKTOP-ERVAM65', client, loopInit, []).