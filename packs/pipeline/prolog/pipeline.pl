% Module declaration: pipeline pack, Layer 70.
:- module(pipeline, [
    % pipeline_run/3: apply a list of named step terms to an input, producing an output.
    pipeline_run/3,
    % pipeline_step/4: apply one named step term; dispatches to the registered handler.
    pipeline_step/4,
    % pipeline_register/2: assert a step handler predicate under a given step name.
    pipeline_register/2,
    % pipeline_registered/2: query which handler is registered for a step name.
    pipeline_registered/2,
    % pipeline_unregister/1: retract the handler for a step name.
    pipeline_unregister/1,
    % pipeline_map/3: apply a 2-argument goal to every element of a list; collect results.
    pipeline_map/3,
    % pipeline_filter/3: keep only elements of a list for which a 1-argument goal succeeds.
    pipeline_filter/3,
    % pipeline_fold/4: fold a 3-argument goal over a list with an initial accumulator.
    pipeline_fold/4,
    % pipeline_zip/3: pair corresponding elements from two lists into pairs.
    pipeline_zip/3,
    % pipeline_unzip/3: split a list of pairs into two parallel lists.
    pipeline_unzip/3,
    % pipeline_take/3: take the first N elements of a list.
    pipeline_take/3,
    % pipeline_drop/3: drop the first N elements of a list.
    pipeline_drop/3,
    % pipeline_partition/4: split a list into elements that satisfy a goal and those that do not.
    pipeline_partition/4
]).

% Import list utilities; msort/length/forall are built-ins, not imported.
:- use_module(library(lists), [member/2, nth0/3, numlist/3, append/3]).
% Import higher-order apply utilities.
:- use_module(library(apply), [maplist/2, maplist/3]).
% Import foldl for pipeline_run.
:- use_module(library(apply), [foldl/4]).

% Dynamic fact: pipeline_handler_(Name, Goal) registers a step handler.
:- dynamic pipeline_handler_/2.

% pipeline_register(+Name, +Goal).
% Assert that step Name is handled by Goal.
% Goal must be a 3-argument callable: Goal(Step, In, Out).
pipeline_register(Name, Goal) :-
    % Remove any existing handler for Name first.
    retractall(pipeline_handler_(Name, _)),
    % Assert the new handler.
    assertz(pipeline_handler_(Name, Goal)).

% pipeline_registered(+Name, -Goal).
% Succeed if Name has a registered handler; bind Goal to it.
pipeline_registered(Name, Goal) :-
    % Look up the dynamic fact.
    pipeline_handler_(Name, Goal).

% pipeline_unregister(+Name).
% Retract the handler for step Name. Succeeds even if none exists.
pipeline_unregister(Name) :-
    % Remove all handlers for this name.
    retractall(pipeline_handler_(Name, _)).

% pipeline_step(+StepTerm, +In, -Out, +Registry).
% Apply one step. StepTerm is a term Step(Args...) or an atom.
% Registry is a list of Name-Goal pairs; checked before dynamic facts.
% Dispatches to the registered handler Goal by calling Goal(StepTerm, In, Out).
pipeline_step(Step, In, Out, Registry) :-
    % Extract step name from the functor of StepTerm.
    pipeline_step_name_(Step, Name),
    % Look up in the local registry first, then dynamic facts.
    ( member(Name-Goal, Registry) ->
        call(Goal, Step, In, Out)
    ; pipeline_handler_(Name, Goal) ->
        call(Goal, Step, In, Out)
    ;   % No handler: pass In through unchanged.
        Out = In
    ).

% pipeline_step_name_(+Step, -Name): extract the step name.
pipeline_step_name_(Step, Name) :-
    % If Step is a compound term, use its functor name.
    ( compound(Step) ->
        functor(Step, Name, _)
    ;   % Otherwise Step is already an atom name.
        Name = Step
    ).

% pipeline_run(+Steps, +Input, -Output).
% Apply each step in Steps to Input in sequence, threading the grid.
% Steps is a list of step terms. Each step is dispatched via pipeline_step/4
% with an empty local registry (uses dynamic facts only).
pipeline_run(Steps, Input, Output) :-
    % Thread Input through all steps using foldl.
    foldl(pipeline_run_step_, Steps, Input, Output).

% pipeline_run_step_(+Step, +In, -Out): apply one step (used by foldl).
:- meta_predicate pipeline_run_step_(+, +, -).
pipeline_run_step_(Step, In, Out) :-
    % Apply the step using the empty registry.
    pipeline_step(Step, In, Out, []).

% pipeline_map(+Goal, +List, -Results).
% Apply a 2-argument goal to every element of List; collect results.
% Goal(Element, Result) is called for each element.
:- meta_predicate pipeline_map(2, +, -).
pipeline_map(Goal, List, Results) :-
    % Delegate to maplist/3 from library(apply).
    maplist(Goal, List, Results).

% pipeline_filter(+Goal, +List, -Kept).
% Keep only elements for which Goal(Element) succeeds.
:- meta_predicate pipeline_filter(1, +, -).
pipeline_filter(Goal, List, Kept) :-
    % Use findall for determinism: collect all elements that satisfy Goal.
    findall(H, (member(H, List), call(Goal, H)), Kept).

% pipeline_fold(+Goal, +List, +Acc0, -AccN).
% Fold Goal over List with initial accumulator Acc0.
% Goal(Element, AccIn, AccOut) is called for each element.
:- meta_predicate pipeline_fold(3, +, +, -).
pipeline_fold(Goal, List, Acc0, AccN) :-
    % Delegate to foldl/4 from library(apply).
    foldl(Goal, List, Acc0, AccN).

% pipeline_zip(+List1, +List2, -Pairs).
% Pair corresponding elements from two equal-length lists.
% Each pair is L1-L2.
pipeline_zip([], [], []).
pipeline_zip([H1|T1], [H2|T2], [H1-H2|Rest]) :-
    % Recurse on the tails.
    pipeline_zip(T1, T2, Rest).

% pipeline_unzip(+Pairs, -List1, -List2).
% Split a list of L-R pairs into two parallel lists.
pipeline_unzip([], [], []).
pipeline_unzip([L-R|Rest], [L|Ls], [R|Rs]) :-
    % Recurse on the tail.
    pipeline_unzip(Rest, Ls, Rs).

% pipeline_take(+N, +List, -Taken).
% Taken is the first N elements of List.
% If List has fewer than N elements, Taken = List.
pipeline_take(0, _, []) :- !.
pipeline_take(_, [], []) :- !.
pipeline_take(N, [H|T], [H|Rest]) :-
    % Decrement N and recurse.
    N1 is N - 1,
    pipeline_take(N1, T, Rest).

% pipeline_drop(+N, +List, -Remaining).
% Remaining is List with the first N elements removed.
% If List has fewer than N elements, Remaining = [].
pipeline_drop(0, List, List) :- !.
pipeline_drop(_, [], []) :- !.
pipeline_drop(N, [_|T], Rest) :-
    % Decrement N and recurse.
    N1 is N - 1,
    pipeline_drop(N1, T, Rest).

% pipeline_partition(+Goal, +List, -Satisfied, -Rejected).
% Split List into elements for which Goal(Element) succeeds (Satisfied)
% and those for which it fails (Rejected). Preserves order.
:- meta_predicate pipeline_partition(1, +, -, -).
pipeline_partition(Goal, List, Sat, Rej) :-
    % Use findall for determinism: two passes, one for each partition.
    findall(H, (member(H, List), call(Goal, H)), Sat),
    findall(H, (member(H, List), \+ call(Goal, H)), Rej).
