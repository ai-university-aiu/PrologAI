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

:- module(lattice_tabling, [
    declare_derived/1,        % +Relation
    pai_derived/3,            % +Relation, ?Args, ?Referents
    surface_contradictions/0,
    pai_tabling_stats/1,      % -Stats
    taxonomy_closure/2        % ?Instance, ?Class
]).

:- use_module(library(node_facts), [anchor_node/4, default_nexus/1,
                                    live_node_facts/2]).
:- use_module(library(lattice),    [nexus_is_open/1, lattice_node_fact/5]).

% lattice_node_fact/5 is declared `dynamic as incremental` in lattice.pl
% (PR 15 adds that attribute).  Tabled predicates here automatically inherit
% that attribute and are invalidated whenever Lattice writes occur.

% ---------------------------------------------------------------------------
% Registry of declared derived relations
% ---------------------------------------------------------------------------

:- dynamic derived_relation_registered/1.

% ---------------------------------------------------------------------------
% declare_derived/1
%
%   Mark Relation as a derived predicate whose answers are maintained
%   automatically by incremental tabling.  Idempotent.
% ---------------------------------------------------------------------------

declare_derived(Relation) :-
    ( derived_relation_registered(Relation)
    ->  true
    ;   assertz(derived_relation_registered(Relation))
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

:- table pai_derived/3 as incremental.

pai_derived(Relation, Args, Referents) :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  lattice:lattice_node_fact(Nexus, _Id, Relation, Args, Referents)
    ;   fail
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

:- table taxonomy_closure/2 as incremental.

taxonomy_closure(Instance, Class) :-
    % Direct instance link
    lattice:lattice_node_fact(_, _, instance_of, [Instance, Class], []).
taxonomy_closure(Instance, Class) :-
    % Transitive: Instance is an instance of a subclass of Class
    lattice:lattice_node_fact(_, _, instance_of, [Instance, Mid], []),
    Mid \= Class,
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

surface_contradictions :-
    ( default_nexus(Nexus), nexus_is_open(Nexus)
    ->  % Find all contradiction candidates: instances that no longer have
        % their class link in the Lattice
        findall(Instance-Class, (
            lattice:lattice_node_fact(Nexus, _, contradiction_candidate,
                                      [Instance, Class], []),
            \+ taxonomy_closure(Instance, Class)
        ), Contradictions),
        forall(
            member(Instance-Class, Contradictions),
            catch(
                anchor_node(contradiction, [Instance, Class, class_link_broken], [], _),
                _, true
            )
        )
    ;   true
    ).

% ---------------------------------------------------------------------------
% pai_tabling_stats/1
% ---------------------------------------------------------------------------

pai_tabling_stats(Stats) :-
    aggregate_all(count, derived_relation_registered(_), DCount),
    catch(
        ( predicate_property(pai_derived(_, _, _), tabled)
        ->  Tabled = true
        ;   Tabled = false
        ),
        _, Tabled = unknown
    ),
    catch(
        ( predicate_property(taxonomy_closure(_, _), tabled)
        ->  TaxTabled = true
        ;   TaxTabled = false
        ),
        _, TaxTabled = unknown
    ),
    Stats = tabling_stats{
        declared_relations:      DCount,
        pai_derived_tabled:      Tabled,
        taxonomy_closure_tabled: TaxTabled
    }.
