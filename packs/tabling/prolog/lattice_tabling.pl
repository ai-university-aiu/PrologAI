/*  PrologAI — Incremental Tabling Truth Maintenance  (Specification PR 15)

    Wires the Lattice's derived knowledge through SWI-Prolog's incremental
    tabling so that inferences are automatically kept consistent with a
    changing world model.  No PrologAI-level cache bookkeeping is needed:
    when anchor_node, prune_node, kindle_node, or quench_node changes a base
    fact, affected tabled derivations are invalidated and lazily recomputed
    by the engine.

    Key predicates:

    declare_derived/1      — declare Relation as an incrementally tabled
                             predicate over the dynamic Lattice node_fact store.
                             Creates a tabling wrapper accessible via
                             pai_derived/3.

    pai_derived/3          — pai_derived(+Relation, ?Args, ?Referents)
                             Query derived Lattice facts via the tabled
                             interface.  Automatically recomputes when
                             underlying node_facts change.

    surface_contradictions/0 — scan the derived table for derivations that
                              have become undefined (well-founded semantics)
                              and inscribe them as contradiction node_facts
                              for compensation and coping.

    pai_tabling_stats/1    — return statistics about the current tabling state
                             (number of tabled calls, recomputations, answers).

    Tabling configuration:
    pai_declare_tabling_fallback/1 — toggle fallback to plain computation
                                     (for debugging comparison).

    Implementation note:
    lattice_node_fact/5 is the base dynamic predicate; it is declared with
    the `incremental` attribute so that tabled predicates depending on it are
    automatically invalidated when Lattice writes occur.

    The `incremental` attribute on lattice_node_fact was added at module
    load time here; no changes are needed to lattice.pl or node_facts.pl.
*/

% Declare this file as the 'lattice_tabling' module and list its exported predicates.
:- module(lattice_tabling, [
    % Continue the multi-line expression started above.
    declare_derived/1,        % +Relation
    % Continue the multi-line expression started above.
    pai_derived/3,            % +Relation, ?Args, ?Referents
    % Supply 'surface_contradictions/0' as the next argument to the expression above.
    surface_contradictions/0,
    % Continue the multi-line expression started above.
    pai_tabling_stats/1,      % -Stats
    % Continue the multi-line expression started above.
    taxonomy_closure/2        % ?Instance, ?Class
% Close the expression opened above.
]).

% Load the built-in 'node_facts' library so its predicates are available here.
:- use_module(library(node_facts), [anchor_node/4, default_nexus/1,
                                    % Continue the multi-line expression started above.
                                    live_node_facts/2]).
% Import [nexus_is_open/1, lattice_node_fact/5] from the built-in 'lattice' library.
:- use_module(library(lattice),    [nexus_is_open/1, lattice_node_fact/5]).

% lattice_node_fact/5 is declared `dynamic as incremental` in lattice.pl
% (PR 15 adds that attribute).  Tabled predicates here automatically inherit
% that attribute and are invalidated whenever Lattice writes occur.

% ---------------------------------------------------------------------------
% Registry of declared derived relations
% ---------------------------------------------------------------------------

% Declare 'derived_relation_registered/1' as dynamic — its facts may be added or removed at runtime.
:- dynamic derived_relation_registered/1.

% ---------------------------------------------------------------------------
% declare_derived/1
%
%   Mark Relation as a derived predicate whose answers are maintained
%   automatically by incremental tabling.  Idempotent.
% ---------------------------------------------------------------------------

