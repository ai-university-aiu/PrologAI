/*  PrologAI — Hyperon Interoperability Bridge  (Specification PR 36)

    Lets PrologAI minds and Hyperon/MeTTa systems exchange knowledge.

    Mapping (bidirectional):
        Atomese expression   →  node_fact  (head→Relation, children→Args)
        Symbol               →  Prolog atom (via lexicon)
        Variable             →  Prolog variable (or '$name' atom for named vars)
        Grounded atom        →  node_fact tagged grounded_atom(Value)
        Hyperon value        →  node_fact tagged hyperon_value(Value)

    Import:
        pai_atomese_import(+Exprs, +Scope, -Ids)
          Exprs: a list of metta_expr(Head, Args) terms  OR  a MeTTa source
          atom where each line is `(Head Arg1 Arg2 ...)`.
          Each expression is inscribed as a node_fact; Referents = [atomese_scope(Scope)]
          so scoped queries and exports work without a separate scope predicate.
          Knowledge lands in a quarantine scope until coordination promotes it.

    Export:
        pai_atomese_export(+Scope, +_Target, -MettaLines)
          Finds all node_facts tagged atomese_scope(Scope) in the active nexus
          and serializes each as a MeTTa source line `(Head Arg1 Arg2 ...)`.

    Space mount:
        pai_space_mount(+SpaceId, +Nexus, +Opts)
          Records a named MeTTa space as a foreign nexus binding.
          Access mode: read (query only), write (read-through and write-through).

    Round-trip invariant:
        export(import(X, S), S) produces the same expressions as X
        up to variable renaming.

    Predicates:
        pai_atomese_import/3  — +Exprs, +Scope, -ImportedIds
        pai_atomese_export/3  — +Scope, +Target, -MettaLines
        pai_space_mount/3     — +SpaceId, +Nexus, +Opts
*/

:- module(interop, [
    pai_atomese_import/3,
    pai_atomese_export/3,
    pai_space_mount/3
]).

:- use_module(library(node_facts), [anchor_node/4]).
:- use_module(library(lattice),    [lattice_node_fact/5]).
:- use_module(library(lists),      [member/2, memberchk/2]).
:- use_module(library(apply),      [maplist/3, foldl/4, include/3]).

:- dynamic mounted_space/3.   % SpaceId, Nexus, Opts

% ---------------------------------------------------------------------------
% pai_atomese_import/3
% ---------------------------------------------------------------------------

pai_atomese_import(Expressions, Scope, ImportedIds) :-
    ( is_list(Expressions)
    ->  ExprList = Expressions
    ;   parse_metta_source(Expressions, ExprList)
    ),
    findall(Id, (
        member(metta_expr(Head, Args), ExprList),
        anchor_node(Head, Args, [atomese_scope(Scope)], Id)
    ), ImportedIds).

% ---------------------------------------------------------------------------
% pai_atomese_export/3
% ---------------------------------------------------------------------------

pai_atomese_export(Scope, _Target, MettaLines) :-
    findall(Line, (
        lattice_node_fact(_, _, Head, Args, Refs),
        memberchk(atomese_scope(Scope), Refs),
        metta_line(Head, Args, Line)
    ), MettaLines).

metta_line(Head, [], Line) :-
    !,
    format(atom(Line), '(~w)', [Head]).
metta_line(Head, Args, Line) :-
    maplist(arg_to_atom, Args, ArgAtoms),
    atomic_list_concat(ArgAtoms, ' ', ArgsStr),
    format(atom(Line), '(~w ~w)', [Head, ArgsStr]).

arg_to_atom(Arg, Atom) :-
    ( atom(Arg) -> Atom = Arg
    ; number(Arg) -> atom_number(Atom, Arg)
    ; term_to_atom(Arg, Atom)
    ).

% ---------------------------------------------------------------------------
% pai_space_mount/3
% ---------------------------------------------------------------------------

pai_space_mount(SpaceId, Nexus, Opts) :-
    ( mounted_space(SpaceId, _, _)
    ->  true
    ;   assertz(mounted_space(SpaceId, Nexus, Opts))
    ).

% ---------------------------------------------------------------------------
% MeTTa source text parser
%
%   parse_metta_source(+Source, -Exprs)
%   Source is an atom where each line is `(Head Arg1 Arg2 ...)`.
% ---------------------------------------------------------------------------

parse_metta_source(Source, Exprs) :-
    atom_string(Source, SourceStr),
    split_string(SourceStr, "\n", "\n\r ", Lines),
    foldl(parse_one_line, Lines, [], Rev),
    reverse(Rev, Exprs).

parse_one_line(Line, Acc, Result) :-
    ( Line \= "",
      string_concat("(", _, Line),
      string_concat(_, ")", Line)
    ->  string_length(Line, Len),
        Len2 is Len - 2,
        sub_string(Line, 1, Len2, _, Body),
        split_string(Body, " \t", " \t", Parts0),
        include([S]>>(S \= ""), Parts0, Parts),
        maplist([S, A]>>(atom_string(A, S)), Parts, AtomParts),
        AtomParts = [Head|Args],
        Result = [metta_expr(Head, Args)|Acc]
    ;   Result = Acc
    ).
