/*  PrologAI — Causalontology Learning  (WP-394, Layer 369)

    Interventional acquisition of causal structure (Causalontology_v5,
    Sections 4.3, 6.1, 6.3, 6.4): the agent acts, which is an intervention;
    it observes the effect; it induces a new causal_relation_object or confirms an existing one
    by raising its strength; and on first inducing an action-effect it
    posits, on the noun side, the disposition the verb-side causation has
    revealed — populating the hinge from the bottom up.

    Doing versus seeing (Section 6.1): interventional evidence is first
    class; where intervention is impossible, causal_learning_observe/2 records the
    relation flagged observational-only and weighted down.

    The frame problem (Section 6.3): null effects are stored compactly as
    counters, never as one relation per non-effect.

    Open- and closed-world discipline (Section 6.4): the negative knowledge
    the agent learns for itself — null effects and preventive relations —
    is closed-world by design and kept in this pack's own namespace.

    Safety (Section 4.6): an action that produces harm is tagged preventive
    and added to the avoid-set, so a curious agent explores widely but never
    re-runs an action it has learned to be harmful.

    The environment is a caller-supplied goal called as
    call(ActGoal, Action, Effect), where Effect is none, penalty, or an
    observed occurrent — a body, a game, or a test double.

    Predicates:
      causal_learning_reset/0        -- clear the learning state
      causal_learning_intervene/3          -- :ActGoal, +Action, -Outcome
      causal_learning_causal/2       -- +Action, +Effect   (induce or confirm)
      causal_learning_preventive/2   -- +Action, +Effect   (hazard: avoid-set)
      causal_learning_avoid/1              -- ?Action
      causal_learning_null_effects/2       -- +Action, -Count    (compact frame store)
      causal_learning_observe/2            -- +Cause, +Effect    (observational-only)
      causal_learning_interventional/1     -- +Id  (learned by doing, not seeing)
      causal_learning_posit_disposition/1  -- +Action (the bottom-up hinge population)
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(causal_learning, [
    % causal_learning_reset/0: clear the learning state.
    causal_learning_reset/0,
    % causal_learning_intervene/3: one act-observe-learn intervention.
    causal_learning_intervene/3,
    % causal_learning_causal/2: induce a new relation or confirm an existing one.
    causal_learning_causal/2,
    % causal_learning_preventive/2: tag a hazard and add it to the avoid-set.
    causal_learning_preventive/2,
    % causal_learning_avoid/1: the actions never to re-run.
    causal_learning_avoid/1,
    % causal_learning_null_effects/2: how often an action produced nothing.
    causal_learning_null_effects/2,
    % causal_learning_observe/2: an observational-only relation, weighted down.
    causal_learning_observe/2,
    % causal_learning_interventional/1: relations backed by doing rather than seeing.
    causal_learning_interventional/1,
    % causal_learning_posit_disposition/1: verb-side causation reveals a noun-side realizable.
    causal_learning_posit_disposition/1
]).

% Import the verb layer this pack writes into.
:- use_module(library(causal_core), [causal_core_causal_relation_object/8, causal_core_new_causal_relation_object/8, causal_core_strengthen/2]).
% Import the hinge this pack populates from the bottom up.
:- use_module(library(realizable_hinge), [realizable_hinge_realizable/3, realizable_hinge_realizable_add/3, realizable_hinge_realized_in_add/2]).
% Import the fresh-identifier generator.
:- use_module(library(gensym), [gensym/2]).

% The environment is a caller-module closure over an action.
:- meta_predicate causal_learning_intervene(2, +, -).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% causal_learning_avoid_/1: the closed-world avoid-set of harmful actions.
:- dynamic causal_learning_avoid_/1.
% causal_learning_null_/2: (Action, Count) — null effects stored compactly.
:- dynamic causal_learning_null_/2.

% Define causal_learning_reset: clear the learning state of this pack.
causal_learning_reset :-
    % Drop the avoid-set.
    retractall(causal_learning_avoid_(_)),
    % Drop the null-effect counters.
    retractall(causal_learning_null_(_, _)).

% ---------------------------------------------------------------------------
% THE INTERVENTIONAL LOOP — do, observe, induce or confirm
% ---------------------------------------------------------------------------

% Define causal_learning_intervene: one intervention through the caller's environment.
causal_learning_intervene(ActGoal, Action, Outcome) :-
    % Doing: perform the action in the environment.
    call(ActGoal, Action, Effect),
    % Learn from what followed.
    (   Effect == none
    % Nothing observable followed: count it compactly (Section 6.3).
    ->  causal_learning_count_null(Action),
        % Report the null outcome.
        Outcome = none
    % Harm followed: tag the hazard (Section 4.6).
    ;   Effect == penalty
    ->  causal_learning_preventive(Action, penalty),
        % Report the hazard outcome.
        Outcome = hazard
    % An effect followed: induce or confirm the relation.
    ;   causal_learning_causal(Action, Effect),
        % Report the learned effect.
        Outcome = learned(Effect)
    ).

% Define causal_learning_causal: induce at 0.70, or confirm by +0.2 capped at 0.99,
% exactly as the specification's pseudocode prescribes (Section 4.3).
causal_learning_causal(Action, Effect) :-
    % Is the relation already known?
    (   causal_core_causal_relation_object(Id, [Action], [Effect], _, _, _, _, _)
    % Confirmation: a repeated intervention raises the strength.
    ->  causal_core_strengthen(Id, 0.2)
    % Induction: a new relation at the canonical initial strength.
    ;   causal_core_new_causal_relation_object([Action], [Effect], temporal(0, 0, instant), sufficient,
                   0.70, [], prov(agent, learned_by_intervention, 0.70), _Id),
        % Verb-side causation reveals a noun-side realizable.
        causal_learning_posit_disposition(Action)
    ).

% Define causal_learning_preventive: tag the hazard and never re-run the action.
causal_learning_preventive(Action, Effect) :-
    % A hazard is recorded once.
    (   causal_learning_avoid_(Action)
    % Already avoided: nothing to add.
    ->  true
    % First discovery: avoid it and reify the preventive relation.
    ;   assertz(causal_learning_avoid_(Action)),
        % The preventive relation at the canonical hazard strength.
        causal_core_new_causal_relation_object([Action], [Effect], temporal(0, 0, instant), preventive,
                   0.90, [], prov(agent, learned_by_intervention, 0.90), _Id)
    ).

% Define causal_learning_avoid: the actions the agent will never re-run.
causal_learning_avoid(Action) :-
    % Enumerate or test the avoid-set.
    causal_learning_avoid_(Action).

% ---------------------------------------------------------------------------
% THE FRAME PROBLEM — null effects stored compactly
% ---------------------------------------------------------------------------

% causal_learning_count_null(+Action): one more observation that nothing followed.
causal_learning_count_null(Action) :-
    % Fetch and bump the counter.
    (   retract(causal_learning_null_(Action, N))
    % Increment an existing counter.
    ->  N1 is N + 1
    % Start a new counter.
    ;   N1 = 1
    ),
    % Store the counter back.
    assertz(causal_learning_null_(Action, N1)).

% Define causal_learning_null_effects: how often an action produced nothing.
causal_learning_null_effects(Action, Count) :-
    % Read the counter, zero when never observed null.
    ( causal_learning_null_(Action, Count0) -> Count = Count0 ; Count = 0 ).

% ---------------------------------------------------------------------------
% DOING VERSUS SEEING — observational relations are flagged and weighted down
% ---------------------------------------------------------------------------

% Define causal_learning_observe: where intervention is impossible, the relation is
% recorded observational-only at a deliberately low strength (Section 6.1).
causal_learning_observe(Cause, Effect) :-
    % Do not duplicate an existing relation for the pair.
    (   causal_core_causal_relation_object(_, [Cause], [Effect], _, _, _, _, _)
    % Already known: observation adds nothing over intervention.
    ->  true
    % New: flagged observational in the context, weighted down.
    ;   causal_core_new_causal_relation_object([Cause], [Effect], temporal(0, unspecified, unspecified),
                   contributory, 0.30, [observational],
                   prov(observation, observational_only, 0.30), _Id)
    ).

% Define causal_learning_interventional: relations backed by doing rather than seeing.
causal_learning_interventional(Id) :-
    % Read the provenance of the relation.
    causal_core_causal_relation_object(Id, _, _, _, _, _, _, prov(_, Evidence, _)),
    % Interventional evidence is the mark.
    Evidence == learned_by_intervention.

% ---------------------------------------------------------------------------
% THE BOTTOM-UP HINGE — causation reveals dispositions
% ---------------------------------------------------------------------------

% Define causal_learning_posit_disposition: on first inducing Action = F(Object), posit
% that the object bears an F-able disposition realized in that action.
causal_learning_posit_disposition(Action) :-
    % Only compound actions over a bearer reveal a disposition.
    compound(Action),
    % Decompose the action into its verb and its object.
    Action =.. [Verb, Bearer],
    % Commit to the one-argument action shape.
    !,
    % Name the disposition kind after the verb.
    atomic_list_concat([Verb, able], Kind0),
    % The realizable kinds of the hinge are fixed; the flavor is recorded
    % on the identifier, and the kind is disposition.
    (   realizable_hinge_realizable(_, disposition, Bearer),
        % One disposition per bearer per verb flavor.
        causal_learning_flavored(Bearer, Kind0)
    % Already posited: nothing to add.
    ->  true
    % New: posit the disposition and its realization seam.
    ;   gensym(disp_, D),
        % Record the disposition on the noun side.
        realizable_hinge_realizable_add(D, disposition, Bearer),
        % Remember its verb flavor.
        assertz(causal_learning_flavor_(D, Bearer, Kind0)),
        % Tie it to the occurrent that realizes it.
        realizable_hinge_realized_in_add(D, Action)
    ).
% Actions of any other shape reveal no disposition.
causal_learning_posit_disposition(_).

% causal_learning_flavor_/3: (DispositionId, Bearer, Flavor) — the verb flavor record.
:- dynamic causal_learning_flavor_/3.

% causal_learning_flavored(+Bearer, +Flavor): the bearer already has this flavor.
causal_learning_flavored(Bearer, Flavor) :-
    % Test the flavor store.
    causal_learning_flavor_(_, Bearer, Flavor).
