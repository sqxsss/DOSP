%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 11月 2022 14:44
%%%-------------------------------------------------------------------
-module(engine).
-author("15147").
-record(data, {users, tweets, current=[]}).
-record(user, {userName="", subList=[], tweetList=[]}).
-record(tweet, {tid, poster="", hashtags=[], mentions=[], contents="", retweetID, time}).

%% API
-export([loop/1, startEngine/0, loopInit/0, getHashTag/1, getMention/1, formatInt/2]).

getHashTag(Content) ->
  L = string:split(Content, " ", all),
  getHashTag(L, []).

getHashTag([], HashTagList) ->
  HashTagList;
getHashTag([F|T], HashTagList) ->
  case string:find(F, "#", leading) of
    nomatch ->
      getHashTag(T, HashTagList);
    _ ->
      getHashTag(T, lists:append(HashTagList,[F]))
  end.

getMention(Content) ->
  L = string:split(Content, " ", all),
  getMention(L, []).

getMention([], MentionList) ->
  MentionList;
getMention([F|T], MentionList) ->
  case string:find(F, "@", leading) of
    nomatch ->
      getMention(T, MentionList);
    _ ->
      getMention(T, lists:append(MentionList,[F]))
  end.

formatInt(Max, I)->
  case Max - length(integer_to_list(I)) of X when X > 0 ->
    string:chars($0, X) ++ integer_to_list(I);
    _ -> I
  end.

getUserSubList(UserName, UserList) ->
  {Name, {user, Name, SubList, TweetList}} = lists:keyfind(UserName, 1, UserList),
  SubList.

queryBySubscribes([], SubList, QueryList) ->
  QueryList;
queryBySubscribes([F|T], SubList, QueryList) ->
  {ID, {tweet, TID, Poster, Hashtags, Mentions, Contents, RetweetID, Time}} = F,
  case lists:member(Poster, SubList) of
    true ->
      queryBySubscribes(T, SubList, lists:append(QueryList,[F]));
    false ->
      queryBySubscribes(T, SubList, QueryList)
  end.

queryByMentions([], UserName, QueryList) ->
  QueryList;
queryByMentions([F|T], UserName, QueryList) -> %% find the tweets that mention UserName
  {ID, {tweet, TID, Poster, Hashtags, Mentions, Contents, RetweetID, Time}} = F,
  case lists:member(string:concat("@", UserName), Mentions) of
    true ->
      queryByMentions(T, UserName, lists:append(QueryList,[F]));
    false ->
      queryByMentions(T, UserName, QueryList)
  end.

queryByHashTags([], HashTag, QueryList) ->
  QueryList;
queryByHashTags([F|T], HashTag, QueryList) ->
  {ID, {tweet, TID, Poster, Hashtags, Mentions, Contents, RetweetID, Time}} = F,
  case lists:member(string:concat("#", HashTag), Hashtags) of
    true ->
      queryByHashTags(T, HashTag, lists:append(QueryList,[F]));
    false ->
      queryByHashTags(T, HashTag, QueryList)
  end.

getRetweetContents(TweetID, ContentList, TweetList) ->
  {TID, {tweet, TID, Poster, Hashtags, Mentions, Contents, RetweetID, Time}} = lists:keyfind(TweetID, 1, TweetList),
  NewList = lists:append(ContentList, [{TID, Contents}]),
  case length(RetweetID) of
    0 ->
      NewList;
    _ ->
      getRetweetContents(RetweetID, NewList, TweetList)
  end.

formatReceiveTweets([], ReceiveList, TweetList) ->
  ReceiveList;
formatReceiveTweets([F|T], ReceiveList, TweetList) ->
  {TID, {tweet, TID, Poster, Hashtags, Mentions, Contents, RetweetID, Time}} = F,
  R = case length(RetweetID) of
        0 ->
          {Poster, TID, Contents, []};
        _ ->
          RetweetContentList = getRetweetContents(RetweetID, [], TweetList),
          {Poster, TID, Contents, RetweetContentList}
      end,
  formatReceiveTweets(T, lists:append(ReceiveList, [R]), TweetList).

mergeLists(First, Second) ->
  if length(First) == 0 ->
      Second;
    length(Second) == 0 ->
      First;
    true ->
      mergeTupleLists(First, Second)
  end.
mergeTupleLists([], TupleList) ->
  TupleList;
mergeTupleLists([F|T], TupleList) ->
  case lists:member(F, TupleList) of
    true ->
      mergeTupleLists(T, TupleList);
    false ->
      mergeTupleLists(T, lists:append(TupleList, [F]))
  end.

