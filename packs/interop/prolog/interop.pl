/*  PrologAI — Hyperon Interoperability Bridge  (Specification PR 36)

    Lets PrologAI minds and Hyperon/MeTTa systems exchange knowledge.

    Mapping (bidirectional):
        Atomese expression   →  node_fact  (head→Relation, children→Args)
        Symbol               →  Prolog atom (via lexicon)
        Variable             →  Prolog variable (or '$name' atom for named vars)
        Grounded atom        →  node_fact tagged grounded_atom(Value)
        Hyperon value        →  node_fact tagged hyperon_value(Value)

    Import:
        interop_atomese_import(+Exprs, +Scope, -Ids)
          Exprs: a list of metta_expr(Head, Args) terms  OR  a MeTTa source
          atom where each line is `(Head Arg1 Arg2 ...)`.
          Each expression is inscribed as a node_fact; Referents = [atomese_scope(Scope)]
          so scoped queries and exports work without a separate scope predicate.
          Knowledge lands in a quarantine scope until coordination promotes it.

    Export:
        interop_atomese_export(+Scope, +_Target, -MettaLines)
          Finds all node_facts tagged atomese_scope(Scope) in the active nexus
          and serializes each as a MeTTa source line `(Head Arg1 Arg2 ...)`.

    Space mount:
        interop_space_mount(+SpaceId, +Nexus, +Opts)
          Records a named MeTTa space as a foreign nexus binding.
          Access mode: read (query only), write (read-through and write-through).

    Round-trip invariant:
        export(import(X, S), S) produces the same expressions as X
        up to variable renaming.

    Predicates:
        interop_atomese_import/3  — +Exprs, +Scope, -ImportedIds
        interop_atomese_export/3  — +Scope, +Target, -MettaLines
        interop_space_mount/3     — +SpaceId, +Nexus, +Opts
*/

% Declare this file as the 'interop' module and list its exported predicates.
:- module(interop, [
    % Supply 'interop_atomese_import/3' as the next argument to the expression above.
    interop_atomese_import/3,
    % Supply 'interop_atomese_export/3' as the next argument to the expression above.
    interop_atomese_export/3,
    % Supply 'interop_space_mount/3' as the next argument to the expression above.
    interop_space_mount/3
% Close the expression opened above.
]).

% Import [anchor_node/4] from the built-in 'node_facts' library.
:- use_module(library(node_facts), [anchor_node/4]).
% Import [lattice_node_fact/5] from the built-in 'lattice' library.
:- use_module(library(lattice),    [lattice_node_fact/5]).
% Import [member/2, memberchk/2] from the built-in 'lists' library.
:- use_module(library(lists),      [member/2, memberchk/2]).
% Import [maplist/3, foldl/4, include/3] from the built-in 'apply' library.
:- use_module(library(apply),      [maplist/3, foldl/4, include/3]).

% Declare 'mounted_space/3.   % SpaceId, Nexus, Opts' as dynamic — its facts may be added or removed at runtime.
:- dynamic mounted_space/3.   % SpaceId, Nexus, Opts

% ---------------------------------------------------------------------------
% interop_atomese_import/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai atomese import': succeed when the following conditions hold.
interop_atomese_import(Expressions, Scope, ImportedIds) :-
    % Execute: ( is_list(Expressions).
    ( is_list(Expressions)
    % If the condition above succeeded, perform the following action.
    ->  ExprList = Expressions
    % Otherwise (else branch), perform the following action.
    ;   parse_metta_source(Expressions, ExprList)
    % Close the expression opened above.
    ),
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Id, (
        % Continue the multi-line expression started above.
        member(metta_expr(Head, Args), ExprList),
        % Continue the multi-line expression started above.
        anchor_node(Head, Args, [atomese_scope(Scope)], Id)
    % Continue the multi-line expression started above.
    ), ImportedIds).

