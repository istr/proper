%%% -*- coding: utf-8 -*-
%%% -*- erlang-indent-level: 2 -*-
%%% -------------------------------------------------------------------
%%% Copyright 2010-2014 Manolis Papadakis <manopapad@gmail.com>,
%%%                     Eirini Arvaniti <eirinibob@gmail.com>
%%%                 and Kostis Sagonas <kostis@cs.ntua.gr>
%%%
%%% This file is part of PropEr.
%%%
%%% PropEr is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU General Public License as published by
%%% the Free Software Foundation, either version 3 of the License, or
%%% (at your option) any later version.
%%%
%%% PropEr is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with PropEr.  If not, see <http://www.gnu.org/licenses/>.

%%% @copyright 2010-2014 Manolis Papadakis, Eirini Arvaniti and Kostis Sagonas
%%% @version {@version}
%%% @author Eirini Arvaniti
%%% @doc Simple fsm test for the process dictionary

-module(pdict_fsm).
-behaviour(proper_fsm).

-export([test/0, test/1, sample_commands/0]).
-export([initial_state/0, initial_state_data/0, precondition/4, weight/3,
	 postcondition/5, next_state_data/5, empty_pdict/1, non_empty_pdict/1]).
-export([set_up/0, clean_up/0]).

-include_lib("proper/include/proper.hrl").

-define(KEYS, [a,b,c,d]).
-define(WRAP(T), proper:test_to_outer_test(T)).

%% A simple fsm test for the process dictionary; tests the
%% operations erlang:put/2, erlang:get/1, erlang:erase/1

-spec test() -> any().
test() ->
    test(100).

-spec test(_) -> any().
test(N) ->
    proper:quickcheck(?WRAP(prop_pdict()), N).

-spec prop_pdict() -> any().
prop_pdict() ->
    ?FORALL(Cmds, proper_fsm:commands(?MODULE),
	    begin
		set_up(),
		{H,S,Res} = proper_fsm:run_commands(?MODULE, Cmds),
		clean_up(),
		?WHENFAIL(
		   io:format("History: ~w\nState: ~w\nRes: ~w\n", [H, S, Res]),
		   aggregate(zip(proper_fsm:state_names(H),
				 command_names(Cmds)),
			     Res =:= ok))
	    end).

-spec set_up() -> ok.
set_up() -> ok.

-spec clean_up() -> ok.
clean_up() ->
    lists:foreach(fun(Key) -> erlang:erase(Key) end, ?KEYS).

-spec key() -> any().
key() ->
    elements(?KEYS).

-spec key([any()]) -> any().
key(List) ->
    elements(proplists:get_keys(List)).

-spec initial_state() -> empty_pdict.
initial_state() -> empty_pdict.

-spec initial_state_data() -> [].
initial_state_data() -> [].

-spec empty_pdict(_) -> [{non_empty_pdict, {call, erlang, put, [any(),...]}},...].
empty_pdict(_S) ->
    [{non_empty_pdict, {call,erlang,put,[key(),integer()]}}].

-spec non_empty_pdict([any()]) ->
    [{empty_pdict, {call, erlang, erase, [any(),...]}}
    | {history, {call, erlang, erase | get | put,[any(),...]}},...].
non_empty_pdict(S) ->
    [{history, {call,erlang,put,[key(),integer()]}},
     {history, {call,erlang,get,[key(S)]}},
     {history, {call,erlang,erase,[key(S)]}},
     {empty_pdict, {call,erlang,erase,[key(S)]}}].

-spec precondition(_,_,_,_) -> boolean().
precondition(non_empty_pdict, non_empty_pdict, S, {call,erlang,erase,[Key]}) ->
    proplists:is_defined(Key, S) andalso proplists:delete(Key, S) =/= [];
precondition(non_empty_pdict, empty_pdict, S, {call,erlang,erase,[Key]}) ->
    proplists:is_defined(Key, S) andalso proplists:delete(Key, S) =:= [];
precondition(_, _, S, {call,erlang,get,[Key]}) ->
    proplists:is_defined(Key, S);
precondition(_, _, _, {call,erlang,put,[_Key,_Val]}) ->
    true.

-spec postcondition(_,_,_,_,_) -> boolean().
postcondition(_, _, Props, {call,erlang,put,[Key,_]}, undefined) ->
    not proplists:is_defined(Key, Props);
postcondition(_, _, Props, {call,erlang,put,[Key,_]}, Old) ->
    [{Key,Old}] =:= proplists:lookup_all(Key, Props);
postcondition(_, _, Props, {call,erlang,get,[Key]}, Val) ->
    [{Key,Val}] =:= proplists:lookup_all(Key, Props);
postcondition(_, _, Props, {call,erlang,erase,[Key]}, Val) ->
    [{Key,Val}] =:= proplists:lookup_all(Key, Props).

-spec next_state_data(_,_,_,_,{call, erlang, erase | get | put, [any(),...]}) -> any().
next_state_data(_, _, Props, _Var, {call,erlang,put,[Key,Value]}) ->
    %% correct model
    [{Key,Value}|proplists:delete(Key, Props)];
    %% wrong model
    %% Props ++ [{Key,Value}];
next_state_data(_, _, Props, _Var, {call,erlang,erase,[Key]}) ->
    proplists:delete(Key, Props);
next_state_data(_, _, Props, _Var, {call,erlang,get,[_]}) ->
    Props.

-spec weight(_,_,{call, erlang, erase | get | put, _}) -> 2 | 5.
weight(_, _, {call,erlang,get,_}) -> 5;
weight(_, _, {call,erlang,erase,_}) -> 2;
weight(_, _, {call,erlang,put,_}) -> 5.

-spec sample_commands() -> any().
sample_commands() ->
    proper_gen:sample(proper_fsm:commands(?MODULE)).
