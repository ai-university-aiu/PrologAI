/*  PrologAI — Causalontology Core  (WP-393, Layer 368)

    The VERB layer of the Causalontology Foundational Ontology (Causalontology_v5,
    Sections 3-5). Its fundamental unit is the reified Causal Relation
    Object (causal_relation_object):

        causal_relation_object(Id, Causes, Effects,
            temporal(Dmin, Dmax, Unit),   % delay window = part of the mechanism
            Modality,                     % necessary|sufficient|contributory|preventive
            Strength,                     % in [0,1]
            Context,                      % enabling conditions
            prov(Source, Evidence, Conf)) % provenance envelope

    Commitments enforced here (Section 3.4):
      - Reified causation with the full payload, validated on assertion.
      - Strict separation of temporal from causal succession: mere sequence
        (causal_core_precedes) is never read as production (causal_core_causally_linked).
      - The temporal window is part of the mechanism: temporal abduction
        admits a candidate cause only when the elapsed time falls inside
        that cause's window (causal_core_temporal_abduction/3).
      - Hierarchical decomposition: a causal_relation_object's mechanism may be a sub-graph of
        finer causal_relation_objects, and causal_core_hierarchy_consistent/1 checks the coarse relation
        against the composition of its parts (Section 6.2).
      - The subsumption argument (Section 3.2): an external causal relation
        is imported read-only as a degenerate, provisional causal_relation_object — some fields
        unspecified — and then refined into an owned relation, so replacement
        loses no information and strictly adds expressive power.
      - The glass-box guarantee: causal_core_why/2 returns the full inspectable story
        of any relation.

    Predicates:
      causal_core_reset/0            -- clear the verb layer
      causal_core_causal_relation_object_assert/1            -- +causal_relation_object           (validated)
      causal_core_new_causal_relation_object/8               -- +Causes..+Prov, -Id (fresh identifier)
      causal_core_the_causal_relation_object/2               -- ?Id, -causal_relation_object
      causal_core_causal_relation_object/8                   -- ?Id..?Prov     (open query)
      causal_core_strengthen/2            -- +Id, +Delta    (capped at 0.99)
      causal_core_predict/2               -- +Cause, -Effect (non-preventive)
      causal_core_preventive/1            -- ?Id
      causal_core_precedes_add/2          -- +A, +B         (temporal succession only)
      causal_core_precedes/2              -- ?A, ?B
      causal_core_causally_linked/2       -- +Cause, +Effect (via a causal_relation_object, never via time)
      causal_core_after_but_not_because/2 -- +A, +B (sequence without production)
      causal_core_temporal_admissible/3   -- +Cause, +Effect, +elapsed(T, Unit)
      causal_core_temporal_abduction/3    -- +Effect, +Candidates, -Ranked
      causal_core_decompose_add/2         -- +ParentId, +SubIds (mechanism sub-graph)
      causal_core_mechanism/2             -- +ParentId, -SubIds
      causal_core_hierarchy_consistent/1  -- +ParentId
      causal_core_import_external/4       -- +Source, +Cause, +Effect, -Id (provisional)
      causal_core_provisional/1           -- ?Id
      causal_core_refine_import/4         -- +Id, +Temporal, +Modality, +Strength
      causal_core_why/2                   -- +Id, -Why
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(causal_core, [
    % causal_core_reset/0: clear the verb layer.
    causal_core_reset/0,
    % causal_core_causal_relation_object_assert/1: assert a validated causal_relation_object.
    causal_core_causal_relation_object_assert/1,
    % causal_core_new_causal_relation_object/8: assert a causal_relation_object under a fresh identifier.
    causal_core_new_causal_relation_object/8,
    % causal_core_causal_relation_object_find/4: coarse finder by causes, effects, and modality.
    causal_core_causal_relation_object_find/4,
    % causal_core_causal_relation_object_find_exact/7: find a relation identical in every defining field.
    causal_core_causal_relation_object_find_exact/7,
    % causal_core_causal_relation_object_find_core/3: find a relation with the same core (causes+effects).
    causal_core_causal_relation_object_find_core/3,
    % causal_core_causal_relation_object_delta/6: the fields in which a candidate differs from a relation.
    causal_core_causal_relation_object_delta/6,
    % causal_core_new_causal_relation_object_unique/8: assert-if-new front door (exact merges; near kept).
    causal_core_new_causal_relation_object_unique/8,
    % causal_core_new_causal_relation_object_nuanced/9: assert door reporting exact/variant/new status.
    causal_core_new_causal_relation_object_nuanced/9,
    % causal_core_causal_relation_object_variant/3: query the near-duplicate variant links and their deltas.
    causal_core_causal_relation_object_variant/3,
    % causal_core_causal_relation_object_variants/1: all variant links, for surfacing flagged near-duplicates.
    causal_core_causal_relation_object_variants/1,
    % causal_core_causal_relation_object_dedup/1: remove only EXACT-duplicate relations, keeping variants.
    causal_core_causal_relation_object_dedup/1,
    % causal_core_the_causal_relation_object/2: fetch one causal_relation_object as a whole term.
    causal_core_the_causal_relation_object/2,
    % causal_core_causal_relation_object/8: open query over the causal_relation_object store.
    causal_core_causal_relation_object/8,
    % causal_core_strengthen/2: raise a relation's strength, capped.
    causal_core_strengthen/2,
    % causal_core_predict/2: forward prediction from non-preventive relations.
    causal_core_predict/2,
    % causal_core_preventive/1: the preventive relations.
    causal_core_preventive/1,
    % causal_core_precedes_add/2: record mere temporal succession.
    causal_core_precedes_add/2,
    % causal_core_precedes/2: query temporal succession.
    causal_core_precedes/2,
    % causal_core_causally_linked/2: production, only ever through a causal_relation_object.
    causal_core_causally_linked/2,
    % causal_core_after_but_not_because/2: sequence that is not production.
    causal_core_after_but_not_because/2,
    % causal_core_temporal_admissible/3: the timing gate of the mechanism.
    causal_core_temporal_admissible/3,
    % causal_core_temporal_abduction/3: abduction filtered by temporal windows.
    causal_core_temporal_abduction/3,
    % causal_core_decompose_add/2: attach a mechanism sub-graph to a relation.
    causal_core_decompose_add/2,
    % causal_core_mechanism/2: read a relation's mechanism sub-graph.
    causal_core_mechanism/2,
    % causal_core_hierarchy_consistent/1: coarse relation vs composed fine relations.
    causal_core_hierarchy_consistent/1,
    % causal_core_import_external/4: subsumption — import a degenerate external verb.
    causal_core_import_external/4,
    % causal_core_provisional/1: imported relations not yet refined.
    causal_core_provisional/1,
    % causal_core_refine_import/4: refine an import into an owned relation.
    causal_core_refine_import/4,
    % causal_core_why/2: the glass-box story of a relation.
    causal_core_why/2
]).

% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2, select/3, subtract/3]).
% Import the fresh-identifier generator.
:- use_module(library(gensym), [gensym/2]).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% causal_core_causal_relation_object_/8: the reified Causal Relation Objects.
:- dynamic causal_core_causal_relation_object_/8.
% causal_core_precedes_/2: mere temporal succession, never production.
:- dynamic causal_core_precedes_/2.
% causal_core_mechanism_/2: (ParentId, SubIds) — hierarchical decomposition.
:- dynamic causal_core_mechanism_/2.

% Define causal_core_reset: clear every verb-layer store.
causal_core_reset :-
    % Drop the relations.
    retractall(causal_core_causal_relation_object_(_, _, _, _, _, _, _, _)),
    % Drop the succession records.
    retractall(causal_core_precedes_(_, _)),
    % Drop the mechanism sub-graphs.
    retractall(causal_core_mechanism_(_, _)).

% ---------------------------------------------------------------------------
% THE causal_relation_object — assertion with full-payload validation
% ---------------------------------------------------------------------------

% Define causal_core_causal_relation_object_assert: a causal_relation_object enters the store only with a lawful payload.
causal_core_causal_relation_object_assert(causal_relation_object(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)) :-
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
    causal_core_window_ordered(Dmin, Dmax),
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
    retractall(causal_core_causal_relation_object_(Id, _, _, _, _, _, _, _)),
    % Record the relation.
    assertz(causal_core_causal_relation_object_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)).

% causal_core_window_ordered(+Dmin, +Dmax): bounds ordered; an unspecified max is open.
causal_core_window_ordered(_, unspecified) :- !.
% Numeric bounds must be ordered.
causal_core_window_ordered(Dmin, Dmax) :-
    % Both bounds are numbers.
    number(Dmin),
    % The maximum too.
    number(Dmax),
    % Ordered.
    Dmin =< Dmax.

% Define causal_core_new_causal_relation_object: assert under a fresh identifier and return it.
causal_core_new_causal_relation_object(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id) :-
    % Allocate a fresh identifier.
    gensym(causal_relation_object_, Id),
    % Assert through the validating front door.
    causal_core_causal_relation_object_assert(causal_relation_object(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)).

% ---------------------------------------------------------------------------
% FACT EXISTENCE — merge only EXACT duplicates; keep near-duplicates as variants
% ---------------------------------------------------------------------------
%
% The nuance the mentor asked for: a subtle difference in a relation may be a
% nugget of gold, so only a relation identical in EVERY defining field is treated
% as a duplicate and merged (its strength raised as confirmation). A near-duplicate
% — the same core relation (same causes and effects) that differs in any detail
% (modality, timing, enabling context, or provenance) — is NOT merged: both are
% kept, they are linked as variants of each other, and the delta (exactly which
% fields differ) is recorded so it can be surfaced for attention. A relation with a
% different core is simply new. The mutable strength is not part of a relation's
% identity (it is how a relation is reinforced), so it is excluded from the match.

% causal_core_causal_relation_object_variant_/3: (CanonicalId, VariantId, Deltas) — two relations that share a
% core but differ in some detail, with the list of differing fields.
:- dynamic causal_core_causal_relation_object_variant_/3.

% causal_core_causal_relation_object_find(+Causes, +Effects, +Modality, -Id): a coarse finder kept for callers
% that want the first relation matching causes, effects, and modality. This is NOT
% the merge test — merging uses the exact finder below.
causal_core_causal_relation_object_find(Causes, Effects, Modality, Id) :-
    % A stored relation with matching causes, effects, and modality.
    causal_core_causal_relation_object_(Id, Causes, Effects, _, Modality, _, _, _),
    % The first match suffices.
    !.

% causal_core_causal_relation_object_find_exact(+Causes,+Effects,+Temporal,+Modality,+Context,+Prov, -Id): the
% id of a relation identical in EVERY defining field (strength excluded). Only such
% a relation is a true duplicate to merge.
causal_core_causal_relation_object_find_exact(Causes, Effects, Temporal, Modality, Context, Prov, Id) :-
    % All defining fields unify; the strength is left free.
    causal_core_causal_relation_object_(Id, Causes, Effects, Temporal, Modality, _Strength, Context, Prov),
    % The first exact match suffices.
    !.

% causal_core_causal_relation_object_find_core(+Causes, +Effects, -Id): the id of an existing relation with the
% same core — the same causes and effects — regardless of the other fields. A core
% match that is not an exact match is a near-duplicate (a variant).
causal_core_causal_relation_object_find_core(Causes, Effects, Id) :-
    % The first relation relating the same cause to the same effect.
    causal_core_causal_relation_object_(Id, Causes, Effects, _, _, _, _, _),
    % One is enough.
    !.

% causal_core_causal_relation_object_delta(+ExistingId, +Temporal,+Modality,+Context,+Prov, -Deltas): the list
% of fields in which a candidate differs from an existing relation, each as
% delta(Field, ExistingValue, NewValue). Empty when only the strength differs.
causal_core_causal_relation_object_delta(ExistingId, Temporal, Modality, Context, Prov, Deltas) :-
    % The existing relation's non-core fields.
    causal_core_causal_relation_object_(ExistingId, _, _, T0, M0, _, C0, P0),
    % Collect each differing field.
    findall(delta(Field, Old, New),
        ( member(f(Field, Old, New),
              [ f(temporal, T0, Temporal), f(modality, M0, Modality),
                f(context,  C0, Context),  f(prov,     P0, Prov) ]),
          Old \== New ),
        Deltas).

% causal_core_new_causal_relation_object_nuanced(+Causes,+Effects,+Temporal,+Modality,+Strength,+Context,+Prov,
% -Id, -Status): the nuanced assert door. Status is exact(ExistingId) when an
% identical relation was merged, variant(CanonicalId, Deltas) when a near-duplicate
% was kept and linked, or new when the relation had no core match.
causal_core_new_causal_relation_object_nuanced(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id, Status) :-
    (   % EXACT duplicate: merge — reuse the id and raise its strength as evidence.
        causal_core_causal_relation_object_find_exact(Causes, Effects, Temporal, Modality, Context, Prov, Ex)
    ->  Id = Ex,
        catch(causal_core_strengthen(Ex, 0.05), _, true),
        Status = exact(Ex)
    ;   % NEAR duplicate: same core, differs in a detail — keep both, link, flag.
        causal_core_causal_relation_object_find_core(Causes, Effects, Canonical)
    ->  causal_core_new_causal_relation_object(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id),
        causal_core_causal_relation_object_delta(Canonical, Temporal, Modality, Context, Prov, Deltas),
        assertz(causal_core_causal_relation_object_variant_(Canonical, Id, Deltas)),
        Status = variant(Canonical, Deltas)
    ;   % Genuinely new relation.
        causal_core_new_causal_relation_object(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id),
        Status = new
    ).

% causal_core_new_causal_relation_object_unique(+Causes,+Effects,+Temporal,+Modality,+Strength,+Context,+Prov,
% -Id): the assert-if-new front door ingest paths call. It merges only an EXACT
% duplicate; a near-duplicate is kept as a linked variant (see causal_core_new_causal_relation_object_nuanced),
% so a subtle difference is never silently merged away. Returns the relation's id.
causal_core_new_causal_relation_object_unique(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id) :-
    causal_core_new_causal_relation_object_nuanced(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id, _Status).

% causal_core_causal_relation_object_variant(?CanonicalId, ?VariantId, ?Deltas): query the variant links — the
% near-duplicate relations kept apart and the fields in which each differs.
causal_core_causal_relation_object_variant(CanonicalId, VariantId, Deltas) :-
    causal_core_causal_relation_object_variant_(CanonicalId, VariantId, Deltas).

% causal_core_causal_relation_object_variants(-List): every variant link as variant(Canonical, Variant, Deltas),
% for surfacing the flagged near-duplicates that want attention.
causal_core_causal_relation_object_variants(List) :-
    findall(variant(C, V, D), causal_core_causal_relation_object_variant_(C, V, D), List).

% causal_core_causal_relation_object_dedup(-Removed): remove only EXACT-duplicate relations, keeping the first
% of each fully-identical group and retracting the rest; near-duplicate variants
% are never removed. Removed is how many were pruned.
causal_core_causal_relation_object_dedup(Removed) :-
    % Key each relation by its FULL defining content (strength excluded).
    findall(k(Causes, Effects, Temporal, Modality, Context, Prov) - Id,
        causal_core_causal_relation_object_(Id, Causes, Effects, Temporal, Modality, _S, Context, Prov),
        Pairs),
    % Group by identical content.
    keysort(Pairs, Sorted),
    % Every id after the first in each identical group is an exact duplicate.
    causal_core_dedup_collect(Sorted, none, ToPrune),
    % Retract each exact duplicate; leave variant links untouched.
    forall(member(Pid, ToPrune),
        ( retractall(causal_core_causal_relation_object_(Pid, _, _, _, _, _, _, _)),
          retractall(causal_core_causal_relation_object_variant_(_, Pid, _)),
          retractall(causal_core_causal_relation_object_variant_(Pid, _, _)) )),
    % How many were removed.
    length(ToPrune, Removed).

% causal_core_dedup_collect(+SortedPairs, +PrevKey, -ToPrune): keep the first id of each
% content group, mark the rest for pruning.
causal_core_dedup_collect([], _, []).
causal_core_dedup_collect([Key - _Id | Rest], PrevKey, ToPrune) :-
    % A new content group: keep this id.
    Key \== PrevKey, !,
    causal_core_dedup_collect(Rest, Key, ToPrune).
causal_core_dedup_collect([Key - Id | Rest], Key, [Id | ToPrune]) :-
    % A repeat: this id is a duplicate to prune.
    causal_core_dedup_collect(Rest, Key, ToPrune).

% Define causal_core_the_causal_relation_object: fetch one relation as a whole term.
causal_core_the_causal_relation_object(Id, causal_relation_object(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)) :-
    % Read the store.
    causal_core_causal_relation_object_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov).

% Define causal_core_causal_relation_object: the open query over the store.
causal_core_causal_relation_object(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov) :-
    % Enumerate or test the store.
    causal_core_causal_relation_object_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov).

% Define causal_core_strengthen: confirmation raises strength, capped at 0.99.
causal_core_strengthen(Id, Delta) :-
    % Fetch the relation.
    retract(causal_core_causal_relation_object_(Id, Causes, Effects, T, M, S0, C, prov(Src, Ev, _))),
    % Raise the strength under the cap.
    S1 is min(0.99, S0 + Delta),
    % Store it back with the confidence tracking the strength.
    assertz(causal_core_causal_relation_object_(Id, Causes, Effects, T, M, S1, C, prov(Src, Ev, S1))).

% ---------------------------------------------------------------------------
% FORWARD PREDICTION
% ---------------------------------------------------------------------------

% Define causal_core_predict: effects read from learned relations, never preventive ones.
causal_core_predict(Cause, Effect) :-
    % A relation whose causes include this cause.
    causal_core_causal_relation_object_(_, Causes, Effects, _, Modality, _, _, _),
    % Preventive relations forbid rather than predict.
    Modality \== preventive,
    % The cause participates.
    memberchk(Cause, Causes),
    % Each of its effects is predicted.
    member(Effect, Effects).

% Define causal_core_preventive: the relations that mark hazards.
causal_core_preventive(Id) :-
    % Read the store for preventive modality.
    causal_core_causal_relation_object_(Id, _, _, _, preventive, _, _, _).

% ---------------------------------------------------------------------------
% TEMPORAL VERSUS CAUSAL SUCCESSION — "after" is never "because"
% ---------------------------------------------------------------------------

% Define causal_core_precedes_add: record that A merely happened before B.
causal_core_precedes_add(A, B) :-
    % Record the succession once.
    (   causal_core_precedes_(A, B)
    % Already recorded.
    ->  true
    % New record.
    ;   assertz(causal_core_precedes_(A, B))
    ).

% Define causal_core_precedes: query mere temporal succession.
causal_core_precedes(A, B) :-
    % Enumerate or test the store.
    causal_core_precedes_(A, B).

% Define causal_core_causally_linked: production holds only through a reified relation.
causal_core_causally_linked(Cause, Effect) :-
    % Some relation carries the pair; succession alone never suffices.
    causal_core_causal_relation_object_(_, Causes, Effects, _, Modality, _, _, _),
    % Preventive relations are not production.
    Modality \== preventive,
    % The cause participates.
    memberchk(Cause, Causes),
    % The effect participates.
    memberchk(Effect, Effects).

% Define causal_core_after_but_not_because: the discipline made queryable.
causal_core_after_but_not_because(A, B) :-
    % A did come before B.
    causal_core_precedes_(A, B),
    % But no relation produces B from A.
    \+ causal_core_causally_linked(A, B).

% ---------------------------------------------------------------------------
% TIMING AS MECHANISM — the temporal admissibility gate
% ---------------------------------------------------------------------------

% Define causal_core_temporal_admissible: elapsed time must fall inside the window.
causal_core_temporal_admissible(Cause, Effect, elapsed(T, Unit)) :-
    % A relation for this cause and effect with a window in this unit.
    causal_core_causal_relation_object_(_, Causes, Effects, temporal(Dmin, Dmax, Unit), _, _, _, _),
    % The cause participates.
    memberchk(Cause, Causes),
    % The effect participates.
    memberchk(Effect, Effects),
    % The elapsed time is at or past the minimum delay.
    T >= Dmin,
    % And within the maximum delay.
    ( Dmax == unspecified -> true ; T =< Dmax ).

% Define causal_core_temporal_abduction: candidates gated by their windows, ranked.
% Candidates are Cause-elapsed(T, Unit) pairs; Ranked is Strength-Cause pairs.
causal_core_temporal_abduction(Effect, Candidates, Ranked) :-
    % Keep each candidate whose elapsed time its own window admits.
    findall(S-Cause,
        % Take each candidate in turn.
        ( member(Cause-elapsed(T, Unit), Candidates),
          % Fetch the relation and its window.
          causal_core_causal_relation_object_(_, Causes, Effects, temporal(Dmin, Dmax, Unit), _, S, _, _),
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

% Define causal_core_decompose_add: attach the finer relations a mechanism comprises.
causal_core_decompose_add(ParentId, SubIds) :-
    % The parent must exist.
    causal_core_causal_relation_object_(ParentId, _, _, _, _, _, _, _),
    % Every sub-relation must exist.
    forall(member(S, SubIds), causal_core_causal_relation_object_(S, _, _, _, _, _, _, _)),
    % Replace any previous decomposition.
    retractall(causal_core_mechanism_(ParentId, _)),
    % Record the mechanism sub-graph.
    assertz(causal_core_mechanism_(ParentId, SubIds)).

% Define causal_core_mechanism: read a relation's mechanism sub-graph.
causal_core_mechanism(ParentId, SubIds) :-
    % Enumerate or test the store.
    causal_core_mechanism_(ParentId, SubIds).

% Define causal_core_hierarchy_consistent: the coarse relation must agree with the
% composition of its parts — the sub-relations must chain from the parent's
% causes to the parent's effects (Section 6.2).
causal_core_hierarchy_consistent(ParentId) :-
    % Fetch the parent's endpoints.
    causal_core_causal_relation_object_(ParentId, Causes, Effects, _, _, _, _, _),
    % Fetch the mechanism.
    causal_core_mechanism_(ParentId, SubIds),
    % Chain the sub-relations from the causes to every effect.
    forall(member(E, Effects), causal_core_chain_reaches(Causes, E, SubIds)).

% causal_core_chain_reaches(+Frontier, +Target, +SubIds): the composition check.
causal_core_chain_reaches(Frontier, Target, _) :-
    % The target is already produced.
    memberchk(Target, Frontier),
    % Done.
    !.
% Otherwise some unused sub-relation must fire from the frontier.
causal_core_chain_reaches(Frontier, Target, SubIds) :-
    % Pick a sub-relation not yet used.
    select(Sub, SubIds, Rest),
    % Fetch its endpoints.
    causal_core_causal_relation_object_(Sub, SubCauses, SubEffects, _, _, _, _, _),
    % Every one of its causes must already be on the frontier.
    forall(member(C, SubCauses), memberchk(C, Frontier)),
    % Its effects join the frontier.
    append(Frontier, SubEffects, Frontier2),
    % Continue toward the target.
    causal_core_chain_reaches(Frontier2, Target, Rest).

% ---------------------------------------------------------------------------
% THE SUBSUMPTION ARGUMENT — import external verbs as degenerate causal_relation_objects
% ---------------------------------------------------------------------------

% Define causal_core_import_external: an external causal assertion becomes a causal_relation_object in
% which the missing fields are unspecified — a degenerate special case.
causal_core_import_external(Source, Cause, Effect, Id) :-
    % Allocate a fresh identifier.
    gensym(causal_relation_object_, Id),
    % The import is provisional, read-only in spirit, owned once refined.
    causal_core_causal_relation_object_assert(causal_relation_object(Id, [Cause], [Effect],
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

% Define causal_core_provisional: the imports not yet refined into owned relations.
causal_core_provisional(Id) :-
    % A provisional flag in the context marks them.
    causal_core_causal_relation_object_(Id, _, _, _, _, _, Context, _),
    % Test the flag.
    memberchk(provisional, Context).

% Define causal_core_refine_import: fill in the omitted payload; the relation is
% then owned, and strictly more expressive than the import it replaced.
causal_core_refine_import(Id, Temporal, Modality, Strength) :-
    % Fetch the provisional relation.
    causal_core_causal_relation_object_(Id, Causes, Effects, _, _, _, Context, prov(Source, _, _)),
    % Only provisional imports are refined this way.
    memberchk(provisional, Context),
    % Drop the provisional flag.
    subtract(Context, [provisional], Context2),
    % Re-assert through the validating front door with the full payload.
    causal_core_causal_relation_object_assert(causal_relation_object(Id, Causes, Effects, Temporal, Modality, Strength,
                      Context2, prov(Source, refined_after_import, Strength))).

% ---------------------------------------------------------------------------
% GLASS-BOX JUSTIFICATION
% ---------------------------------------------------------------------------

% Define causal_core_why: the full inspectable story of a relation.
causal_core_why(Id, why(Id, causes(Causes), effects(Effects), window(Temporal),
               modality(Modality), strength(Strength), context(Context),
               provenance(Prov), mechanism(SubIds))) :-
    % Fetch the relation.
    causal_core_causal_relation_object_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov),
    % Fetch its mechanism, empty when it has none.
    ( causal_core_mechanism_(Id, SubIds) -> true ; SubIds = [] ).

% ===========================================================================
% CAUSALONTOLOGY 2.0.0 CONFORMANCE VOCABULARY (WP-425)
%
% This section makes causal_core speak the Causalontology 2.0.0 standard as
% published data structures: RFC 8785 canonicalization, SHA-256 content
% identity for all eighteen kinds, the locally-checkable semantic rules, and
% the five normative algorithms of Section 12 (bridge closure, bridged
% reachability, stratal classification, the skip decision, unit
% normalization). Objects are SWI dicts with atom keys; string values are
% Prolog strings; booleans are the atoms true/false; null is the atom null.
% Every predicate here is additive and side-effect free (no dynamic state),
% so nothing in the existing verb layer or the ARC solving core is touched.
% ===========================================================================

% Bring in the SHA-256 primitive used by content identity.
:- use_module(library(sha)).

% Export the whole conformance vocabulary surface.
:- export(causal_core_identity_fields/2).
:- export(causal_core_jcs/2).
:- export(causal_core_canonicalize/3).
:- export(causal_core_identify/3).
:- export(causal_core_infer_kind/2).
:- export(causal_core_unit_seconds/2).
:- export(causal_core_to_seconds/3).
:- export(causal_core_validate_semantics/3).
:- export(causal_core_is_partial/3).
:- export(causal_core_admissible/3).
:- export(causal_core_conflicts/2).
:- export(causal_core_refinement_valid/3).
:- export(causal_core_bridge_closure/3).
:- export(causal_core_hierarchy_consistent/4).
:- export(causal_core_classify/4).
:- export(causal_core_endpoints_mixed/2).
:- export(causal_core_skip_gaps/3).
:- export(causal_core_delay_within_window/3).
:- export(causal_core_bridge_wellformed/4).
:- export(causal_core_seam_wellformed/4).
:- export(causal_core_seam_home/4).
:- export(causal_core_dimension/2).
:- export(causal_core_conduit_wellformed/4).
:- export(causal_core_state_gaps/3).
:- export(causal_core_covering_law_mismatch/3).
:- export(causal_core_retrocausal/2).
:- export(causal_core_has_cycle/1).
:- export(causal_core_enrichment_field/3).
:- export(causal_core_atomize/2).

% -- The identity-bearing fields of each of the eighteen kinds (identity.md).
% The "type" field is always injected, so it is not listed in these tables.
% occurrent identity: its label, category, and stratum.
causal_core_identity_fields(occurrent, [label, category, stratum]).
% causal_relation_object identity: the full causal payload.
causal_core_identity_fields(causal_relation_object,
    [causes, effects, mechanism, temporal, modality, context, refines, skips]).
% continuant identity: label and category.
causal_core_identity_fields(continuant, [label, category]).
% realizable identity: its kind, bearer, and optional label.
causal_core_identity_fields(realizable, [kind, bearer, label]).
% stratum identity: label, scheme, ordinal, unit, governs.
causal_core_identity_fields(stratum, [label, scheme, ordinal, unit, governs]).
% bridge identity: the coarse occurrent, its fine set, and the relation.
causal_core_identity_fields(bridge, [coarse, fine, relation]).
% cross_stratal_seam identity (3.0.0, the eighteenth kind): source, target endpoints, mechanism_status, optional chain.
causal_core_identity_fields(cross_stratal_seam, [source, target, mechanism_status, chain]).
% port identity: bearer, label, direction, accepted occurrents, realizable.
causal_core_identity_fields(port, [bearer, label, direction, accepts, realizable]).
% conduit identity: label, from, to, carried occurrents, transform, and (3.0.0) the optional realized_by native-law reference.
causal_core_identity_fields(conduit, [label, from, to, carries, transform, realized_by]).
% quality identity: label, datatype, unit, stratum.
causal_core_identity_fields(quality, [label, datatype, unit, stratum]).
% token_individual identity: what it instantiates, its designator, its whole.
causal_core_identity_fields(token_individual, [instantiates, designator, part_of]).
% token_occurrence identity: instantiates, interval, participants, locus, observer.
causal_core_identity_fields(token_occurrence,
    [instantiates, interval, participants, locus, observer]).
% state_assertion identity: subject, quality, value, interval.
causal_core_identity_fields(state_assertion, [subject, quality, value, interval]).
% token_causal_claim identity: causes, effects, covering law, delay, counterfactual.
causal_core_identity_fields(token_causal_claim,
    [causes, effects, covering_law, actual_delay, counterfactual]).
% assertion identity: about, source, evidence type/body, strength, confidence, timestamp, evidenced_by.
causal_core_identity_fields(assertion,
    [about, source, evidence_type, evidence, strength, confidence, timestamp, evidenced_by]).
% enrichment identity: about, field, entry, source, timestamp.
causal_core_identity_fields(enrichment, [about, field, entry, source, timestamp]).
% retraction identity: what it retracts, source, timestamp.
causal_core_identity_fields(retraction, [retracts, source, timestamp]).
% succession identity: predecessor, successor, timestamp.
causal_core_identity_fields(succession, [predecessor, successor, timestamp]).

% -- causal_core_infer_kind(+Obj, -Kind): the kind of a dict (type, id, or shape).
% An explicit type field wins.
causal_core_infer_kind(Obj, Kind) :-
    get_dict(type, Obj, TypeVal), !,
    ( atom(TypeVal) -> Kind = TypeVal ; atom_string(Kind, TypeVal) ).
% Otherwise a known id-scheme prefix names the kind.
causal_core_infer_kind(Obj, Kind) :-
    get_dict(id, Obj, Id), causal_core_kind_of_id_str(Id, K), K \== unknown, !, Kind = K.
% coarse+fine is a bridge.
causal_core_infer_kind(Obj, bridge) :- get_dict(coarse, Obj, _), get_dict(fine, Obj, _), !.
% causes+effects is a causal_relation_object.
causal_core_infer_kind(Obj, causal_relation_object) :- get_dict(causes, Obj, _), get_dict(effects, Obj, _), !.
% retracts is a retraction.
causal_core_infer_kind(Obj, retraction) :- get_dict(retracts, Obj, _), !.
% predecessor+successor is a succession.
causal_core_infer_kind(Obj, succession) :- get_dict(predecessor, Obj, _), get_dict(successor, Obj, _), !.
% field+entry is an enrichment.
causal_core_infer_kind(Obj, enrichment) :- get_dict(field, Obj, _), get_dict(entry, Obj, _), !.
% evidence_type, or about+confidence, is an assertion.
causal_core_infer_kind(Obj, assertion) :- ( get_dict(evidence_type, Obj, _) ; ( get_dict(about, Obj, _), get_dict(confidence, Obj, _) ) ), !.
% kind+bearer is a realizable.
causal_core_infer_kind(Obj, realizable) :- get_dict(kind, Obj, _), get_dict(bearer, Obj, _), !.

% -- causal_core_kind_of_id_str(+Id, -Kind): kind named by an id string prefix.
causal_core_kind_of_id_str(Id, Kind) :-
    ( sub_string(Id, B, _, _, ":") -> sub_string(Id, 0, B, _, SchemeS) ; SchemeS = Id ),
    ( atom_string(SchemeA, SchemeS), causal_core_identity_fields(SchemeA, _) -> Kind = SchemeA ; Kind = unknown ).

% -- causal_core_identity_bearing(+Kind, +Obj, -Bearing): the identity subset.
causal_core_identity_bearing(Kind, Obj, Bearing) :-
    % Look up the identity-bearing field list for this kind.
    causal_core_identity_fields(Kind, Fields),
    % Inject the type as a string, matching the reference serializer.
    atom_string(Kind, KindStr),
    % Keep only the present identity fields, building key-value pairs.
    findall(F-V, (member(F, Fields), get_dict(F, Obj, V)), Pairs0),
    % Prepend the injected type field.
    Pairs = [type-KindStr|Pairs0],
    % Build a dict from the retained pairs (tag is irrelevant to canonical form).
    dict_pairs(Bearing, _, Pairs).

% -- causal_core_jcs(+Value, -String): RFC 8785 canonical serialization.
% The atom null serializes to the JSON null literal.
causal_core_jcs(null, "null") :- !.
% The atom true serializes to the JSON true literal.
causal_core_jcs(true, "true") :- !.
% The atom false serializes to the JSON false literal.
causal_core_jcs(false, "false") :- !.
% Integers serialize as their base-ten form.
causal_core_jcs(V, S) :- integer(V), !, number_string(V, S).
% Floats serialize by the RFC 8785 number rules for our value ranges.
causal_core_jcs(V, S) :- float(V), !, causal_core_jcs_float(V, S).
% Strings serialize as escaped, quoted JSON strings.
causal_core_jcs(V, S) :- string(V), !, causal_core_jcs_string(V, S).
% Dicts serialize with keys sorted by code point (JCS object rule).
causal_core_jcs(V, S) :- is_dict(V), !, causal_core_jcs_object(V, S).
% Lists serialize as JSON arrays, element order preserved.
causal_core_jcs(V, S) :- is_list(V), !, causal_core_jcs_array(V, S).
% Any remaining atom (a non-boolean enum) serializes as a JSON string.
causal_core_jcs(V, S) :- atom(V), !, atom_string(V, Str), causal_core_jcs_string(Str, S).

% -- causal_core_jcs_float(+Float, -String): the number rule for our ranges.
causal_core_jcs_float(V, S) :-
    % Zero prints as a bare 0.
    ( V =:= 0 -> S = "0"
    % An integer-valued float below 1e21 prints as that integer.
    ; ( V =:= truncate(V), abs(V) < 1.0e21 )
        -> I is truncate(V), number_string(I, S)
    % Otherwise SWI's shortest round-trip decimal is used (ES6-compatible here).
    ; format(string(S), "~w", [V])
    ).

% -- causal_core_jcs_string(+String, -Quoted): escape and quote a JSON string.
causal_core_jcs_string(Str, Quoted) :-
    % Take the string as a list of character codes.
    string_codes(Str, Codes),
    % Escape each code per the JCS/RFC 8785 rules (source order preserved).
    foldl(causal_core_jcs_escape, Codes, Esc, []),
    % Flatten the per-character code fragments into one list.
    flatten(Esc, EscCodes),
    % Wrap the escaped body in double quotes.
    string_codes(Body, EscCodes),
    % Concatenate the opening quote, body, and closing quote.
    causal_core_atomics_string(["\"", Body, "\""], Quoted).

% -- causal_core_jcs_escape(+Code, -Acc, +Acc0): one character's escape codes.
causal_core_jcs_escape(0'", [[0'\\, 0'"]|A], A) :- !.
% Backslash escapes to \\.
causal_core_jcs_escape(0'\\, [[0'\\, 0'\\]|A], A) :- !.
% Backspace escapes to \b.
causal_core_jcs_escape(8, [[0'\\, 0'b]|A], A) :- !.
% Tab escapes to \t.
causal_core_jcs_escape(9, [[0'\\, 0't]|A], A) :- !.
% Line feed escapes to \n.
causal_core_jcs_escape(10, [[0'\\, 0'n]|A], A) :- !.
% Form feed escapes to \f.
causal_core_jcs_escape(12, [[0'\\, 0'f]|A], A) :- !.
% Carriage return escapes to \r.
causal_core_jcs_escape(13, [[0'\\, 0'r]|A], A) :- !.
% Any other control character below 0x20 escapes to a \u00xx sequence.
causal_core_jcs_escape(C, [U|A], A) :- C < 0x20, !,
    format(codes(U), "\\u~|~`0t~16r~4+", [C]).
% All other characters pass through unchanged.
causal_core_jcs_escape(C, [[C]|A], A).

% -- causal_core_jcs_array(+List, -String): serialize a JSON array.
causal_core_jcs_array(List, S) :-
    % Serialize each element.
    maplist(causal_core_jcs, List, Parts),
    % Join the parts with commas.
    causal_core_atomics_string(Parts, ",", Inner),
    % Wrap in square brackets.
    causal_core_atomics_string(["[", Inner, "]"], S).

% -- causal_core_jcs_object(+Dict, -String): serialize a JSON object.
causal_core_jcs_object(Dict, S) :-
    % Take the dict's key-value pairs.
    dict_pairs(Dict, _, Pairs),
    % Sort the pairs by key using standard order (code-point order for ASCII keys).
    sort(1, @=<, Pairs, Sorted),
    % Serialize each pair as "key":value.
    maplist(causal_core_jcs_member, Sorted, Parts),
    % Join the members with commas.
    causal_core_atomics_string(Parts, ",", Inner),
    % Wrap in braces.
    causal_core_atomics_string(["{", Inner, "}"], S).

% -- causal_core_jcs_member(+Key-Value, -String): one serialized object member.
causal_core_jcs_member(K-V, S) :-
    % Serialize the key as a JSON string.
    atom_string(K, KStr), causal_core_jcs_string(KStr, KS),
    % Serialize the value.
    causal_core_jcs(V, VS),
    % Join key and value with a colon.
    causal_core_atomics_string([KS, ":", VS], S).

% -- causal_core_atomics_string helpers (concatenate / join a list of atomics).
causal_core_atomics_string(List, S) :- causal_core_atomic_concat(List, "", S).
% Join with a separator.
causal_core_atomics_string(List, Sep, S) :- causal_core_atomic_concat(List, Sep, S).
% Concatenate a list of strings/atoms/numbers into one string with a separator.
causal_core_atomic_concat(List, Sep, S) :-
    % Reuse the library join over atoms, then cast to a string.
    atomic_list_concat(List, Sep, A), atom_string(A, S).

% -- causal_core_canonicalize(+Obj, +Kind, -Bytes): the identity-bearing bytes.
causal_core_canonicalize(Obj, Kind0, Bytes) :-
    % Resolve the kind, inferring it from the type field when unbound.
    ( var(Kind0) -> causal_core_infer_kind(Obj, Kind) ; Kind = Kind0 ),
    % Reduce the object to its identity-bearing subset.
    causal_core_identity_bearing(Kind, Obj, Bearing),
    % Serialize that subset with the RFC 8785 rules.
    causal_core_jcs(Bearing, Bytes).

% -- causal_core_identify(+Obj, +Kind, -Id): scheme + ':' + SHA-256 hex digest.
causal_core_identify(Obj, Kind0, Id) :-
    % Resolve the kind as above.
    ( var(Kind0) -> causal_core_infer_kind(Obj, Kind) ; Kind = Kind0 ),
    % Compute the canonical bytes.
    causal_core_canonicalize(Obj, Kind, Bytes),
    % Hash them with SHA-256 over their UTF-8 encoding.
    sha_hash(Bytes, Digest, [algorithm(sha256), encoding(utf8)]),
    % Render the digest as lowercase hexadecimal.
    hash_atom(Digest, HexAtom),
    % The scheme is the whole-word kind name (Principle P7).
    atom_string(Kind, KindStr),
    % Assemble scheme + ':' + digest as the content-addressed identifier.
    causal_core_atomics_string([KindStr, ":", HexAtom], Id).

% ---------------------------------------------------------------------------
% Unit normalization (Algorithm E) and temporal admissibility (Rule 4)
% ---------------------------------------------------------------------------

% -- causal_core_unit_seconds(+Unit, -Seconds): the fixed conversion table.
% An instant is zero seconds.
causal_core_unit_seconds(instant, 0).
% One second.
causal_core_unit_seconds(seconds, 1).
% One minute is sixty seconds.
causal_core_unit_seconds(minutes, 60).
% One hour.
causal_core_unit_seconds(hours, 3600).
% One day.
causal_core_unit_seconds(days, 86400).
% One week.
causal_core_unit_seconds(weeks, 604800).
% One mean Gregorian month (normative constant).
causal_core_unit_seconds(months, 2629746).
% One mean Gregorian year (normative constant, 365.2425 days).
causal_core_unit_seconds(years, 31556952).

% -- causal_core_unit_seconds accepts a unit given as a string too.
causal_core_unit_atom(U, A) :- ( atom(U) -> A = U ; atom_string(A, U) ).

% -- causal_core_dimension(+Unit, -Dim): 3.0.0. 'ordinal' for the tick unit, else 'wallclock'.
causal_core_dimension(U, Dim) :- causal_core_unit_atom(U, A), ( A == ticks -> Dim = ordinal ; Dim = wallclock ).

% -- causal_core_to_seconds(+Duration, +Unit, -Seconds): normalize a delay.
% 3.0.0: an ordinal (tick) unit is dimensionless and has NO wall-clock mapping - converting it is a refused category error.
causal_core_to_seconds(_, Unit, _) :- causal_core_unit_atom(Unit, ticks), !,
    throw(error(type_error(wall_clock_unit, ticks),
                context(causal_core_to_seconds/3, 'ticks is an ordinal (dimensionless) unit with no wall-clock seconds mapping'))).
causal_core_to_seconds(_, Unit, 0) :- causal_core_unit_atom(Unit, instant), !.
% Any other unit multiplies the duration by its second-count.
causal_core_to_seconds(Duration, Unit, Seconds) :-
    causal_core_unit_atom(Unit, A), causal_core_unit_seconds(A, Per),
    Seconds is Duration * Per.

% -- causal_core_admissible(+Cro, +ElapsedSeconds, -Bool): Rule 4.
causal_core_admissible(Cro, _, true) :- \+ get_dict(temporal, Cro, _), !.
% 3.0.0: an ordinal (tick) window is ordered by INTEGER comparison of tick counts (Elapsed is a tick count, no seconds mapping).
causal_core_admissible(Cro, Elapsed, Bool) :-
    get_dict(temporal, Cro, T), get_dict(unit, T, U), causal_core_unit_atom(U, ticks), !,
    get_dict(minimum_delay, T, Lo), get_dict(maximum_delay, T, Hi),
    ( ( Lo =< Elapsed, Elapsed =< Hi ) -> Bool = true ; Bool = false ).
% With a wall-clock window, the elapsed time must fall inside the normalized bounds.
causal_core_admissible(Cro, Elapsed, Bool) :-
    get_dict(temporal, Cro, T),
    get_dict(unit, T, U), causal_core_unit_atom(U, Unit),
    causal_core_unit_seconds(Unit, Per),
    get_dict(minimum_delay, T, Lo0), get_dict(maximum_delay, T, Hi0),
    Lo is Lo0 * Per, Hi is Hi0 * Per,
    ( ( Lo =< Elapsed, Elapsed =< Hi ) -> Bool = true ; Bool = false ).

% ---------------------------------------------------------------------------
% Local semantic rules (validate_semantics)
% ---------------------------------------------------------------------------

% -- causal_core_validate_semantics(+Obj, +Kind, -Reasons): [] iff valid.
causal_core_validate_semantics(Obj, Kind0, Reasons) :-
    ( var(Kind0) -> causal_core_infer_kind(Obj, Kind) ; Kind = Kind0 ),
    findall(R, causal_core_semantic_error(Kind, Obj, R), Reasons).

% -- Rule 4: a causal_relation_object's minimum delay may not exceed its maximum.
causal_core_semantic_error(causal_relation_object, Obj, "minimum_delay must be <= maximum_delay") :-
    get_dict(temporal, Obj, T),
    get_dict(minimum_delay, T, Lo), get_dict(maximum_delay, T, Hi),
    number(Lo), number(Hi), Lo > Hi.
% Acyclicity: a causal_relation_object may not list its own id in its mechanism.
causal_core_semantic_error(causal_relation_object, Obj,
        "mechanism must be acyclic (a Causal Relation Object may not contain itself)") :-
    get_dict(id, Obj, Id), get_dict(mechanism, Obj, M), memberchk(Id, M).
% Acyclicity: a causal_relation_object may not refine itself.
causal_core_semantic_error(causal_relation_object, Obj, "refines must be acyclic") :-
    get_dict(id, Obj, Id), get_dict(refines, Obj, Id).
% Rule 16 clause 1: skips:true with a non-empty mechanism is a hard contradiction.
causal_core_semantic_error(causal_relation_object, Obj,
        "contradictory_skip: skips is true but a mechanism is present") :-
    get_dict(skips, Obj, true), get_dict(mechanism, Obj, M), M \== [].
% 3.0.0 Rule 22 local clause: a Cross Stratal Seam that DRAWS a chain cannot declare its mechanism 'absent'.
causal_core_semantic_error(cross_stratal_seam, Obj,
        "contradictory_seam: a drawn chain cannot carry mechanism_status 'absent' (a drawn mechanism is not absent)") :-
    get_dict(chain, Obj, _), get_dict(mechanism_status, Obj, MS), causal_core_atomize(MS, absent).
% Rule 12: an enrichment field must be legal for the kind it is about.
causal_core_semantic_error(enrichment, Obj, Msg) :-
    get_dict(field, Obj, FieldV), causal_core_atomize(FieldV, Field),
    causal_core_enrichment_field(Field, LegalKinds, _Shape),
    get_dict(about, Obj, AboutV), causal_core_atomize(AboutV, About),
    causal_core_kind_of_id(About, AboutKind), AboutKind \== unknown,
    \+ memberchk(AboutKind, LegalKinds),
    format(string(Msg), "~w is not a legal field for a ~w (rule 12)", [Field, AboutKind]).
% Rule 12: an aliases entry must be a language-tagged text object.
causal_core_semantic_error(enrichment, Obj, "an aliases entry must be a language-tagged text object") :-
    get_dict(field, Obj, FieldV), causal_core_atomize(FieldV, aliases),
    get_dict(entry, Obj, Entry),
    \+ ( is_dict(Entry), get_dict(lang, Entry, _), get_dict(text, Entry, _) ).
% Rule 12: a reference-shaped enrichment entry must be an identifier of the right scheme.
causal_core_semantic_error(enrichment, Obj, Msg) :-
    get_dict(field, Obj, FieldV), causal_core_atomize(FieldV, Field),
    causal_core_enrichment_field(Field, _, Shape), Shape \== alias,
    get_dict(entry, Obj, Entry),
    \+ ( string(Entry), atom_string(Shape, ShapeS), string_concat(ShapeS, ":", Pfx), string_concat(Pfx, _, Entry) ),
    format(string(Msg), "a ~w entry must be a ~w: identifier", [Field, Shape]).

% -- The enrichment field-to-kind table (Rule 12), with entry shapes.
causal_core_enrichment_field(aliases, [occurrent, continuant], alias).
% participants attach continuants to an occurrent.
causal_core_enrichment_field(participants, [occurrent], continuant).
% subsumes relates continuants.
causal_core_enrichment_field(subsumes, [continuant], continuant).
% part_of relates continuants.
causal_core_enrichment_field(part_of, [continuant], continuant).
% realized_in attaches an occurrent to a realizable.
causal_core_enrichment_field(realized_in, [realizable], occurrent).
% occurrent_subsumes relates occurrents (new in 2.0.0).
causal_core_enrichment_field(occurrent_subsumes, [occurrent], occurrent).
% occurrent_part_of relates occurrents (new in 2.0.0).
causal_core_enrichment_field(occurrent_part_of, [occurrent], occurrent).

% -- causal_core_kind_of_id(+Id, -Kind): the kind named by an identifier's scheme.
causal_core_kind_of_id(Id, Kind) :-
    % Split the identifier at the first colon to recover the scheme.
    ( sub_atom(Id, Before, _, After, ":")
        -> sub_atom(Id, 0, Before, _, SchemeA), _ = After
        ;  SchemeA = Id ),
    % A scheme that names a known kind yields that kind; otherwise unknown.
    ( causal_core_identity_fields(SchemeA, _) -> Kind = SchemeA ; Kind = unknown ).

% -- causal_core_atomize(+V, -Atom): normalize a string or atom to an atom.
causal_core_atomize(V, A) :- ( atom(V) -> A = V ; atom_string(A, V) ).

% -- causal_core_is_partial(+Cro, -Partial, -Missing): unspecified optional fields.
causal_core_is_partial(Cro, Partial, Missing) :-
    findall(F, (member(F, [mechanism, temporal, modality, context]), \+ get_dict(F, Cro, _)), Missing),
    ( Missing == [] -> Partial = false ; Partial = true ).

% ---------------------------------------------------------------------------
% Rule 6: the formal conflict test
% ---------------------------------------------------------------------------

% -- causal_core_conflicts(+A, +B, -Bool) via the four gates plus modality opposition.
causal_core_conflicts(A, B) :-
    % Same cause set (as sets).
    get_dict(causes, A, CA), get_dict(causes, B, CB), causal_core_same_set(CA, CB),
    % Same effect set.
    get_dict(effects, A, EA), get_dict(effects, B, EB), causal_core_same_set(EA, EB),
    % Compatible contexts.
    causal_core_contexts_compatible(A, B),
    % Overlapping temporal windows.
    causal_core_window_overlap(A, B),
    % One preventive against one of the positive modalities.
    causal_core_modality(A, MA), causal_core_modality(B, MB),
    ( ( MA == preventive, causal_core_positive(MB) )
    ; ( MB == preventive, causal_core_positive(MA) ) ).

% -- causal_core_modality(+Cro, -Atom): the modality as an atom, or none.
causal_core_modality(Cro, M) :- ( get_dict(modality, Cro, V) -> causal_core_atomize(V, M) ; M = none ).

% -- The four mutually-compatible positive modalities (Rule 6, amended).
causal_core_positive(necessary).
causal_core_positive(sufficient).
causal_core_positive(contributory).
causal_core_positive(enabling).

% -- causal_core_same_set(+A, +B): equal as sets.
causal_core_same_set(A, B) :- sort(A, S), sort(B, S).

% -- causal_core_contexts_compatible(+A, +B): equal, subset, or either empty.
causal_core_contexts_compatible(A, _B) :-
    ( \+ get_dict(context, A, _) ; get_dict(context, A, []) ), !.
causal_core_contexts_compatible(_A, B) :-
    ( \+ get_dict(context, B, _) ; get_dict(context, B, []) ), !.
causal_core_contexts_compatible(A, B) :-
    get_dict(context, A, CA), get_dict(context, B, CB),
    sort(CA, SA), sort(CB, SB),
    ( SA == SB ; ord_subset(SA, SB) ; ord_subset(SB, SA) ).

% -- causal_core_window_overlap(+A, +B): overlap, or either window absent.
causal_core_window_overlap(A, _B) :- \+ get_dict(temporal, A, _), !.
causal_core_window_overlap(_A, B) :- \+ get_dict(temporal, B, _), !.
causal_core_window_overlap(A, B) :-
    causal_core_window_bounds(A, DimA, LoA, HiA), causal_core_window_bounds(B, DimB, LoB, HiB),
    DimA == DimB,                       % 3.0.0: ordinal and wall-clock windows are disjoint dimensions, never overlapping
    LoA =< HiB, LoB =< HiA.

% -- causal_core_window_bounds(+Cro, -Dim, -Lo, -Hi): the window's dimension and comparable bounds
% (a tick count in the ordinal dimension, or seconds in the wall-clock dimension).
causal_core_window_bounds(Cro, Dim, Lo, Hi) :-
    get_dict(temporal, Cro, T), get_dict(unit, T, U), causal_core_dimension(U, Dim),
    get_dict(minimum_delay, T, L), get_dict(maximum_delay, T, H),
    ( Dim == ordinal
      -> Lo = L, Hi = H
      ;  causal_core_unit_atom(U, Unit), causal_core_unit_seconds(Unit, Per), Lo is L * Per, Hi is H * Per ).

% ---------------------------------------------------------------------------
% Rule 3: refinement validity
% ---------------------------------------------------------------------------

% -- causal_core_refinement_valid(+Child, +Parent, -Result): ok(_) or invalid(Reason).
causal_core_refinement_valid(Child, Parent, Result) :-
    ( \+ ( get_dict(refines, Child, R), get_dict(id, Parent, R) )
        -> Result = invalid("child does not name the parent in refines")
    ; ( get_dict(causes, Child, CC), get_dict(causes, Parent, PC), \+ causal_core_same_set(CC, PC)
      ; get_dict(effects, Child, EC), get_dict(effects, Parent, PE), \+ causal_core_same_set(EC, PE) )
        -> Result = invalid("a refinement must keep the parent's causes and effects")
    ; causal_core_refine_conflict(Child, Parent)
        -> Result = invalid("a refinement may not change a field the parent specified; this is a rival claim")
    ; causal_core_refine_added(Child, Parent, 0)
        -> Result = invalid("a refinement must add at least one unspecified field")
    ; Result = ok("valid refinement")
    ).

% -- causal_core_refine_conflict: the child changes a field the parent specified.
causal_core_refine_conflict(Child, Parent) :-
    member(F, [mechanism, temporal, modality, context]),
    get_dict(F, Parent, PV), ( \+ get_dict(F, Child, PV) ).

% -- causal_core_refine_added: count fields the child adds that the parent lacked.
causal_core_refine_added(Child, Parent, N) :-
    findall(F, ( member(F, [mechanism, temporal, modality, context]),
                 \+ get_dict(F, Parent, _), get_dict(F, Child, _) ), Added),
    length(Added, N).

% ===========================================================================
% 2.0.0 NORMATIVE ALGORITHMS (Section 12)
% ===========================================================================

% -- ALGORITHM A. causal_core_bridge_closure(+OccId, +Bridges, -Set).
causal_core_bridge_closure(OccId, Bridges, Set) :-
    % Seed the frontier and result with the starting occurrent.
    causal_core_bc_loop([OccId], Bridges, [OccId], Set0),
    % Return the sorted closure set.
    sort(Set0, Set).

% -- The worklist loop for bridge closure, guarded against cycles by Result.
causal_core_bc_loop([], _, Acc, Acc).
% Pop the current node and expand it via every bridge whose coarse it is.
causal_core_bc_loop([Cur|Rest], Bridges, Acc, Out) :-
    findall(F, ( member(B, Bridges), get_dict(coarse, B, Cur),
                 get_dict(fine, B, Fine), member(F, Fine) ), Fines),
    % Keep only fines not already seen, to terminate on malformed cyclic data.
    findall(F, (member(F, Fines), \+ memberchk(F, Acc)), New),
    append(Acc, New, Acc1), append(New, Rest, Frontier),
    causal_core_bc_loop(Frontier, Bridges, Acc1, Out).

% -- ALGORITHM B (amended Rule 7). causal_core_hierarchy_consistent(+Parent, +Members, +Bridges, -Verdict).
causal_core_hierarchy_consistent(Parent, _Members, _Bridges, consistent) :-
    % Nothing claimed (no mechanism) is trivially consistent.
    ( \+ get_dict(mechanism, Parent, _) ; get_dict(mechanism, Parent, []) ), !.
causal_core_hierarchy_consistent(Parent, Members, Bridges, Verdict) :-
    get_dict(mechanism, Parent, Mech),
    ( causal_core_any_dangling(Mech, Members)
        % A dangling mechanism entry is ignorance, not refutation.
        -> Verdict = indeterminate
        ;  causal_core_hierarchy_check(Parent, Mech, Members, Bridges, Verdict)
    ).

% -- True if any mechanism id is missing from the members map.
causal_core_any_dangling(Mech, Members) :-
    member(Mid, Mech), \+ causal_core_map_get(Mid, Members, _), !.

% -- Build the edge relation and test every parent cause/effect pair for a bridged path.
causal_core_hierarchy_check(Parent, Mech, Members, Bridges, Verdict) :-
    findall(C-E, ( member(Mid, Mech), causal_core_map_get(Mid, Members, M),
                   get_dict(causes, M, MCs), member(C, MCs),
                   get_dict(effects, M, MEs), member(E, MEs) ), EdgePairs),
    get_dict(causes, Parent, PCauses), get_dict(effects, Parent, PEffects),
    ( ( member(PC, PCauses), member(PE, PEffects),
        \+ causal_core_bridged_connected(PC, PE, EdgePairs, Bridges) )
        -> Verdict = inconsistent
        ;  Verdict = consistent
    ).

% -- A parent cause reaches a parent effect if any of their bridge-closures are path-connected.
causal_core_bridged_connected(PC, PE, EdgePairs, Bridges) :-
    causal_core_bridge_closure(PC, Bridges, CSet),
    causal_core_bridge_closure(PE, Bridges, ESet),
    member(Cp, CSet), member(Ep, ESet),
    causal_core_path_exists(EdgePairs, Cp, Ep), !.

% -- causal_core_path_exists(+EdgePairs, +Src, +Dst): reachability over Cause-Effect edges.
causal_core_path_exists(Edges, Src, Dst) :- causal_core_reach([Src], Edges, [], Dst).
% The destination is reached when it is the current node.
causal_core_reach([Dst|_], _, _, Dst) :- !.
causal_core_reach([N|Rest], Edges, Seen, Dst) :-
    ( memberchk(N, Seen)
        -> causal_core_reach(Rest, Edges, Seen, Dst)
        ;  findall(E, member(N-E, Edges), Succs),
           append(Succs, Rest, Frontier),
           causal_core_reach(Frontier, Edges, [N|Seen], Dst)
    ).

% -- causal_core_map_get(+Key, +Map, -Value): read from a dict keyed by id strings.
% The members map is a dict whose keys are the (atomized) identifiers.
causal_core_map_get(Key, Map, Value) :-
    causal_core_atomize(Key, KA), get_dict(KA, Map, Value).

% -- ALGORITHM C (Rule 15). causal_core_classify(+Cro, +OccMap, +StratumMap, -Class).
causal_core_classify(Cro, OccMap, StratumMap, Class) :-
    get_dict(causes, Cro, Causes), get_dict(effects, Cro, Effects),
    ( ( maplist(causal_core_stratum_of(OccMap), Causes, CStrata),
        maplist(causal_core_stratum_of(OccMap), Effects, EStrata) )
        -> causal_core_classify_known(CStrata, EStrata, StratumMap, Class)
        ;  Class = unclassifiable
    ).

% -- Look up the stratum id of an occurrent; fail (→ unclassifiable) if absent.
causal_core_stratum_of(OccMap, OccId, Stratum) :-
    causal_core_map_get(OccId, OccMap, Occ), get_dict(stratum, Occ, Stratum).

% -- Classify once every endpoint's stratum is known.
causal_core_classify_known(CStrata, EStrata, StratumMap, Class) :-
    append(CStrata, EStrata, All), sort(All, AllStrata),
    findall(Sc, (member(S, AllStrata), causal_core_scheme_of(StratumMap, S, Sc)), Schemes),
    sort(Schemes, USchemes),
    ( USchemes = [_,_|_]
        -> Class = scheme_mismatch
        ;  maplist(causal_core_ordinal_of(StratumMap), CStrata, COrd),
           maplist(causal_core_ordinal_of(StratumMap), EStrata, EOrd),
           causal_core_classify_ordinals(COrd, EOrd, Class)
    ).

% -- Scheme of a stratum id via the stratum map.
causal_core_scheme_of(StratumMap, S, Scheme) :- causal_core_map_get(S, StratumMap, St), get_dict(scheme, St, Scheme).
% -- Ordinal of a stratum id via the stratum map.
causal_core_ordinal_of(StratumMap, S, Ord) :- causal_core_map_get(S, StratumMap, St), get_dict(ordinal, St, Ord).

% -- Decide the class from cause and effect ordinal lists.
causal_core_classify_ordinals(COrd, EOrd, Class) :-
    max_list(COrd, CMax), min_list(COrd, CMin), max_list(EOrd, EMax), min_list(EOrd, EMin),
    ( CMax =:= CMin, CMin =:= EMax, EMax =:= EMin
        -> Class = intra_stratal
        ;  findall(D, (member(I, COrd), member(J, EOrd), D is abs(I-J)), Ds),
           min_list(Ds, Gap), max_list(Ds, Span),
           ( Span =:= 1 -> Class = adjacent_stratal
           ; Gap > 1    -> Class = skipping
           ;               Class = mixed )
    ).

% -- causal_core_endpoints_mixed(+Cro, +OccMap): causes or effects span >1 stratum.
causal_core_endpoints_mixed(Cro, OccMap) :-
    get_dict(causes, Cro, Causes), get_dict(effects, Cro, Effects),
    maplist(causal_core_stratum_of(OccMap), Causes, CS),
    maplist(causal_core_stratum_of(OccMap), Effects, ES),
    sort(CS, UCS), sort(ES, UES),
    ( length(UCS, NC), NC > 1 ; length(UES, NE), NE > 1 ), !.

% -- ALGORITHM D (Rule 16). causal_core_skip_gaps(+Cro, +Class, -Gaps).
causal_core_skip_gaps(Cro, Class, Gaps) :-
    ( get_dict(mechanism, Cro, M), M \== [] -> HasMech = true ; HasMech = false ),
    ( get_dict(skips, Cro, true) -> Skips = true ; Skips = false ),
    ( Skips == true, HasMech == true
        % A hard contradiction short-circuits every other gap.
        -> Gaps = [contradictory_skip]
        ;  findall(G, causal_core_skip_gap(Skips, HasMech, Class, G), Gaps)
    ).

% -- vacuous_skip: skips:true where the classification is not skipping/unclassifiable.
causal_core_skip_gap(true, _, Class, vacuous_skip) :-
    Class \== skipping, Class \== unclassifiable.
% incomplete_mechanism: a skipping relation without a mechanism and without skips:true.
causal_core_skip_gap(false, false, skipping, incomplete_mechanism).

% -- ALGORITHM E surface (Rule 20). causal_core_delay_within_window(+ActualDelay, +Temporal, -Bool).
causal_core_delay_within_window(ActualDelay, Temporal, true) :-
    ( ActualDelay == none ; Temporal == none ), !.
% 3.0.0: an ordinal delay compares to an ordinal window by integer tick count; an ordinal delay and a wall-clock window
% (or the reverse) are different dimensions and never fall within one another.
causal_core_delay_within_window(ActualDelay, Temporal, Bool) :-
    get_dict(unit, ActualDelay, AU), get_dict(unit, Temporal, TU),
    causal_core_dimension(AU, DimA), causal_core_dimension(TU, DimT),
    ( DimA \== DimT
      -> Bool = false
    ; DimA == ordinal
      -> get_dict(duration, ActualDelay, Obs),
         get_dict(minimum_delay, Temporal, Lo), get_dict(maximum_delay, Temporal, Hi),
         ( ( Lo =< Obs, Obs =< Hi ) -> Bool = true ; Bool = false )
    ; get_dict(duration, ActualDelay, Dur), causal_core_to_seconds(Dur, AU, Observed),
      get_dict(minimum_delay, Temporal, Lo0), causal_core_to_seconds(Lo0, TU, Lo),
      get_dict(maximum_delay, Temporal, Hi0), causal_core_to_seconds(Hi0, TU, Hi),
      ( ( Lo =< Observed, Observed =< Hi ) -> Bool = true ; Bool = false )
    ).

% -- Rule 14 (N3.2.1). causal_core_bridge_wellformed(+Bridge, +OccMap, +StratumMap, -Result).
causal_core_bridge_wellformed(Bridge, OccMap, StratumMap, Result) :-
    ( \+ ( get_dict(coarse, Bridge, Coarse), causal_core_stratum_of_id(OccMap, Coarse, _) )
        -> Result = invalid("malformed_bridge: coarse has no stratum (a)")
    ; get_dict(fine, Bridge, Fine),
      \+ maplist(causal_core_has_stratum(OccMap), Fine)
        -> Result = invalid("malformed_bridge: a fine member has no stratum (b)")
    ; get_dict(fine, Bridge, Fine2),
      maplist(causal_core_stratum_of_id(OccMap), Fine2, FineStrata), sort(FineStrata, US), US = [_,_|_]
        -> Result = invalid("malformed_bridge: fine members span >1 stratum (c)")
    ; get_dict(coarse, Bridge, C3), causal_core_stratum_of_id(OccMap, C3, CS),
      get_dict(fine, Bridge, [F1|_]), causal_core_stratum_of_id(OccMap, F1, FS),
      causal_core_scheme_of(StratumMap, CS, ScC), causal_core_scheme_of(StratumMap, FS, ScF), ScC \== ScF
        -> Result = invalid("malformed_bridge: coarse and fine differ in scheme (d)")
    ; get_dict(coarse, Bridge, C4), causal_core_stratum_of_id(OccMap, C4, CS4),
      get_dict(fine, Bridge, [F2|_]), causal_core_stratum_of_id(OccMap, F2, FS4),
      causal_core_ordinal_of(StratumMap, CS4, OC), causal_core_ordinal_of(StratumMap, FS4, OF), \+ OC > OF
        -> Result = invalid("malformed_bridge: coarse ordinal not > fine ordinal (e)")
    ; Result = ok("well-formed bridge")
    ).

% -- Helpers: the stratum id of an occurrent id, and a presence check.
causal_core_stratum_of_id(OccMap, OccId, Stratum) :- causal_core_map_get(OccId, OccMap, Occ), get_dict(stratum, Occ, Stratum).
% Succeeds if the occurrent has a stratum.
causal_core_has_stratum(OccMap, OccId) :- causal_core_stratum_of_id(OccMap, OccId, _).

% -- 3.0.0 Rule 22 / Algorithm F. causal_core_seam_wellformed(+Seam, +OccMap, +StratumMap, -Result).
% A Cross Stratal Seam is a MANAGED jump across NON-ADJACENT strata; a drawn chain must be intervening,
% strictly-between the endpoints, strictly monotone, and forbids mechanism_status 'absent'.
causal_core_seam_wellformed(Seam, OccMap, StratumMap, Result) :-
    ( \+ ( get_dict(source, Seam, Src), causal_core_stratum_of_id(OccMap, Src, _) )
        -> Result = invalid("malformed_seam: source has no stratum (a)")
    ; \+ ( get_dict(target, Seam, Tgt), causal_core_stratum_of_id(OccMap, Tgt, _) )
        -> Result = invalid("malformed_seam: target has no stratum (a)")
    ; get_dict(source, Seam, S1), causal_core_stratum_of_id(OccMap, S1, SS1),
      get_dict(target, Seam, T1), causal_core_stratum_of_id(OccMap, T1, TS1),
      causal_core_scheme_of(StratumMap, SS1, ScS), causal_core_scheme_of(StratumMap, TS1, ScT), ScS \== ScT
        -> Result = invalid("malformed_seam: endpoints differ in scheme (b)")
    ; get_dict(source, Seam, S2), causal_core_stratum_of_id(OccMap, S2, SS2),
      get_dict(target, Seam, T2), causal_core_stratum_of_id(OccMap, T2, TS2),
      causal_core_ordinal_of(StratumMap, SS2, OS), causal_core_ordinal_of(StratumMap, TS2, OT),
      Gap is abs(OS - OT), Gap =< 1
        -> Result = invalid("malformed_seam: endpoints are adjacent or co-stratal; a seam is for NON-adjacent strata (c)")
    ; get_dict(chain, Seam, Chain)
        -> causal_core_seam_chain_check(Seam, Chain, OccMap, StratumMap, Result)
    ; Result = ok("well-formed cross_stratal_seam")
    ).

% -- causal_core_seam_chain_check: a drawn chain forbids 'absent', and each member is intervening + strictly monotone.
causal_core_seam_chain_check(Seam, Chain, OccMap, StratumMap, Result) :-
    get_dict(source, Seam, S), causal_core_stratum_of_id(OccMap, S, SS),
    get_dict(target, Seam, T), causal_core_stratum_of_id(OccMap, T, TS),
    causal_core_ordinal_of(StratumMap, SS, OS), causal_core_ordinal_of(StratumMap, TS, OT),
    Lo is min(OS, OT), Hi is max(OS, OT),
    ( get_dict(mechanism_status, Seam, MS0), causal_core_atomize(MS0, absent)
        -> Result = invalid("malformed_seam: a drawn chain contradicts mechanism_status 'absent' (d)")
    ; \+ maplist(causal_core_has_stratum(OccMap), Chain)
        -> Result = invalid("malformed_seam: a chain member has no stratum (e)")
    ; maplist(causal_core_chain_ordinal(OccMap, StratumMap), Chain, Ords),
      \+ forall(member(O, Ords), ( Lo < O, O < Hi ))
        -> Result = invalid("malformed_seam: a chain member is not at an INTERVENING stratum (f)")
    ; maplist(causal_core_chain_ordinal(OccMap, StratumMap), Chain, Ords2),
      \+ causal_core_strictly_monotone(Ords2)
        -> Result = invalid("malformed_seam: chain is not strictly monotone from one endpoint toward the other (g)")
    ; Result = ok("well-formed cross_stratal_seam")
    ).

% -- the ordinal of a chain member's stratum.
causal_core_chain_ordinal(OccMap, StratumMap, OccId, Ord) :-
    causal_core_stratum_of_id(OccMap, OccId, St), causal_core_ordinal_of(StratumMap, St, Ord).

% -- strictly monotone: all successive differences share one sign (all up, or all down).
causal_core_strictly_monotone([_]) :- !.
causal_core_strictly_monotone([]) :- !.
causal_core_strictly_monotone(L) :-
    findall(D, ( nth0(I, L, A), I1 is I + 1, nth0(I1, L, B), D is B - A ), Diffs),
    ( forall(member(D, Diffs), D > 0) ; forall(member(D, Diffs), D < 0) ).

% -- THE HOME RULE (3.0.0). causal_core_seam_home(+Seam, +OccMap, +StratumMap, -HomeStratumId): the coarsest (max-ordinal) endpoint stratum.
causal_core_seam_home(Seam, OccMap, StratumMap, Home) :-
    get_dict(source, Seam, S), causal_core_stratum_of_id(OccMap, S, SS),
    get_dict(target, Seam, T), causal_core_stratum_of_id(OccMap, T, TS),
    causal_core_ordinal_of(StratumMap, SS, OS), causal_core_ordinal_of(StratumMap, TS, OT),
    ( OS >= OT -> Home = SS ; Home = TS ).

% -- Rule 17 (N4.2.1-2). causal_core_conduit_wellformed(+Conduit, +PortMap, +CroMap, -Result).
causal_core_conduit_wellformed(Conduit, PortMap, CroMap, Result) :-
    ( \+ ( get_dict(from, Conduit, Fr), causal_core_map_get(Fr, PortMap, _) )
        -> Result = invalid("malformed_conduit: dangling port reference")
    ; \+ ( get_dict(to, Conduit, To0), causal_core_map_get(To0, PortMap, _) )
        -> Result = invalid("malformed_conduit: dangling port reference")
    ; get_dict(from, Conduit, Fr1), causal_core_map_get(Fr1, PortMap, FromPort),
      get_dict(direction, FromPort, FDir), causal_core_atomize(FDir, FDA), \+ member(FDA, [out, bidirectional])
        -> Result = invalid("malformed_conduit: from port is not out/bidirectional (a)")
    ; get_dict(to, Conduit, To1), causal_core_map_get(To1, PortMap, ToPort),
      get_dict(direction, ToPort, TDir), causal_core_atomize(TDir, TDA), \+ member(TDA, [in, bidirectional])
        -> Result = invalid("malformed_conduit: to port is not in/bidirectional (b)")
    ; get_dict(from, Conduit, Fr2), causal_core_map_get(Fr2, PortMap, FromPort2), get_dict(accepts, FromPort2, FAcc),
      get_dict(carries, Conduit, Carries), \+ forall(member(O, Carries), memberchk(O, FAcc))
        -> Result = invalid("malformed_conduit: carries not accepted by from (c)")
    ; causal_core_conduit_to_ok(Conduit, PortMap, CroMap)
        -> Result = ok("well-formed conduit")
    ; Result = invalid("malformed_conduit: carries/transform effects not accepted by to (d)")
    ).

% -- The to-side acceptance check, with the transform exception of N4.2.2.
causal_core_conduit_to_ok(Conduit, PortMap, _CroMap) :-
    \+ get_dict(transform, Conduit, _), !,
    get_dict(to, Conduit, To), causal_core_map_get(To, PortMap, ToPort), get_dict(accepts, ToPort, TAcc),
    get_dict(carries, Conduit, Carries), forall(member(O, Carries), memberchk(O, TAcc)).
% With a transform whose law is known, the law's effects must be accepted by the to-port.
causal_core_conduit_to_ok(Conduit, PortMap, CroMap) :-
    get_dict(transform, Conduit, Tid),
    ( causal_core_map_get(Tid, CroMap, Law)
        -> get_dict(to, Conduit, To), causal_core_map_get(To, PortMap, ToPort), get_dict(accepts, ToPort, TAcc),
           get_dict(effects, Law, Effects), forall(member(O, Effects), memberchk(O, TAcc))
        ;  true  % an unknown transform law is not refuted (relaxed per N4.2.2)
    ).

% -- Rule 19 (N5.3.1-2). causal_core_state_gaps(+State, +Quality, -Gaps).
causal_core_state_gaps(State, Quality, Gaps) :-
    get_dict(datatype, Quality, DtV), causal_core_atomize(DtV, Dt),
    get_dict(value, State, V),
    ( get_dict(quantity, V, _) -> Shape = quantity
    ; get_dict(categorical, V, _) -> Shape = categorical
    ; get_dict(boolean, V, _) -> Shape = boolean
    ; Shape = none ),
    ( Shape \== Dt
        -> Gaps = [value_type_mismatch]
    ;  ( Dt == quantity, get_dict(unit, V, VU), get_dict(unit, Quality, QU), \+ VU == QU )
        -> Gaps = [unit_mismatch]
    ;  Gaps = []
    ).

% -- Rule 20. causal_core_covering_law_mismatch(+Tcc, +TokenMap, +Law): tokens do not instantiate the law.
causal_core_covering_law_mismatch(Tcc, TokenMap, Law) :-
    get_dict(causes, Law, LC), sort(LC, LCauses), get_dict(effects, Law, LE), sort(LE, LEffects),
    ( get_dict(causes, Tcc, TCs), member(C, TCs), causal_core_map_get(C, TokenMap, Tok),
      get_dict(instantiates, Tok, Inst), \+ memberchk(Inst, LCauses)
    ; get_dict(effects, Tcc, TEs), member(E, TEs), causal_core_map_get(E, TokenMap, Tok2),
      get_dict(instantiates, Tok2, Inst2), \+ memberchk(Inst2, LEffects)
    ), !.

% -- Rule 21. causal_core_retrocausal(+Tcc, +TokenMap): a cause token starts after an effect token.
causal_core_retrocausal(Tcc, TokenMap) :-
    get_dict(causes, Tcc, TCs), member(C, TCs), causal_core_map_get(C, TokenMap, Tok),
    get_dict(interval, Tok, CI), get_dict(start, CI, CStart),
    get_dict(effects, Tcc, TEs), member(E, TEs), causal_core_map_get(E, TokenMap, Tok2),
    get_dict(interval, Tok2, EI), get_dict(start, EI, EStart),
    CStart @> EStart, !.

% -- Generic acyclicity. causal_core_has_cycle(+Edges): Edges is a dict node -> list of successors.
causal_core_has_cycle(Edges) :-
    dict_pairs(Edges, _, Pairs),
    member(Start-_, Pairs),
    causal_core_dfs_cycle(Start, Edges, [], _), !.

% -- Depth-first cycle detection tracking the current path.
causal_core_dfs_cycle(Node, _Edges, Path, cycle) :-
    memberchk(Node, Path), !.
causal_core_dfs_cycle(Node, Edges, Path, Res) :-
    ( get_dict(Node, Edges, Succs) -> true ; Succs = [] ),
    member(Next, Succs),
    causal_core_dfs_cycle(Next, Edges, [Node|Path], Res),
    Res == cycle, !.
