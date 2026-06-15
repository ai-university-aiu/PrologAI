/*  PrologAI — library/types  (Specification Section 3.14) */

:- module(pai_types, [
    pai_truth/2,
    pai_truth_assert/2,
    pai_uuid/1,
    pai_is_uuid/1,
    pai_constant/2,
    pai_constant_value/2
]).

:- use_module(library(apply), [maplist/2]).

%! pai_truth(+Term, -Value) is det.
%  Six-valued truth: true, false, paradox, neither, absurd, unknown.
pai_truth(true,    true)    :- !.
pai_truth(false,   false)   :- !.
pai_truth(unknown, unknown) :- !.
pai_truth(Term, true)  :- ground(Term), call(Term), !.
pai_truth(Term, false) :- ground(Term), \+ call(Term), !.
pai_truth(_,    unknown).

pai_truth_assert(Fact, true)  :- assertz(Fact), !.
pai_truth_assert(_Fact, false) :- !.
pai_truth_assert(_,    unknown).

%! pai_uuid(-UUID) is det.
pai_uuid(UUID) :-
    ( current_predicate(uuid/1)
    ->  uuid(UUID)
    ;   random_between(0, 0xFFFFFFFF,         A),
        random_between(0, 0xFFFF,             B),
        random_between(0, 0x0FFF,             C0), C is C0 \/ 0x4000,
        random_between(0, 0x3FFF,             D0), D is D0 \/ 0x8000,
        random_between(0, 0xFFFFFFFFFFFF,     E),
        format(atom(UUID), "~`0t~16r~8|-~`0t~16r~4|-~`0t~16r~4|-~`0t~16r~4|-~`0t~16r~12|",
               [A, B, C, D, E])
    ).

pai_is_uuid(A) :-
    atom(A),
    atom_length(A, 36),
    atom_codes(A, Codes),
    maplist([Code]>>( Code =:= 0'- ; code_type(Code, alnum) ), Codes).

:- dynamic pai_constant_entry/2.

pai_constant(Name, Value) :-
    ( pai_constant_entry(Name, _)
    ->  throw(error(permission_error(redefine, constant, Name), pai_constant/2))
    ;   assertz(pai_constant_entry(Name, Value))
    ).

pai_constant_value(Name, Value) :-
    pai_constant_entry(Name, Value).
