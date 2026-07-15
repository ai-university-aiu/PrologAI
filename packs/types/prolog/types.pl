/*  PrologAI — Gradual Lattice Types  (Specification PR 33)

    Lets the mind declare, check, and reason about the types of its own
    knowledge — adopted from MeTTa's types-as-atoms-in-the-space design.

    Design principles:
    - A type declaration is itself a node_fact (relation type_of) so types
      live in the Lattice, are queryable, learnable, and themselves typed.
    - Typing is gradual: untyped node_facts are always legal; the checker is
      off by default and can be hot-started on demand.
    - A violation never crashes anything: the checker inscribes an ill_typed
      node_fact naming the offending value and expected type, then continues.
    - SWI-Prolog's must_be/2 is the primitive type-checking layer.

    Predicates:
        types_type_declare/2  — +Subject, +Type  : declare Subject :: Type
        types_type_of/2       — ?Subject, ?Type  : query declared types
        types_type_check/2    — +Value, +Type    : check; inscribe ill_typed on mismatch
*/

% Declare this file as the 'types' module and list its exported predicates.
:- module(types, [
    % Supply 'types_type_declare/2' as the next argument to the expression above.
    types_type_declare/2,
    % Supply 'types_type_of/2' as the next argument to the expression above.
    types_type_of/2,
    % Supply 'types_type_check/2' as the next argument to the expression above.
    types_type_check/2
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [anchor_node/4]).
% Import [lattice_node_fact/5] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_node_fact/5]).

% ---------------------------------------------------------------------------
% types_type_declare/2
%
%   Inscribe a type_of(Subject, Type) node_fact in the default nexus.
%   Idempotent: if an identical declaration already exists, skip.
% ---------------------------------------------------------------------------

% Define a clause for 'pai type declare': succeed when the following conditions hold.
types_type_declare(Subject, Type) :-
    % Execute: ( lattice_node_fact(_, _, type_of, [Subject, Type], _).
    ( lattice_node_fact(_, _, type_of, [Subject, Type], _)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   anchor_node(type_of, [Subject, Type], [], _)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% types_type_of/2
%
%   Query all declared types.  Backtrackable.
% ---------------------------------------------------------------------------

% Define a clause for 'pai type of': succeed when the following conditions hold.
types_type_of(Subject, Type) :-
    % State the fact: lattice node fact(_, _, type_of, [Subject, Type], _).
    lattice_node_fact(_, _, type_of, [Subject, Type], _).

% ---------------------------------------------------------------------------
% types_type_check/2
%
%   Validate Value against Type using SWI-Prolog's must_be/2.
%   On type mismatch: inscribe an ill_typed node_fact naming the violation
%   and succeed anyway (gradual typing — the system never crashes).
%   On type match: succeed silently.
% ---------------------------------------------------------------------------

% Define a clause for 'pai type check': succeed when the following conditions hold.
types_type_check(Value, Type) :-
    % Execute: ( catch(must_be(Type, Value), _, fail).
    ( catch(must_be(Type, Value), _, fail)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   catch(anchor_node(ill_typed, [Value, Type], [], _), _, true)
    % Close the expression opened above.
    ).
