%%% Copyright 2010-2011 Manolis Papadakis <manopapad@gmail.com>,
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

%%% @copyright 2010-2011 Manolis Papadakis, Eirini Arvaniti and Kostis Sagonas
%%% @version {@version}
%%% @author Eirini Arvaniti

-module(error_statem).
-compile(export_all).

-include_lib("proper/include/proper.hrl").

-record(state, {step = 0::non_neg_integer()}).

-spec initial_state() -> #state{step::0}.
initial_state() ->
    #state{}.

-spec command(_) -> any().
command(_S) ->
    oneof([{call,?MODULE,foo,[integer()]},
	   {call,?MODULE,bar,[]}]).

-spec precondition(_,_) -> true.
precondition(_, _) ->
    true.

-spec next_state(#state{step::number()},_,_) -> #state{step::number()}.
next_state(#state{step=Step}, _, _) ->
    #state{step=Step+1}.

-spec postcondition(_,_,_) -> true.
postcondition(_, _, _) ->
    true.

-spec foo(_) -> ok.
foo(I) ->
    case I > 10 of
	false -> ok;
	true  -> throw(badarg)
    end.

-spec bar() -> 42.
bar() -> 42.

-spec prop_simple() -> any().
prop_simple() ->
    ?FORALL(Cmds, commands(?MODULE),
	    begin
		{_H,_S,Res} = run_commands(?MODULE, Cmds),
		equals(Res, ok)
	    end).
