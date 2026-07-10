/*  PrologAI — Causalontology Learning  (WP-394, Layer 369)

    Interventional acquisition of causal structure (Causalontology_v5,
    Sections 4.3, 6.1, 6.3, 6.4): the agent acts, which is an intervention;
    it observes the effect; it induces a new CRO or confirms an existing one
    by raising its strength; and on first inducing an action-effect it
    posits, on the noun side, the disposition the verb-side causation has
    revealed — populating the hinge from the bottom up.

    Doing versus seeing (Section 6.1): interventional evidence is first
    class; where intervention is impossible, co_observe/2 records the
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
      co_learn_reset/0        -- clear the learning state
      co_intervene/3          -- :ActGoal, +Action, -Outcome
      co_learn_causal/2       -- +Action, +Effect   (induce or confirm)
      co_learn_preventive/2   -- +Action, +Effect   (hazard: avoid-set)
      co_avoid/1              -- ?Action
      co_null_effects/2       -- +Action, -Count    (compact frame store)
      co_observe/2            -- +Cause, +Effect    (observational-only)
      co_interventional/1     -- +Id  (learned by doing, not seeing)
      co_posit_disposition/1  -- +Action (the bottom-up hinge population)
*/

% Declare this module and list every exported predicate with its correct arity.
:- module(co_learn, [
    % co_learn_reset/0: clear the learning state.
    co_learn_reset/0,
    % co_intervene/3: one act-observe-learn intervention.
    co_intervene/3,
    % co_learn_causal/2: induce a new relation or confirm an existing one.
    co_learn_causal/2,
    % co_learn_preventive/2: tag a hazard and add it to the avoid-set.
    co_learn_preventive/2,
    % co_avoid/1: the actions never to re-run.
    co_avoid/1,
    % co_null_effects/2: how often an action produced nothing.
    co_null_effects/2,
    % co_observe/2: an observational-only relation, weighted down.
    co_observe/2,
    % co_interventional/1: relations backed by doing rather than seeing.
    co_interventional/1,
    % co_posit_disposition/1: verb-side causation reveals a noun-side realizable.
    co_posit_disposition/1
]).

% Import the verb layer this pack writes into.
:- use_module(library(co_core), [co_cro/8, co_new_cro/8, co_strengthen/2]).
% Import the hinge this pack populates from the bottom up.
:- use_module(library(co_hinge), [co_realizable/3, co_realizable_add/3, co_realized_in_add/2]).
% Import the fresh-identifier generator.
:- use_module(library(gensym), [gensym/2]).

% The environment is a caller-module closure over an action.
:- meta_predicate co_intervene(2, +, -).

% ---------------------------------------------------------------------------
% Internal state
% ---------------------------------------------------------------------------

% co_avoid_/1: the closed-world avoid-set of harmful actions.
:- dynamic co_avoid_/1.
% co_null_/2: (Action, Count) — null effects stored compactly.
:- dynamic co_null_/2.

% Define co_learn_reset: clear the learning state of this pack.
co_learn_reset :-
    % Drop the avoid-set.
    retractall(co_avoid_(_)),
    % Drop the null-effect counters.
    retractall(co_null_(_, _)).

% ---------------------------------------------------------------------------
% THE INTERVENTIONAL LOOP — do, observe, induce or confirm
% ---------------------------------------------------------------------------

% Define co_intervene: one intervention through the caller's environment.
co_intervene(ActGoal, Action, Outcome) :-
    % Doing: perform the action in the environment.
    call(ActGoal, Action, Effect),
    % Learn from what followed.
    (   Effect == none
    % Nothing observable followed: count it compactly (Section 6.3).
    ->  co_count_null(Action),
        % Report the null outcome.
        Outcome = none
    % Harm followed: tag the hazard (Section 4.6).
    ;   Effect == penalty
    ->  co_learn_preventive(Action, penalty),
        % Report the hazard outcome.
        Outcome = hazard
    % An effect followed: induce or confirm the relation.
    ;   co_learn_causal(Action, Effect),
        % Report the learned effect.
        Outcome = learned(Effect)
    ).

