% Module declaration: pipeline pack, Layer 70.
:- module(pipeline, [
    % pl_run/3: apply a list of named step terms to an input, producing an output.
    pl_run/3,
    % pl_step/4: apply one named step term; dispatches to the registered handler.
    pl_step/4,
    % pl_register/2: assert a step handler predicate under a given step name.
    pl_register/2,
    % pl_registered/2: query which handler is registered for a step name.
    pl_registered/2,
    % pl_unregister/1: retract the handler for a step name.
    pl_unregister/1,
    % pl_map/3: apply a 2-argument goal to every element of a list; collect results.
    pl_map/3,
    % pl_filter/3: keep only elements of a list for which a 1-argument goal succeeds.
    pl_filter/3,
    % pl_fold/4: fold a 3-argument goal over a list with an initial accumulator.
    pl_fold/4,
    % pl_zip/3: pair corresponding elements from two lists into pairs.
    pl_zip/3,
    % pl_unzip/3: split a list of pairs into two parallel lists.
    pl_unzip/3,
    % pl_take/3: take the first N elements of a list.
    pl_take/3,
    % pl_drop/3: drop the first N elements of a list.
    pl_drop/3,
    % pl_partition/4: split a list into elements that satisfy a goal and those that do not.
    pl_partition/4
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).
% Import foldl for pl_run.
:- use_module(library(apply), [foldl/4]).

% Dynamic fact: pl_handler_(Name, Goal) registers a step handler.
:- dynamic pl_handler_/2.

% pl_register(+Name, +Goal).
% Assert that step Name is handled by Goal.
% Goal must be a 3-argument callable: Goal(Step, In, Out).
pl_register(Name, Goal) :-
    % Remove any existing handler for Name first.
    retractall(pl_handler_(Name, _)),
    % Assert the new handler.
    assertz(pl_handler_(Name, Goal)).

% pl_registered(+Name, -Goal).
% Succeed if Name has a registered handler; bind Goal to it.
pl_registered(Name, Goal) :-
    % Look up the dynamic fact.
    pl_handler_(Name, Goal).

% pl_unregister(+Name).
% Retract the handler for step Name. Succeeds even if none exists.
pl_unregister(Name) :-
    % Remove all handlers for this name.
    retractall(pl_handler_(Name, _)).

% pl_step(+StepTerm, +In, -Out, +Registry).
% Apply one step. StepTerm is a term Step(Args...) or an atom.
% Registry is a list of Name-Goal pairs; checked before dynamic facts.
% Dispatches to the registered handler Goal by calling Goal(StepTerm, In, Out).
pl_step(Step, In, Out, Registry) :-
    % Extract step name from the functor of StepTerm.
    pl_step_name_(Step, Name),
    % Look up in the local registry first, then dynamic facts.
    ( member(Name-Goal, Registry) ->
        call(Goal, Step, In, Out)
    ; pl_handler_(Name, Goal) ->
        call(Goal, Step, In, Out)
    ;   % No handler: pass In through unchanged.
        Out = In
    ).

% pl_step_name_(+Step, -Name): extract the step name.
pl_step_name_(Step, Name) :-
    % If Step is a compound term, use its functor name.
    ( compound(Step) ->
        functor(Step, Name, _)
    ;   % Otherwise Step is already an atom name.
        Name = Step
    ).

% pl_run(+Steps, +Input, -Output).
% Apply each step in Steps to Input in sequence, threading the grid.
% Steps is a list of step terms. Each step is dispatched via pl_step/4
% with an empty local registry (uses dynamic facts only).
pl_run(Steps, Input, Output) :-
    % Thread Input through all steps using foldl.
    foldl(pl_run_step_, Steps, Input, Output).

% pl_run_step_(+Step, +In, -Out): apply one step (used by foldl).
:- meta_predicate pl_run_step_(+, +, -).
pl_run_step_(Step, In, Out) :-
    % Apply the step using the empty registry.
    pl_step(Step, In, Out, []).

% pl_map(+Goal, +List, -Results).
% Apply a 2-argument goal to every element of List; collect results.
% Goal(Element, Result) is called for each element.
:- meta_predicate pl_map(2, +, -).
pl_map(Goal, List, Results) :-
    % Delegate to maplist/3 from library(apply).
    maplist(Goal, List, Results).

% pl_filter(+Goal, +List, -Kept).
% Keep only elements for which Goal(Element) succeeds.
:- meta_predicate pl_filter(1, +, -).
pl_filter(Goal, List, Kept) :-
    % Use findall for determinism: collect all elements that satisfy Goal.
    findall(H, (member(H, List), call(Goal, H)), Kept).

% pl_fold(+Goal, +List, +Acc0, -AccN).
% Fold Goal over List with initial accumulator Acc0.
% Goal(Element, AccIn, AccOut) is called for each element.
:- meta_predicate pl_fold(3, +, +, -).
pl_fold(Goal, List, Acc0, AccN) :-
    % Delegate to foldl/4 from library(apply).
    foldl(Goal, List, Acc0, AccN).

% pl_zip(+List1, +List2, -Pairs).
% Pair corresponding elements from two equal-length lists.
% Each pair is L1-L2.
pl_zip([], [], []).
pl_zip([H1|T1], [H2|T2], [H1-H2|Rest]) :-
    % Recurse on the tails.
    pl_zip(T1, T2, Rest).

% pl_unzip(+Pairs, -List1, -List2).
% Split a list of L-R pairs into two parallel lists.
pl_unzip([], [], []).
pl_unzip([L-R|Rest], [L|Ls], [R|Rs]) :-
    % Recurse on the tail.
    pl_unzip(Rest, Ls, Rs).

% pl_take(+N, +List, -Taken).
% Taken is the first N elements of List.
% If List has fewer than N elements, Taken = List.
pl_take(0, _, []) :- !.
pl_take(_, [], []) :- !.
pl_take(N, [H|T], [H|Rest]) :-
    % Decrement N and recurse.
    N1 is N - 1,
    pl_take(N1, T, Rest).

% pl_drop(+N, +List, -Remaining).
% Remaining is List with the first N elements removed.
% If List has fewer than N elements, Remaining = [].
pl_drop(0, List, List) :- !.
pl_drop(_, [], []) :- !.
pl_drop(N, [_|T], Rest) :-
    % Decrement N and recurse.
    N1 is N - 1,
    pl_drop(N1, T, Rest).

% pl_partition(+Goal, +List, -Satisfied, -Rejected).
% Split List into elements for which Goal(Element) succeeds (Satisfied)
% and those for which it fails (Rejected). Preserves order.
:- meta_predicate pl_partition(1, +, -, -).
pl_partition(Goal, List, Sat, Rej) :-
    % Use findall for determinism: two passes, one for each partition.
    findall(H, (member(H, List), call(Goal, H)), Sat),
    findall(H, (member(H, List), \+ call(Goal, H)), Rej).
