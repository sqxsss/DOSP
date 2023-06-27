%%%-------------------------------------------------------------------
%%% @author 15147
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 10月 2022 18:52
%%%-------------------------------------------------------------------
-module(node).
-author("15147").
-record(data, {finger_table, finger_table_size,request, successor, predecessor, nodeSize, name, isFinished=0}).

%% API
-export([closest_preceding_node/4, find_successor/4, sending_requests/3, loop/1, create/4]).
-export([fix_fingers/2, join/5, check_predecessor/1, stabilize/1, notify/2]).

loop(D = #data{}) ->
  receive
    {findSuccessor, ID, Time, StartNode} ->
%%      io:format("keep finding ~n"),
      find_successor(D, ID, Time + 1, StartNode);
    {getPredecessor, Node} ->
      list_to_atom(Node) ! {predecessor, D#data.predecessor};
    {checkPre, Node} ->
      list_to_atom(Node) ! {checkSuccess, D#data.name};
    {notifyNode, Node} ->
      notify(Node, D);
    {join, Node} ->
      find_successor(D, list_to_integer(string:substr(Node, 2)), 0, Node)
  end,
  loop(D).

find_successor(D = #data{}, ID, Time, StartNode) ->
  ModID = processing:modulo(ID, trunc(math:pow(2, D#data.finger_table_size))),
  NodeID = list_to_integer(string:substr(D#data.name, 2)),
  SuccessorID = list_to_integer(string:substr(D#data.successor, 2)),
  RingSize =trunc(math:pow(2, D#data.finger_table_size)),

  if ModID > NodeID, ModID =< SuccessorID ->
%%    io:format("find key position ~s for ~b in ~b times ~n", [D#data.successor, ID, Time]),
    sumMachine ! {found, Time},
    D#data.successor;
    ModID =:= NodeID ->
%%      io:format("find key position ~s for ~b in ~b times ~n", [D#data.name, ID, Time]),
      sumMachine ! {found, Time},
      D#data.name;
    ModID > D#data.nodeSize, ModID =< RingSize ->
%%      io:format("find key position ~s for ~b in ~b times ~n", ["n1", ID, Time]),
      sumMachine ! {found, Time},
      "n1";
    true ->
      Closest = closest_preceding_node(ModID, D, D#data.finger_table_size, 0),
%%      io:format("the closest node ~s found by node ~s for key ~b ~n", [Closest, D#data.name, ID]),
      list_to_atom(Closest) ! {findSuccessor, ID, Time, StartNode}
  end.

closest_preceding_node(ID, D, 0, Largest) ->
  if Largest =:= 0 ->
    D#data.name;
    true->
      string:concat("n", integer_to_list(Largest))
  end;
closest_preceding_node(ID, D = #data{}, M, Largest) ->
  CurNodeID = list_to_integer(string:substr(D#data.name, 2)),
  case ID < CurNodeID of
    true ->
%%      Temp = CurNodeID +  trunc(math:pow(2, D#data.finger_table_size - 1)),
%%      if Temp > D#data.nodeSize ->
%%
%%      {K, V} = lists:keyfind(Key, 1, D#data.finger_table),
%%      io:format("the closest node ~s that node ~s can find~n", [V, D#data.name]),
      "n1";
    false ->
      Key = CurNodeID +  trunc(math:pow(2, M - 1)),
      {K, V} = lists:keyfind(Key, 1, D#data.finger_table),
      ValueNum = list_to_integer(string:substr(V, 2)),
      case ValueNum =< ID of
        true ->
%%          io:format("the closest node ~s that node ~s can find~n", [V, D#data.name]),
          if ValueNum > Largest ->
            closest_preceding_node(ID, D, M-1, ValueNum);
            true ->
              closest_preceding_node(ID, D, M-1, Largest)
          end;
        false ->
          closest_preceding_node(ID, D, M - 1, Largest)
      end
  end.

sending_requests(D, NodeSize, 0) ->
  D#data{isFinished = 1};
sending_requests(D=#data{}, NodeSize, Time) ->
  ModRandomID = rand:uniform(NodeSize),
%%  io:format("node ~p start finding key ~b ~n", [D#data.name, ModRandomID]),
  find_successor(D,ModRandomID, 0, D#data.name),
  timer:sleep(1000),
  sending_requests(D, NodeSize, Time - 1).

notify(Node, D=#data{}) ->
  NodeNum = list_to_integer(string:substr(Node, 2)),
  CurNum = list_to_integer(string:substr(D#data.name, 2)),
  case D#data.predecessor =:= "" of
    true ->
      D#data{predecessor = Node};
    false ->
      PreNum = list_to_integer(string:substr(D#data.predecessor, 2)),
      if NodeNum > PreNum, NodeNum < CurNum ->
        D#data{predecessor = Node};
        true ->
          ok
      end
  end.

stabilize(D=#data{}) ->
  list_to_atom(D#data.successor) ! {getPredecessor, D#data.name},
  receive
    {predecessor, PreNode} ->
      PreNum = list_to_integer(string:substr(PreNode, 2)),
      CurNum = list_to_integer(string:substr(D#data.name, 2)),
      SucNum = list_to_integer(string:substr(D#data.successor, 2)),
      if PreNum > CurNum, PreNum < SucNum ->
        D#data{successor = PreNode};
        true ->
          ok
      end,
      list_to_atom(D#data.successor) ! {notifyNode, D#data.name}
  end.

fix_fingers(D=#data{}, Next) ->
  if Next > D#data.finger_table_size ->
    ok;
    true ->
      K = list_to_integer(string:substr(D#data.name, 2)) + math:pow(2, Next-1),
      Node = find_successor(D, K, 0, D#data.name),
      fix_fingers(D#data{finger_table = orddict:store(Next, Node, D#data.finger_table)}, Next+1)
  end.

check_predecessor(D=#data{}) ->
  list_to_atom(D#data.predecessor) ! {checkPre, D#data.name},
  receive
    {checkSuccess, PreName} ->
      ok
  after 1000 ->
    D#data{predecessor = ""}
  end.

init_finger_table(Node, Size, Table, Next, M) ->
  case Next =< M of
    true ->
      K = list_to_integer(string:substr(Node, 2)) + trunc(math:pow(2, Next-1)),
      Ring = trunc(math:pow(2, M)),
      Value =case K > Size of
              true ->
                case K > Ring of
                  true ->
                    string:concat("n", integer_to_list(K - Ring));
                  false ->
                    "n1"
                end;
              false ->
                string:concat("n", integer_to_list(K))
            end,
      init_finger_table(Node, Size, lists:append(Table, [{K, Value}]), Next+1, M);
    false ->
      Table
  end.

join(ExistedNode, Name, M, NodeSize, Request) ->
  NodeNum = list_to_integer(string:substr(Name, 2)),
  Suc = if NodeSize =:= NodeNum ->
              "n1";
          true ->
            string:concat("n", integer_to_list(NodeNum+1))
        end,
  Pre = string:concat("n", integer_to_list(NodeNum-1)),
  List = init_finger_table(Name, NodeSize, orddict:to_list(orddict:new()), 1, M),
  D = #data{successor = Suc, predecessor = Pre, name = Name, finger_table_size = M,
    nodeSize = NodeSize, finger_table = orddict:from_list(List), request = Request},
  timer:sleep(1000),
  sending_requests(D, NodeSize, Request),
  loop(D).

create(Name, M, NodeSize, Request) ->
  List = init_finger_table(Name, NodeSize, orddict:to_list(orddict:new()), 1, M),
  D = #data{successor = "n2", predecessor = "", name = Name, finger_table_size = M,
    nodeSize = NodeSize, finger_table = orddict:from_list(List), request = Request},
  loop(D).