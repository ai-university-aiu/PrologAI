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
        pai_type_declare/2  — +Subject, +Type  : declare Subject :: Type
        pai_type_of/2       — ?Subject, ?Type  : query declared types
        pai_type_check/2    — +Value, +Type    : check; inscribe ill_typed on mismatch
*/

:- module(types, [
    pai_type_declare/2,
    pai_type_of/2,
    pai_type_check/2
]).

:- use_module(library(node_facts), [anchor_node/4]).
:- use_module(library(lattice),    [lattice_node_fact/5]).

% ---------------------------------------------------------------------------
% pai_type_declare/2
%
%   Inscribe a type_of(Subject, Type) node_fact in the default nexus.
%   Idempotent: if an identical declaration already exists, skip.
% ---------------------------------------------------------------------------

pai_type_declare(Subject, Type) :-
    ( lattice_node_fact(_, _, type_of, [Subject, Type], _)
    ->  true
    ;   anchor_node(type_of, [Subject, Type], [], _)
    ).

% ---------------------------------------------------------------------------
% pai_type_of/2
%
%   Query all declared types.  Backtrackable.
% ---------------------------------------------------------------------------

pai_type_of(Subject, Type) :-
    lattice_node_fact(_, _, type_of, [Subject, Type], _).

% ---------------------------------------------------------------------------
% pai_type_check/2
%
%   Validate Value against Type using SWI-Prolog's must_be/2.
%   On type mismatch: inscribe an ill_typed node_fact naming the violation
%   and succeed anyway (gradual typing — the system never crashes).
%   On type match: succeed silently.
% ---------------------------------------------------------------------------

pai_type_check(Value, Type) :-
    ( catch(must_be(Type, Value), _, fail)
    ->  true
    ;   catch(anchor_node(ill_typed, [Value, Type], [], _), _, true)
    ).