loop(D=#data{}) ->
  receive
    {connect, Name, CID} ->
      case lists:member(Name, D#data.current) of
        true ->
          CID ! {connect, existed},
          loop(D);
        false ->
          case orddict:find(Name, D#data.users) of
            {ok, U} -> %% user already existed, connect
              io:format("user ~s connect back ~n", [Name]),
              CID ! {connect, login},
              NewCurrent = lists:append(D#data.current,[Name]),
              loop(D#data{current = NewCurrent});
            error ->   %% user new, register and add into the data
              io:format("user ~s registed ~n", [Name]),
              NewUsers = orddict:store(Name, #user{userName = Name, subList = [], tweetList = []}, D#data.users),
              CID ! {connect, ok},
              NewCurrent = lists:append(D#data.current,[Name]),
              loop(D#data{users = NewUsers, current = NewCurrent})
          end
      end;
    {quit, UserName, CID} ->
      NewCurrent = lists:delete(UserName, D#data.current),
      io:format("user ~s disconnected ~n", [UserName]),
      CID ! {quit, ok},
      loop(D#data{current = NewCurrent});
    {subscribe, SubName, UserName, CID} ->
      case orddict:find(UserName, D#data.users) of
        {ok, U} -> %% add new subscribe user name into the list in the users data
          {user, N, SubL, TweL} = U,
          NewSubList = lists:append(SubL,[SubName]),
          NewUsers = orddict:store(UserName, #user{userName = UserName, subList = NewSubList, tweetList = TweL}, D#data.users),
          CID ! {subscribe, ok, SubName},
          loop(D#data{users = NewUsers});
        error ->   %% user does not exist
          CID ! {subscribe, error},
          loop(D)
      end;
    {send, P, UserName, CID} ->
      %% if RetweId = "", normal send; if not retweet
      {RetweID, Content} = P,
      HashTagList = getHashTag(Content),
      MentionList = getMention(Content),
      case orddict:find(UserName, D#data.users) of
        {ok, U} ->
          {user, N, SubL, TweL} = U,

          %% create new tweet id: username + number in the format of "admin0001"
          Numb = length(TweL) + 1,
          FormatNumb = formatInt(4, Numb),
          TID = string:concat(UserName, FormatNumb),

          %% add new tweet into D#data
%%          calendar:now_to_datetime(os:timestamp()).
          Timestamp = os:timestamp(),
          NewTweets = orddict:store(TID,
            #tweet{tid = TID, poster=UserName, hashtags=HashTagList, mentions=MentionList, contents=Content, retweetID = RetweID, time=Timestamp},
            D#data.tweets),
          WriteFormat =string:concat(string:concat(string:concat(UserName, " "), TID), Content),
          file:write_file("tweets.txt", io_lib:fwrite("~s\n", [WriteFormat]), [append]),

          %% add new tweet id into user's tweet list
          NewTweetList = lists:append(TweL,[TID]),
          NewUsers = orddict:store(UserName, #user{userName = UserName, subList = SubL, tweetList = NewTweetList}, D#data.users),
          CID ! {send, ok, TID},
          loop(D#data{users = NewUsers, tweets = NewTweets});
        error ->   %% user does not exist
          CID ! {send, error},
          loop(D)
      end;
    {showTweet, Condition,  UserName, CID} ->
      {S, M, H} = Condition,
      QueryList1 = case S of
                    "N" ->
                      [];
                    "Y" ->
                      SubList = getUserSubList(UserName, D#data.users),
                      queryBySubscribes(D#data.tweets, SubList, [])
                  end,
      QueryList2 = case M of
                     "N" ->
                       [];
                     "Y" ->
                       queryByMentions(D#data.tweets, UserName, [])
                   end,
      QueryList3 = case length(H) of
                     0 ->
                       [];
                     _ ->
                       queryByHashTags(D#data.tweets, H, [])
                   end,
      Mer1 = mergeLists(QueryList1, QueryList2),
      QueryL = mergeLists(QueryList3, Mer1),
      %% add one more step: sort by timestamp
      ReceiveList = formatReceiveTweets(QueryL, [], D#data.tweets),
      CID ! {showTweet, ReceiveList},
      loop(D)
  end.

loopInit() ->
  loop(D=#data{users = orddict:new(), tweets = orddict:new()}).

startEngine() ->
  register(twitterEngine, spawn(engine, loopInit,[])).