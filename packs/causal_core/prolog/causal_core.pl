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
        (causal_core_precedes) is never read as production (causal_core_causally_linked).
      - The temporal window is part of the mechanism: temporal abduction
        admits a candidate cause only when the elapsed time falls inside
        that cause's window (causal_core_temporal_abduction/3).
      - Hierarchical decomposition: a CRO's mechanism may be a sub-graph of
        finer CROs, and causal_core_hierarchy_consistent/1 checks the coarse relation
        against the composition of its parts (Section 6.2).
      - The subsumption argument (Section 3.2): an external causal relation
        is imported read-only as a degenerate, provisional CRO — some fields
        unspecified — and then refined into an owned relation, so replacement
        loses no information and strictly adds expressive power.
      - The glass-box guarantee: causal_core_why/2 returns the full inspectable story
        of any relation.

    Predicates:
      causal_core_reset/0            -- clear the verb layer
      causal_core_cro_assert/1            -- +CRO           (validated)
      causal_core_new_cro/8               -- +Causes..+Prov, -Id (fresh identifier)
      causal_core_the_cro/2               -- ?Id, -CRO
      causal_core_cro/8                   -- ?Id..?Prov     (open query)
      causal_core_strengthen/2            -- +Id, +Delta    (capped at 0.99)
      causal_core_predict/2               -- +Cause, -Effect (non-preventive)
      causal_core_preventive/1            -- ?Id
      causal_core_precedes_add/2          -- +A, +B         (temporal succession only)
      causal_core_precedes/2              -- ?A, ?B
      causal_core_causally_linked/2       -- +Cause, +Effect (via a CRO, never via time)
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
    % causal_core_cro_assert/1: assert a validated CRO.
    causal_core_cro_assert/1,
    % causal_core_new_cro/8: assert a CRO under a fresh identifier.
    causal_core_new_cro/8,
    % causal_core_cro_find/4: coarse finder by causes, effects, and modality.
    causal_core_cro_find/4,
    % causal_core_cro_find_exact/7: find a relation identical in every defining field.
    causal_core_cro_find_exact/7,
    % causal_core_cro_find_core/3: find a relation with the same core (causes+effects).
    causal_core_cro_find_core/3,
    % causal_core_cro_delta/6: the fields in which a candidate differs from a relation.
    causal_core_cro_delta/6,
    % causal_core_new_cro_unique/8: assert-if-new front door (exact merges; near kept).
    causal_core_new_cro_unique/8,
    % causal_core_new_cro_nuanced/9: assert door reporting exact/variant/new status.
    causal_core_new_cro_nuanced/9,
    % causal_core_cro_variant/3: query the near-duplicate variant links and their deltas.
    causal_core_cro_variant/3,
    % causal_core_cro_variants/1: all variant links, for surfacing flagged near-duplicates.
    causal_core_cro_variants/1,
    % causal_core_cro_dedup/1: remove only EXACT-duplicate relations, keeping variants.
    causal_core_cro_dedup/1,
    % causal_core_the_cro/2: fetch one CRO as a whole term.
    causal_core_the_cro/2,
    % causal_core_cro/8: open query over the CRO store.
    causal_core_cro/8,
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
    % causal_core_causally_linked/2: production, only ever through a CRO.
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

% causal_core_cro_/8: the reified Causal Relation Objects.
:- dynamic causal_core_cro_/8.
% causal_core_precedes_/2: mere temporal succession, never production.
:- dynamic causal_core_precedes_/2.
% causal_core_mechanism_/2: (ParentId, SubIds) — hierarchical decomposition.
:- dynamic causal_core_mechanism_/2.

% Define causal_core_reset: clear every verb-layer store.
causal_core_reset :-
    % Drop the relations.
    retractall(causal_core_cro_(_, _, _, _, _, _, _, _)),
    % Drop the succession records.
    retractall(causal_core_precedes_(_, _)),
    % Drop the mechanism sub-graphs.
    retractall(causal_core_mechanism_(_, _)).

% ---------------------------------------------------------------------------
% THE CRO — assertion with full-payload validation
% ---------------------------------------------------------------------------

% Define causal_core_cro_assert: a CRO enters the store only with a lawful payload.
causal_core_cro_assert(cro(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)) :-
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
    retractall(causal_core_cro_(Id, _, _, _, _, _, _, _)),
    % Record the relation.
    assertz(causal_core_cro_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)).

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

% Define causal_core_new_cro: assert under a fresh identifier and return it.
causal_core_new_cro(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id) :-
    % Allocate a fresh identifier.
    gensym(cro_, Id),
    % Assert through the validating front door.
    causal_core_cro_assert(cro(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)).

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

% causal_core_cro_variant_/3: (CanonicalId, VariantId, Deltas) — two relations that share a
% core but differ in some detail, with the list of differing fields.
:- dynamic causal_core_cro_variant_/3.