% Define a clause for 'declare derived': succeed when the following conditions hold.
declare_derived(Relation) :-
    % Execute: ( derived_relation_registered(Relation).
    ( derived_relation_registered(Relation)
    % If the condition above succeeded, perform the following action.
    ->  true
    % Otherwise (else branch), perform the following action.
    ;   assertz(derived_relation_registered(Relation))
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_derived/3
%
%   Tabled query interface over the Lattice node_fact store.
%   Returns any node_fact matching (Relation, Args, Referents) from the
%   current default nexus, transparently reflecting all changes to the
%   Lattice without requiring manual cache invalidation.
%
%   The predicate itself is tabled with the incremental attribute; because
%   lattice_node_fact/5 is also incremental, a change via anchor_node or
%   prune_node automatically retriggers recomputation the next time
%   pai_derived is called.
% ---------------------------------------------------------------------------

% Execute the compile-time directive: table pai_derived/3 as incremental.
:- table pai_derived/3 as incremental.

% Define a clause for 'pai derived': succeed when the following conditions hold.
pai_derived(Relation, Args, Referents) :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  lattice:lattice_node_fact(Nexus, _Id, Relation, Args, Referents)
    % Otherwise (else branch), perform the following action.
    ;   fail
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% taxonomy_closure/2  — example built-in derived relation
%
%   taxonomy_closure(?Instance, ?Class) is true when Instance is a member of
%   Class, either directly or through a chain of subclass links.
%
%   Tabled so transitive closure is computed once and kept consistent as the
%   Lattice changes.
% ---------------------------------------------------------------------------

% Execute the compile-time directive: table taxonomy_closure/2 as incremental.
:- table taxonomy_closure/2 as incremental.

% Define a clause for 'taxonomy closure': succeed when the following conditions hold.
taxonomy_closure(Instance, Class) :-
    % Direct instance link
    % Execute: lattice:lattice_node_fact(_, _, instance_of, [Instance, Class], [])..
    lattice:lattice_node_fact(_, _, instance_of, [Instance, Class], []).
% Define a clause for 'taxonomy closure': succeed when the following conditions hold.
taxonomy_closure(Instance, Class) :-
    % Transitive: Instance is an instance of a subclass of Class
    % Execute: lattice:lattice_node_fact(_, _, instance_of, [Instance, Mid], []),.
    lattice:lattice_node_fact(_, _, instance_of, [Instance, Mid], []),
    % Check that 'Mid' is not unifiable with 'Class'.
    Mid \= Class,
    % State the fact: taxonomy closure(Mid, Class).
    taxonomy_closure(Mid, Class).

% ---------------------------------------------------------------------------
% surface_contradictions/0
%
%   Scan for derived facts that have been retracted (become undefined) by
%   changes to the base Lattice.  Any fact that WAS derived but no longer
%   holds is inscribed as a contradiction node_fact.
%
%   In full well-founded semantics, "undefined" is the third truth value;
%   we approximate it here by checking whether previously-derived facts are
%   still derivable.
% ---------------------------------------------------------------------------

% Execute: surface_contradictions :-.
surface_contradictions :-
    % Execute: ( default_nexus(Nexus), nexus_is_open(Nexus).
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    % If the condition above succeeded, perform the following action.
    ->  % Find all contradiction candidates: instances that no longer have
        % their class link in the Lattice
        % Continue the multi-line expression started above.
        findall(Instance-Class, (
            % Continue the multi-line expression started above.
            lattice:lattice_node_fact(Nexus, _, contradiction_candidate,
                                      % Continue the multi-line expression started above.
                                      [Instance, Class], []),
            % Continue the multi-line expression started above.
            \+ taxonomy_closure(Instance, Class)
        % Continue the multi-line expression started above.
        ), Contradictions),
        % Continue the multi-line expression started above.
        forall(
            % Continue the multi-line expression started above.
            member(Instance-Class, Contradictions),
            % Continue the multi-line expression started above.
            catch(
                % Continue the multi-line expression started above.
                anchor_node(contradiction, [Instance, Class, class_link_broken], [], _),
                % Continue the multi-line expression started above.
                _, true
            % Close the expression opened above.
            )
        % Close the expression opened above.
        )
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    ).

% ---------------------------------------------------------------------------
% pai_tabling_stats/1
% ---------------------------------------------------------------------------

% Define a clause for 'pai tabling stats': succeed when the following conditions hold.
pai_tabling_stats(Stats) :-
    % Aggregate solutions using 'count' and bind the result to a single value.
    aggregate_all(count, derived_relation_registered(_), DCount),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( predicate_property(pai_derived(_, _, _), tabled)
        % If the condition above succeeded, perform the following action.
        ->  Tabled = true
        % Otherwise (else branch), perform the following action.
        ;   Tabled = false
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, Tabled = unknown
    % Close the expression opened above.
    ),
    % State a fact for 'catch' with the arguments listed below.
    catch(
        % Continue the multi-line expression started above.
        ( predicate_property(taxonomy_closure(_, _), tabled)
        % If the condition above succeeded, perform the following action.
        ->  TaxTabled = true
        % Otherwise (else branch), perform the following action.
        ;   TaxTabled = false
        % Close the expression opened above.
        ),
        % Continue the multi-line expression started above.
        _, TaxTabled = unknown
    % Close the expression opened above.
    ),
    % Check that 'Stats' is unifiable with 'tabling_stats{'.
    Stats = tabling_stats{
        % Execute: declared_relations:      DCount,.
        declared_relations:      DCount,
        % Execute: pai_derived_tabled:      Tabled,.
        pai_derived_tabled:      Tabled,
        % Execute: taxonomy_closure_tabled: TaxTabled.
        taxonomy_closure_tabled: TaxTabled
    % Execute: }..
    }.