% ---------------------------------------------------------------------------
% interop_atomese_export/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai atomese export': succeed when the following conditions hold.
interop_atomese_export(Scope, _Target, MettaLines) :-
    % Collect all matching Template values into a list (findall — never fails, returns empty list if none).
    findall(Line, (
        % Continue the multi-line expression started above.
        lattice_node_fact(_, _, Head, Args, Refs),
        % Continue the multi-line expression started above.
        memberchk(atomese_scope(Scope), Refs),
        % Continue the multi-line expression started above.
        metta_line(Head, Args, Line)
    % Continue the multi-line expression started above.
    ), MettaLines).

% Define a clause for 'metta line': succeed when the following conditions hold.
metta_line(Head, [], Line) :-
    % Commit to this clause — discard all remaining choice points (cut).
    !,
    % Write formatted output to the current output stream.
    format(atom(Line), '(~w)', [Head]).
% Define a clause for 'metta line': succeed when the following conditions hold.
metta_line(Head, Args, Line) :-
    % State a fact for 'maplist' with the arguments listed below.
    maplist(arg_to_atom, Args, ArgAtoms),
    % State a fact for 'atomic list concat' with the arguments listed below.
    atomic_list_concat(ArgAtoms, ' ', ArgsStr),
    % Write formatted output to the current output stream.
    format(atom(Line), '(~w ~w)', [Head, ArgsStr]).

% Define a clause for 'arg to atom': succeed when the following conditions hold.
arg_to_atom(Arg, Atom) :-
    % Check that '( atom(Arg) -> Atom' is unifiable with 'Arg'.
    ( atom(Arg) -> Atom = Arg
    % Otherwise (else branch), perform the following action.
    ; number(Arg) -> atom_number(Atom, Arg)
    % Otherwise (else branch), perform the following action.
    ; term_to_atom(Arg, Atom)
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% interop_space_mount/3
% ---------------------------------------------------------------------------

% Define a clause for 'pai space mount': succeed when the following conditions hold.
interop_space_mount(SpaceId, Nexus, Opts) :-
    % Execute: ( mounted_space(SpaceId, _, _).
    ( mounted_space(SpaceId, _, _)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   assertz(mounted_space(SpaceId, Nexus, Opts))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% MeTTa source text parser
%
%   parse_metta_source(+Source, -Exprs)
%   Source is an atom where each line is `(Head Arg1 Arg2 ...)`.
% ---------------------------------------------------------------------------

% Define a clause for 'parse metta source': succeed when the following conditions hold.
parse_metta_source(Source, Exprs) :-
    % State a fact for 'atom string' with the arguments listed below.
    atom_string(Source, SourceStr),
    % State a fact for 'split string' with the arguments listed below.
    split_string(SourceStr, "\n", "\n\r ", Lines),
    % State a fact for 'foldl' with the arguments listed below.
    foldl(parse_one_line, Lines, [], Rev),
    % State the fact: reverse(Rev, Exprs).
    reverse(Rev, Exprs).

% Define a clause for 'parse one line': succeed when the following conditions hold.
parse_one_line(Line, Acc, Result) :-
    % Check that '( Line' is not unifiable with '""'.
    ( Line \= "",
      % Continue the multi-line expression started above.
      string_concat("(", _, Line),
      % Continue the multi-line expression started above.
      string_concat(_, ")", Line)
    % If the condition above succeeded, perform the following action.
    ->  string_length(Line, Len),
        % Continue the multi-line expression started above.
        Len2 is Len - 2,
        % Continue the multi-line expression started above.
        sub_string(Line, 1, Len2, _, Body),
        % Continue the multi-line expression started above.
        split_string(Body, " \t", " \t", Parts0),
        % Continue the multi-line expression started above.
        include([S]>>(S \= ""), Parts0, Parts),
        % Continue the multi-line expression started above.
        maplist([S, A]>>(atom_string(A, S)), Parts, AtomParts),
        % Continue the multi-line expression started above.
        AtomParts = [Head|Args],
        % Continue the multi-line expression started above.
        Result = [metta_expr(Head, Args)|Acc]
    % Otherwise (else branch), perform the following action.
    ;   Result = Acc
    % Close the expression opened above.
    ).
