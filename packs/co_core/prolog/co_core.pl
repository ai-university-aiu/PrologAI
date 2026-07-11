/*  PrologAI — Causalontology Core  (WP-393, Layer 368)

    The VERB layer of the Causalontology Foundational Ontology (Causalontology_v5,
    Sections 3-5). Its fundamental unit is the reified Causal Relation
    Object (CRO):

        cro(Id, Causes, Effects,
            temporal(Dmin, Dmax, Unit),   % delay window = part of the mechanism
            Modality,                     % necessary|sufficient|contributory|preventive
            Strength,                     % in [0,1]
            Context,                      % enabling conditions
            prov(Source, Evidence, Conf)) % provenance envelope

    Commitments enforced here (Section 3.4):
      - Reified causation with the full payload, validated on assertion.
      - Strict separation of temporal from causal succession: mere sequence
        (co_precedes) is never read as production (co_causally_linked).
      - The temporal window is part of the mechanism: temporal abduction
        admits a candidate cause only when the elapsed time falls inside
        that cause's window (co_temporal_abduction/3).
      - Hierarchical decomposition: a CRO's mechanism may be a sub-graph of
        finer CROs, and co_hierarchy_consistent/1 checks the coarse relation
        against the composition of its parts (Section 6.2).
      - The subsumption argument (Section 3.2): an external causal relation
        is imported read-only as a degenerate, provisional CRO — some fields
        unspecified — and then refined into an owned relation, so replacement
        loses no information and strictly adds expressive power.
      - The glass-box guarantee: co_why/2 returns the full inspectable story
        of any relation.

    Predicates:
      co_core_reset/0            -- clear the verb layer
      co_cro_assert/1            -- +CRO           (validated)
      co_new_cro/8               -- +Causes..+Prov, -Id (fresh identifier)
      co_the_cro/2               -- ?Id, -CRO
      co_cro/8                   -- ?Id..?Prov     (open query)
      co_strengthen/2            -- +Id, +Delta    (capped at 0.99)
      co_predict/2               -- +Cause, -Effect (non-preventive)
      co_preventive/1            -- ?Id
      co_precedes_add/2          -- +A, +B         (temporal succession only)
      co_precedes/2              -- ?A, ?B
      co_causally_linked/2       -- +Cause, +Effect (via a CRO, never via time)
      co_after_but_not_because/2 -- +A, +B (sequence without production)
      co_temporal_admissible/3   -- +Cause, +Effect, +elapsed(T, Unit)
      co_temporal_abduction/3    -- +Effect, +Candidates, -Ranked
      co_decompose_add/2         -- +ParentId, +SubIds (mechanism sub-graph)
      co_mechanism/2             -- +ParentId, -SubIds
      co_hierarchy_consistent/1  -- +ParentId
      co_import_external/4       -- +Source, +Cause, +Effect, -Id (provisional)
      co_provisional/1           -- ?Id
      co_refine_import/4         -- +Id, +Temporal, +Modality, +Strength
      co_why/2                   -- +Id, -Why
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_core, [
    % co_core_reset/0: clear the verb layer.
    co_core_reset/0,
    % co_cro_assert/1: assert a validated CRO.
    co_cro_assert/1,
    % co_new_cro/8: assert a CRO under a fresh identifier.
    co_new_cro/8,
    % co_cro_find/4: find an existing relation by causes, effects, and modality.
    co_cro_find/4,
    % co_new_cro_unique/8: assert-if-new front door (no duplicate relations).
    co_new_cro_unique/8,
    % co_cro_dedup/1: remove content-duplicate relations, keeping the first.
    co_cro_dedup/1,
    % co_the_cro/2: fetch one CRO as a whole term.
    co_the_cro/2,
    % co_cro/8: open query over the CRO store.
    co_cro/8,
    % co_strengthen/2: raise a relation's strength, capped.
    co_strengthen/2,
    % co_predict/2: forward prediction from non-preventive relations.
    co_predict/2,
    % co_preventive/1: the preventive relations.
    co_preventive/1,
    % co_precedes_add/2: record mere temporal succession.
    co_precedes_add/2,
    % co_precedes/2: query temporal succession.
    co_precedes/2,
    % co_causally_linked/2: production, only ever through a CRO.
    co_causally_linked/2,
    % co_after_but_not_because/2: sequence that is not production.
    co_after_but_not_because/2,
    % co_temporal_admissible/3: the timing gate of the mechanism.
    co_temporal_admissible/3,
    % co_temporal_abduction/3: abduction filtered by temporal windows.
    co_temporal_abduction/3,
    % co_decompose_add/2: attach a mechanism sub-graph to a relation.
    co_decompose_add/2,
    % co_mechanism/2: read a relation's mechanism sub-graph.
    co_mechanism/2,
    % co_hierarchy_consistent/1: coarse relation vs composed fine relations.
    co_hierarchy_consistent/1,
    % co_import_external/4: subsumption — import a degenerate external verb.
    co_import_external/4,
    % co_provisional/1: imported relations not yet refined.
    co_provisional/1,
    % co_refine_import/4: refine an import into an owned relation.
    co_refine_import/4,
    % co_why/2: the glass-box story of a relation.
    co_why/2
]).

% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2, select/3, subtract/3]).
% Import the fresh-identifier generator.
:- use_module(library(gensym), [gensym/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% co_cro_/8: the reified Causal Relation Objects.
:- dynamic co_cro_/8.
% co_precedes_/2: mere temporal succession, never production.
:- dynamic co_precedes_/2.
% co_mechanism_/2: (ParentId, SubIds) — hierarchical decomposition.
:- dynamic co_mechanism_/2.

% Define co_core_reset: clear every verb-layer store.
co_core_reset :-
    % Drop the relations.
    retractall(co_cro_(_, _, _, _, _, _, _, _)),
    % Drop the succession records.
    retractall(co_precedes_(_, _)),
    % Drop the mechanism sub-graphs.
    retractall(co_mechanism_(_, _)).

% ---------------------------------------------------------------------------
% THE CRO — assertion with full-payload validation
% ---------------------------------------------------------------------------

% Define co_cro_assert: a CRO enters the store only with a lawful payload.
co_cro_assert(cro(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)) :-
    % Causes are a non-empty list of occurrents.
    is_list(Causes),
    % At least one cause.
    Causes \== [],
    % Effects are a non-empty list of occurrents.
    is_list(Effects),
    % At least one effect.
    Effects \== [],
    % The temporal window is part of the mechanism and must be well-formed.
    Temporal = temporal(Dmin, Dmax, _Unit),
    % The window's bounds must be ordered.
    co_window_ordered(Dmin, Dmax),
    % The modality is one of the four of the specification.
    memberchk(Modality, [necessary, sufficient, contributory, preventive]),
    % The strength is a fraction.
    number(Strength),
    % Lower bound.
    Strength >= 0.0,
    % Upper bound.
    Strength =< 1.0,
    % Enabling context conditions are a list.
    is_list(Context),
    % The provenance envelope is mandatory.
    Prov = prov(_Source, _Evidence, _Conf),
    % Replace any previous relation under this identifier.
    retractall(co_cro_(Id, _, _, _, _, _, _, _)),
    % Record the relation.
    assertz(co_cro_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)).

% co_window_ordered(+Dmin, +Dmax): bounds ordered; an unspecified max is open.
co_window_ordered(_, unspecified) :- !.
% Numeric bounds must be ordered.
co_window_ordered(Dmin, Dmax) :-
    % Both bounds are numbers.
    number(Dmin),
    % The maximum too.
    number(Dmax),
    % Ordered.
    Dmin =< Dmax.

% Define co_new_cro: assert under a fresh identifier and return it.
co_new_cro(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id) :-
    % Allocate a fresh identifier.
    gensym(cro_, Id),
    % Assert through the validating front door.
    co_cro_assert(cro(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)).

% ---------------------------------------------------------------------------
% FACT EXISTENCE — do not clutter the verb layer with duplicate relations
% ---------------------------------------------------------------------------

% co_cro_find(+Causes, +Effects, +Modality, -Id): the identifier of an existing
% relation with the same causes, effects, and modality, if one is present. Two
% relations are the same relation when those three agree; the strength, timing,
% and provenance are how a relation is refined, not what makes it distinct.
co_cro_find(Causes, Effects, Modality, Id) :-
    % A stored relation with matching causes, effects, and modality.
    co_cro_(Id, Causes, Effects, _, Modality, _, _, _),
    % The first match suffices.
    !.

% co_new_cro_unique(+Causes,+Effects,+Temporal,+Modality,+Strength,+Context,+Prov,
% -Id): the canonical assert-if-new front door for the verb layer. If a relation
% with the same causes, effects, and modality already exists, return its id and add
% nothing (the repeat is evidence, so its strength is raised a little); otherwise
% create a new relation. Ingest paths call this so re-running never duplicates.
co_new_cro_unique(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id) :-
    % Reuse an existing relation when present...
    (   co_cro_find(Causes, Effects, Modality, Existing)
    ->  Id = Existing,
        % A repeated assertion is confirmation; nudge the strength up (capped).
        catch(co_strengthen(Existing, 0.05), _, true)
    % ...otherwise create a genuinely new one.
    ;   co_new_cro(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id)
    ).

% co_cro_dedup(-Removed): remove content-duplicate relations, keeping the first of
% each (Causes, Effects, Modality) group and retracting the rest. Removed is how
% many were pruned. Cleans a store that accumulated duplicates before assert-if-new.
co_cro_dedup(Removed) :-
    % Every relation as a keyed record (content is the key, id the value).
    findall(k(Causes, Effects, Modality) - Id,
        co_cro_(Id, Causes, Effects, _, Modality, _, _, _),
        Pairs),
    % Group by content.
    keysort(Pairs, Sorted),
    % Collect the ids to prune (every id after the first in each content group).
    co_dedup_collect(Sorted, none, ToPrune),
    % Retract each duplicate relation.
    forall(member(Pid, ToPrune), retractall(co_cro_(Pid, _, _, _, _, _, _, _))),
    % How many were removed.
    length(ToPrune, Removed).

% co_dedup_collect(+SortedPairs, +PrevKey, -ToPrune): keep the first id of each
% content group, mark the rest for pruning.
co_dedup_collect([], _, []).
co_dedup_collect([Key - _Id | Rest], PrevKey, ToPrune) :-
    % A new content group: keep this id.
    Key \== PrevKey, !,
    co_dedup_collect(Rest, Key, ToPrune).
co_dedup_collect([Key - Id | Rest], Key, [Id | ToPrune]) :-
    % A repeat: this id is a duplicate to prune.
    co_dedup_collect(Rest, Key, ToPrune).

% Define co_the_cro: fetch one relation as a whole term.
co_the_cro(Id, cro(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)) :-
    % Read the store.
    co_cro_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov).

% Define co_cro: the open query over the store.
co_cro(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov) :-
    % Enumerate or test the store.
    co_cro_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov).

% Define co_strengthen: confirmation raises strength, capped at 0.99.
co_strengthen(Id, Delta) :-
    % Fetch the relation.
    retract(co_cro_(Id, Causes, Effects, T, M, S0, C, prov(Src, Ev, _))),
    % Raise the strength under the cap.
    S1 is min(0.99, S0 + Delta),
    % Store it back with the confidence tracking the strength.
    assertz(co_cro_(Id, Causes, Effects, T, M, S1, C, prov(Src, Ev, S1))).

% ---------------------------------------------------------------------------
% FORWARD PREDICTION
% ---------------------------------------------------------------------------

% Define co_predict: effects read from learned relations, never preventive ones.
co_predict(Cause, Effect) :-
    % A relation whose causes include this cause.
    co_cro_(_, Causes, Effects, _, Modality, _, _, _),
    % Preventive relations forbid rather than predict.
    Modality \== preventive,
    % The cause participates.
    memberchk(Cause, Causes),
    % Each of its effects is predicted.
    member(Effect, Effects).

% Define co_preventive: the relations that mark hazards.
co_preventive(Id) :-
    % Read the store for preventive modality.
    co_cro_(Id, _, _, _, preventive, _, _, _).

% ---------------------------------------------------------------------------
% TEMPORAL VERSUS CAUSAL SUCCESSION — "after" is never "because"
% ---------------------------------------------------------------------------

% Define co_precedes_add: record that A merely happened before B.
co_precedes_add(A, B) :-
    % Record the succession once.
    (   co_precedes_(A, B)
    % Already recorded.
    ->  true
    % New record.
    ;   assertz(co_precedes_(A, B))
    ).

% Define co_precedes: query mere temporal succession.
co_precedes(A, B) :-
    % Enumerate or test the store.
    co_precedes_(A, B).

% Define co_causally_linked: production holds only through a reified relation.
co_causally_linked(Cause, Effect) :-
    % Some relation carries the pair; succession alone never suffices.
    co_cro_(_, Causes, Effects, _, Modality, _, _, _),
    % Preventive relations are not production.
    Modality \== preventive,
    % The cause participates.
    memberchk(Cause, Causes),
    % The effect participates.
    memberchk(Effect, Effects).

% Define co_after_but_not_because: the discipline made queryable.
co_after_but_not_because(A, B) :-
    % A did come before B.
    co_precedes_(A, B),
    % But no relation produces B from A.
    \+ co_causally_linked(A, B).

% ---------------------------------------------------------------------------
% TIMING AS MECHANISM — the temporal admissibility gate
% ---------------------------------------------------------------------------

% Define co_temporal_admissible: elapsed time must fall inside the window.
co_temporal_admissible(Cause, Effect, elapsed(T, Unit)) :-
    % A relation for this cause and effect with a window in this unit.
    co_cro_(_, Causes, Effects, temporal(Dmin, Dmax, Unit), _, _, _, _),
    % The cause participates.
    memberchk(Cause, Causes),
    % The effect participates.
    memberchk(Effect, Effects),
    % The elapsed time is at or past the minimum delay.
    T >= Dmin,
    % And within the maximum delay.
    ( Dmax == unspecified -> true ; T =< Dmax ).

% Define co_temporal_abduction: candidates gated by their windows, ranked.
% Candidates are Cause-elapsed(T, Unit) pairs; Ranked is Strength-Cause pairs.
co_temporal_abduction(Effect, Candidates, Ranked) :-
    % Keep each candidate whose elapsed time its own window admits.
    findall(S-Cause,
        % Take each candidate in turn.
        ( member(Cause-elapsed(T, Unit), Candidates),
          % Fetch the relation and its window.
          co_cro_(_, Causes, Effects, temporal(Dmin, Dmax, Unit), _, S, _, _),
          % The cause participates.
          memberchk(Cause, Causes),
          % The effect participates.
          memberchk(Effect, Effects),
          % The timing gate: at or past the minimum delay.
          T >= Dmin,
          % And within the maximum delay.
          ( Dmax == unspecified -> true ; T =< Dmax ) ),
        Fits),
    % Rank the admissible causes by strength, strongest first.
    sort(0, @>=, Fits, Ranked).

% ---------------------------------------------------------------------------
% HIERARCHICAL DECOMPOSITION — the mechanism as a sub-graph
% ---------------------------------------------------------------------------

% Define co_decompose_add: attach the finer relations a mechanism comprises.
co_decompose_add(ParentId, SubIds) :-
    % The parent must exist.
    co_cro_(ParentId, _, _, _, _, _, _, _),
    % Every sub-relation must exist.
    forall(member(S, SubIds), co_cro_(S, _, _, _, _, _, _, _)),
    % Replace any previous decomposition.
    retractall(co_mechanism_(ParentId, _)),
    % Record the mechanism sub-graph.
    assertz(co_mechanism_(ParentId, SubIds)).

% Define co_mechanism: read a relation's mechanism sub-graph.
co_mechanism(ParentId, SubIds) :-
    % Enumerate or test the store.
    co_mechanism_(ParentId, SubIds).

% Define co_hierarchy_consistent: the coarse relation must agree with the
% composition of its parts — the sub-relations must chain from the parent's
% causes to the parent's effects (Section 6.2).
co_hierarchy_consistent(ParentId) :-
    % Fetch the parent's endpoints.
    co_cro_(ParentId, Causes, Effects, _, _, _, _, _),
    % Fetch the mechanism.
    co_mechanism_(ParentId, SubIds),
    % Chain the sub-relations from the causes to every effect.
    forall(member(E, Effects), co_chain_reaches(Causes, E, SubIds)).

% co_chain_reaches(+Frontier, +Target, +SubIds): the composition check.
co_chain_reaches(Frontier, Target, _) :-
    % The target is already produced.
    memberchk(Target, Frontier),
    % Done.
    !.
% Otherwise some unused sub-relation must fire from the frontier.
co_chain_reaches(Frontier, Target, SubIds) :-
    % Pick a sub-relation not yet used.
    select(Sub, SubIds, Rest),
    % Fetch its endpoints.
    co_cro_(Sub, SubCauses, SubEffects, _, _, _, _, _),
    % Every one of its causes must already be on the frontier.
    forall(member(C, SubCauses), memberchk(C, Frontier)),
    % Its effects join the frontier.
    append(Frontier, SubEffects, Frontier2),
    % Continue toward the target.
    co_chain_reaches(Frontier2, Target, Rest).

% ---------------------------------------------------------------------------
% THE SUBSUMPTION ARGUMENT — import external verbs as degenerate CROs
% ---------------------------------------------------------------------------

% Define co_import_external: an external causal assertion becomes a CRO in
% which the missing fields are unspecified — a degenerate special case.
co_import_external(Source, Cause, Effect, Id) :-
    % Allocate a fresh identifier.
    gensym(cro_, Id),
    % The import is provisional, read-only in spirit, owned once refined.
    co_cro_assert(cro(Id, [Cause], [Effect],
                      % The window the external vocabulary omitted.
                      temporal(0, unspecified, unspecified),
                      % The weakest modality that loses no information.
                      contributory,
                      % A neutral strength pending refinement.
                      0.5,
                      % Flagged provisional in the enabling context.
                      [provisional],
                      % Provenance names the external source.
                      prov(Source, imported_external, 0.5))).

% Define co_provisional: the imports not yet refined into owned relations.
co_provisional(Id) :-
    % A provisional flag in the context marks them.
    co_cro_(Id, _, _, _, _, _, Context, _),
    % Test the flag.
    memberchk(provisional, Context).

% Define co_refine_import: fill in the omitted payload; the relation is
% then owned, and strictly more expressive than the import it replaced.
co_refine_import(Id, Temporal, Modality, Strength) :-
    % Fetch the provisional relation.
    co_cro_(Id, Causes, Effects, _, _, _, Context, prov(Source, _, _)),
    % Only provisional imports are refined this way.
    memberchk(provisional, Context),
    % Drop the provisional flag.
    subtract(Context, [provisional], Context2),
    % Re-assert through the validating front door with the full payload.
    co_cro_assert(cro(Id, Causes, Effects, Temporal, Modality, Strength,
                      Context2, prov(Source, refined_after_import, Strength))).

% ---------------------------------------------------------------------------
% GLASS-BOX JUSTIFICATION
% ---------------------------------------------------------------------------

% Define co_why: the full inspectable story of a relation.
co_why(Id, why(Id, causes(Causes), effects(Effects), window(Temporal),
               modality(Modality), strength(Strength), context(Context),
               provenance(Prov), mechanism(SubIds))) :-
    % Fetch the relation.
    co_cro_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov),
    % Fetch its mechanism, empty when it has none.
    ( co_mechanism_(Id, SubIds) -> true ; SubIds = [] ).