% causal_core_cro_find(+Causes, +Effects, +Modality, -Id): a coarse finder kept for callers
% that want the first relation matching causes, effects, and modality. This is NOT
% the merge test — merging uses the exact finder below.
causal_core_cro_find(Causes, Effects, Modality, Id) :-
    % A stored relation with matching causes, effects, and modality.
    causal_core_cro_(Id, Causes, Effects, _, Modality, _, _, _),
    % The first match suffices.
    !.

% causal_core_cro_find_exact(+Causes,+Effects,+Temporal,+Modality,+Context,+Prov, -Id): the
% id of a relation identical in EVERY defining field (strength excluded). Only such
% a relation is a true duplicate to merge.
causal_core_cro_find_exact(Causes, Effects, Temporal, Modality, Context, Prov, Id) :-
    % All defining fields unify; the strength is left free.
    causal_core_cro_(Id, Causes, Effects, Temporal, Modality, _Strength, Context, Prov),
    % The first exact match suffices.
    !.

% causal_core_cro_find_core(+Causes, +Effects, -Id): the id of an existing relation with the
% same core — the same causes and effects — regardless of the other fields. A core
% match that is not an exact match is a near-duplicate (a variant).
causal_core_cro_find_core(Causes, Effects, Id) :-
    % The first relation relating the same cause to the same effect.
    causal_core_cro_(Id, Causes, Effects, _, _, _, _, _),
    % One is enough.
    !.

% causal_core_cro_delta(+ExistingId, +Temporal,+Modality,+Context,+Prov, -Deltas): the list
% of fields in which a candidate differs from an existing relation, each as
% delta(Field, ExistingValue, NewValue). Empty when only the strength differs.
causal_core_cro_delta(ExistingId, Temporal, Modality, Context, Prov, Deltas) :-
    % The existing relation's non-core fields.
    causal_core_cro_(ExistingId, _, _, T0, M0, _, C0, P0),
    % Collect each differing field.
    findall(delta(Field, Old, New),
        ( member(f(Field, Old, New),
              [ f(temporal, T0, Temporal), f(modality, M0, Modality),
                f(context,  C0, Context),  f(prov,     P0, Prov) ]),
          Old \== New ),
        Deltas).

% causal_core_new_cro_nuanced(+Causes,+Effects,+Temporal,+Modality,+Strength,+Context,+Prov,
% -Id, -Status): the nuanced assert door. Status is exact(ExistingId) when an
% identical relation was merged, variant(CanonicalId, Deltas) when a near-duplicate
% was kept and linked, or new when the relation had no core match.
causal_core_new_cro_nuanced(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id, Status) :-
    (   % EXACT duplicate: merge — reuse the id and raise its strength as evidence.
        causal_core_cro_find_exact(Causes, Effects, Temporal, Modality, Context, Prov, Ex)
    ->  Id = Ex,
        catch(causal_core_strengthen(Ex, 0.05), _, true),
        Status = exact(Ex)
    ;   % NEAR duplicate: same core, differs in a detail — keep both, link, flag.
        causal_core_cro_find_core(Causes, Effects, Canonical)
    ->  causal_core_new_cro(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id),
        causal_core_cro_delta(Canonical, Temporal, Modality, Context, Prov, Deltas),
        assertz(causal_core_cro_variant_(Canonical, Id, Deltas)),
        Status = variant(Canonical, Deltas)
    ;   % Genuinely new relation.
        causal_core_new_cro(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id),
        Status = new
    ).

% causal_core_new_cro_unique(+Causes,+Effects,+Temporal,+Modality,+Strength,+Context,+Prov,
% -Id): the assert-if-new front door ingest paths call. It merges only an EXACT
% duplicate; a near-duplicate is kept as a linked variant (see causal_core_new_cro_nuanced),
% so a subtle difference is never silently merged away. Returns the relation's id.
causal_core_new_cro_unique(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id) :-
    causal_core_new_cro_nuanced(Causes, Effects, Temporal, Modality, Strength, Context, Prov, Id, _Status).

% causal_core_cro_variant(?CanonicalId, ?VariantId, ?Deltas): query the variant links — the
% near-duplicate relations kept apart and the fields in which each differs.
causal_core_cro_variant(CanonicalId, VariantId, Deltas) :-
    causal_core_cro_variant_(CanonicalId, VariantId, Deltas).

% causal_core_cro_variants(-List): every variant link as variant(Canonical, Variant, Deltas),
% for surfacing the flagged near-duplicates that want attention.
causal_core_cro_variants(List) :-
    findall(variant(C, V, D), causal_core_cro_variant_(C, V, D), List).

% causal_core_cro_dedup(-Removed): remove only EXACT-duplicate relations, keeping the first
% of each fully-identical group and retracting the rest; near-duplicate variants
% are never removed. Removed is how many were pruned.
causal_core_cro_dedup(Removed) :-
    % Key each relation by its FULL defining content (strength excluded).
    findall(k(Causes, Effects, Temporal, Modality, Context, Prov) - Id,
        causal_core_cro_(Id, Causes, Effects, Temporal, Modality, _S, Context, Prov),
        Pairs),
    % Group by identical content.
    keysort(Pairs, Sorted),
    % Every id after the first in each identical group is an exact duplicate.
    causal_core_dedup_collect(Sorted, none, ToPrune),
    % Retract each exact duplicate; leave variant links untouched.
    forall(member(Pid, ToPrune),
        ( retractall(causal_core_cro_(Pid, _, _, _, _, _, _, _)),
          retractall(causal_core_cro_variant_(_, Pid, _)),
          retractall(causal_core_cro_variant_(Pid, _, _)) )),
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

