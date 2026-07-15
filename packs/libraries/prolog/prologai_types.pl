/*  PrologAI — library/types  (Specification Section 3.14) */

% Declare this file as the 'prologai_types' module and list its exported predicates.
:- module(prologai_types, [
    % Supply 'prologai_truth/2' as the next argument to the expression above.
    prologai_truth/2,
    % Supply 'prologai_truth_assert/2' as the next argument to the expression above.
    prologai_truth_assert/2,
    % Supply 'prologai_uuid/1' as the next argument to the expression above.
    prologai_uuid/1,
    % Supply 'prologai_is_uuid/1' as the next argument to the expression above.
    prologai_is_uuid/1,
    % Supply 'prologai_constant/2' as the next argument to the expression above.
    prologai_constant/2,
    % Supply 'prologai_constant_value/2' as the next argument to the expression above.
    prologai_constant_value/2
% Close the expression opened above.
]).

% Import [maplist/2] from the built-in 'apply' library.
:- use_module(library(apply), [maplist/2]).

%! prologai_truth(+Term, -Value) is det.
%  Six-valued truth: true, false, paradox, neither, absurd, unknown.
% Define a clause for 'pai truth': succeed when the following conditions hold.
prologai_truth(true,    true)    :- !.
% Define a clause for 'pai truth': succeed when the following conditions hold.
prologai_truth(false,   false)   :- !.
% Define a clause for 'pai truth': succeed when the following conditions hold.
prologai_truth(unknown, unknown) :- !.
% Define a clause for 'pai truth': succeed when the following conditions hold.
prologai_truth(Term, true)  :- ground(Term), call(Term), !.
% Define a clause for 'pai truth': succeed when the following conditions hold.
prologai_truth(Term, false) :- ground(Term), \+ call(Term), !.
% State the fact: pai truth(_,    unknown).
prologai_truth(_,    unknown).

% Define a clause for 'pai truth assert': succeed when the following conditions hold.
prologai_truth_assert(Fact, true)  :- assertz(Fact), !.
% Define a clause for 'pai truth assert': succeed when the following conditions hold.
prologai_truth_assert(_Fact, false) :- !.
% State the fact: pai truth assert(_,    unknown).
prologai_truth_assert(_,    unknown).

%! prologai_uuid(-UUID) is det.
% Define a clause for 'pai uuid': succeed when the following conditions hold.
prologai_uuid(UUID) :-
    % Execute: ( current_predicate(uuid/1).
    ( current_predicate(uuid/1)
    % If the condition above succeeded, perform the following action.
    ->  uuid(UUID)
    % Otherwise (else branch), perform the following action.
    ;   random_between(0, 0xFFFFFFFF,         A),
        % Continue the multi-line expression started above.
        random_between(0, 0xFFFF,             B),
        % Continue the multi-line expression started above.
        random_between(0, 0x0FFF,             C0), C is C0 \/ 0x4000,
        % Continue the multi-line expression started above.
        random_between(0, 0x3FFF,             D0), D is D0 \/ 0x8000,
        % Continue the multi-line expression started above.
        random_between(0, 0xFFFFFFFFFFFF,     E),
        % Continue the multi-line expression started above.
        format(atom(UUID), "~`0t~16r~8|-~`0t~16r~4|-~`0t~16r~4|-~`0t~16r~4|-~`0t~16r~12|",
               % Continue the multi-line expression started above.
               [A, B, C, D, E])
    % Close the expression opened above.
    ).

% Define a clause for 'pai is uuid': succeed when the following conditions hold.
prologai_is_uuid(A) :-
    % State a fact for 'atom' with the arguments listed below.
    atom(A),
    % State a fact for 'atom length' with the arguments listed below.
    atom_length(A, 36),
    % State a fact for 'atom codes' with the arguments listed below.
    atom_codes(A, Codes),
    % Check that 'maplist([Code]>>( Code' is numerically equal to '0'- ; code_type(Code, alnum) ), Codes)'.
    maplist([Code]>>( Code =:= 0'- ; code_type(Code, alnum) ), Codes).

% Continue the multi-line expression started above.
:- dynamic prologai_constant_entry/2.

% Continue the multi-line expression started above.
prologai_constant(Name, Value) :-
    % Continue the multi-line expression started above.
    ( prologai_constant_entry(Name, _)
    % If the condition above succeeded, perform the following action.
    ->  throw(error(permission_error(redefine, constant, Name), prologai_constant/2))
    % Otherwise (else branch), perform the following action.
    ;   assertz(prologai_constant_entry(Name, Value))
    % Close the expression opened above.
    ).

% Continue the multi-line expression started above.
prologai_constant_value(Name, Value) :-
    % Continue the multi-line expression started above.
    prologai_constant_entry(Name, Value).