% Define co_learn_causal: induce at 0.70, or confirm by +0.2 capped at 0.99,
% exactly as the specification's pseudocode prescribes (Section 4.3).
co_learn_causal(Action, Effect) :-
    % Is the relation already known?
    (   co_cro(Id, [Action], [Effect], _, _, _, _, _)
    % Confirmation: a repeated intervention raises the strength.
    ->  co_strengthen(Id, 0.2)
    % Induction: a new relation at the canonical initial strength.
    ;   co_new_cro([Action], [Effect], temporal(0, 0, instant), sufficient,
                   0.70, [], prov(agent, learned_by_intervention, 0.70), _Id),
        % Verb-side causation reveals a noun-side realizable.
        co_posit_disposition(Action)
    ).

% Define co_learn_preventive: tag the hazard and never re-run the action.
co_learn_preventive(Action, Effect) :-
    % A hazard is recorded once.
    (   co_avoid_(Action)
    % Already avoided: nothing to add.
    ->  true
    % First discovery: avoid it and reify the preventive relation.
    ;   assertz(co_avoid_(Action)),
        % The preventive relation at the canonical hazard strength.
        co_new_cro([Action], [Effect], temporal(0, 0, instant), preventive,
                   0.90, [], prov(agent, learned_by_intervention, 0.90), _Id)
    ).

% Define co_avoid: the actions the agent will never re-run.
co_avoid(Action) :-
    % Enumerate or test the avoid-set.
    co_avoid_(Action).

% ---------------------------------------------------------------------------
% THE FRAME PROBLEM — null effects stored compactly
% ---------------------------------------------------------------------------

% co_count_null(+Action): one more observation that nothing followed.
co_count_null(Action) :-
    % Fetch and bump the counter.
    (   retract(co_null_(Action, N))
    % Increment an existing counter.
    ->  N1 is N + 1
    % Start a new counter.
    ;   N1 = 1
    ),
    % Store the counter back.
    assertz(co_null_(Action, N1)).

% Define co_null_effects: how often an action produced nothing.
co_null_effects(Action, Count) :-
    % Read the counter, zero when never observed null.
    ( co_null_(Action, Count0) -> Count = Count0 ; Count = 0 ).

% ---------------------------------------------------------------------------
% DOING VERSUS SEEING — observational relations are flagged and weighted down
% ---------------------------------------------------------------------------

% Define co_observe: where intervention is impossible, the relation is
% recorded observational-only at a deliberately low strength (Section 6.1).
co_observe(Cause, Effect) :-
    % Do not duplicate an existing relation for the pair.
    (   co_cro(_, [Cause], [Effect], _, _, _, _, _)
    % Already known: observation adds nothing over intervention.
    ->  true
    % New: flagged observational in the context, weighted down.
    ;   co_new_cro([Cause], [Effect], temporal(0, unspecified, unspecified),
                   contributory, 0.30, [observational],
                   prov(observation, observational_only, 0.30), _Id)
    ).

% Define co_interventional: relations backed by doing rather than seeing.
co_interventional(Id) :-
    % Read the provenance of the relation.
    co_cro(Id, _, _, _, _, _, _, prov(_, Evidence, _)),
    % Interventional evidence is the mark.
    Evidence == learned_by_intervention.

% ---------------------------------------------------------------------------
% THE BOTTOM-UP HINGE — causation reveals dispositions
% ---------------------------------------------------------------------------

% Define co_posit_disposition: on first inducing Action = F(Object), posit
% that the object bears an F-able disposition realized in that action.
co_posit_disposition(Action) :-
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
    (   co_realizable(_, disposition, Bearer),
        % One disposition per bearer per verb flavor.
        co_flavored(Bearer, Kind0)
    % Already posited: nothing to add.
    ->  true
    % New: posit the disposition and its realization seam.
    ;   gensym(disp_, D),
        % Record the disposition on the noun side.
        co_realizable_add(D, disposition, Bearer),
        % Remember its verb flavor.
        assertz(co_flavor_(D, Bearer, Kind0)),
        % Tie it to the occurrent that realizes it.
        co_realized_in_add(D, Action)
    ).
% Actions of any other shape reveal no disposition.
co_posit_disposition(_).

% co_flavor_/3: (DispositionId, Bearer, Flavor) — the verb flavor record.
:- dynamic co_flavor_/3.

% co_flavored(+Bearer, +Flavor): the bearer already has this flavor.
co_flavored(Bearer, Flavor) :-
    % Test the flavor store.
    co_flavor_(_, Bearer, Flavor).