% Define causal_core_the_cro: fetch one relation as a whole term.
causal_core_the_cro(Id, cro(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov)) :-
    % Read the store.
    causal_core_cro_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov).

% Define causal_core_cro: the open query over the store.
causal_core_cro(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov) :-
    % Enumerate or test the store.
    causal_core_cro_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov).

% Define causal_core_strengthen: confirmation raises strength, capped at 0.99.
causal_core_strengthen(Id, Delta) :-
    % Fetch the relation.
    retract(causal_core_cro_(Id, Causes, Effects, T, M, S0, C, prov(Src, Ev, _))),
    % Raise the strength under the cap.
    S1 is min(0.99, S0 + Delta),
    % Store it back with the confidence tracking the strength.
    assertz(causal_core_cro_(Id, Causes, Effects, T, M, S1, C, prov(Src, Ev, S1))).

% ---------------------------------------------------------------------------
% FORWARD PREDICTION
% ---------------------------------------------------------------------------

% Define causal_core_predict: effects read from learned relations, never preventive ones.
causal_core_predict(Cause, Effect) :-
    % A relation whose causes include this cause.
    causal_core_cro_(_, Causes, Effects, _, Modality, _, _, _),
    % Preventive relations forbid rather than predict.
    Modality \== preventive,
    % The cause participates.
    memberchk(Cause, Causes),
    % Each of its effects is predicted.
    member(Effect, Effects).

% Define causal_core_preventive: the relations that mark hazards.
causal_core_preventive(Id) :-
    % Read the store for preventive modality.
    causal_core_cro_(Id, _, _, _, preventive, _, _, _).

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
    causal_core_cro_(_, Causes, Effects, _, Modality, _, _, _),
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
    causal_core_cro_(_, Causes, Effects, temporal(Dmin, Dmax, Unit), _, _, _, _),
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
          causal_core_cro_(_, Causes, Effects, temporal(Dmin, Dmax, Unit), _, S, _, _),
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
    causal_core_cro_(ParentId, _, _, _, _, _, _, _),
    % Every sub-relation must exist.
    forall(member(S, SubIds), causal_core_cro_(S, _, _, _, _, _, _, _)),
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
    causal_core_cro_(ParentId, Causes, Effects, _, _, _, _, _),
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
    causal_core_cro_(Sub, SubCauses, SubEffects, _, _, _, _, _),
    % Every one of its causes must already be on the frontier.
    forall(member(C, SubCauses), memberchk(C, Frontier)),
    % Its effects join the frontier.
    append(Frontier, SubEffects, Frontier2),
    % Continue toward the target.
    causal_core_chain_reaches(Frontier2, Target, Rest).

% ---------------------------------------------------------------------------
% THE SUBSUMPTION ARGUMENT — import external verbs as degenerate CROs
% ---------------------------------------------------------------------------

% Define causal_core_import_external: an external causal assertion becomes a CRO in
% which the missing fields are unspecified — a degenerate special case.
causal_core_import_external(Source, Cause, Effect, Id) :-
    % Allocate a fresh identifier.
    gensym(cro_, Id),
    % The import is provisional, read-only in spirit, owned once refined.
    causal_core_cro_assert(cro(Id, [Cause], [Effect],
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
    causal_core_cro_(Id, _, _, _, _, _, Context, _),
    % Test the flag.
    memberchk(provisional, Context).

% Define causal_core_refine_import: fill in the omitted payload; the relation is
% then owned, and strictly more expressive than the import it replaced.
causal_core_refine_import(Id, Temporal, Modality, Strength) :-
    % Fetch the provisional relation.
    causal_core_cro_(Id, Causes, Effects, _, _, _, Context, prov(Source, _, _)),
    % Only provisional imports are refined this way.
    memberchk(provisional, Context),
    % Drop the provisional flag.
    subtract(Context, [provisional], Context2),
    % Re-assert through the validating front door with the full payload.
    causal_core_cro_assert(cro(Id, Causes, Effects, Temporal, Modality, Strength,
                      Context2, prov(Source, refined_after_import, Strength))).

% ---------------------------------------------------------------------------
% GLASS-BOX JUSTIFICATION
% ---------------------------------------------------------------------------

% Define causal_core_why: the full inspectable story of a relation.
causal_core_why(Id, why(Id, causes(Causes), effects(Effects), window(Temporal),
               modality(Modality), strength(Strength), context(Context),
               provenance(Prov), mechanism(SubIds))) :-
    % Fetch the relation.
    causal_core_cro_(Id, Causes, Effects, Temporal, Modality, Strength, Context, Prov),
    % Fetch its mechanism, empty when it has none.
    ( causal_core_mechanism_(Id, SubIds) -> true ; SubIds = [] ).
