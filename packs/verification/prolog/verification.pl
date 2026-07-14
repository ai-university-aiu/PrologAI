/*  PrologAI — Causalontology Verify-Before-Act  (WP-405, Layer 380)

    An explorer that only remembers the exact moves that have already killed it
    will keep dying: it re-learns the same lesson in every new state. The lever the
    ARC-AGI-3 deaths pinned is to VERIFY a move before taking it — to predict, from
    the model already learned, whether an action is likely fatal in the current
    situation even though it has not been tried HERE yet, and to plan a step in the
    model before spending a real action on it.

    This pack is that world-model safety layer. It keeps a small model of fatality
    learned from experience: which (state, action) transitions ended a run, and
    which states are terminal (dead). From that it does two things a bare death-
    memory cannot.

    First, it GENERALISES. An action that has ended the run in several distinct
    states is judged broadly fatal and is predicted fatal in a new state too,
    before it is tried there — the difference between "this exact move killed me
    here" and "this kind of move keeps killing me". A caller ranks its options so
    the predicted-fatal ones fall to the back rather than being taken; they are
    deprioritised, not forbidden, so if every option looks risky the least-risky is
    still available.

    Second, it PLANS IN THE MODEL. Given a caller-supplied transition model (a
    predicate that says what a state would become under an action), it simulates a
    candidate action and checks whether the simulated next state is one already
    known to be dead — catching a fatal move without spending a real action on it.

    Predicates:
      verification_reset/0                    clear the fatality model
      verification_set_threshold/1            -- +K   (broadly-fatal generalisation threshold)
      verification_threshold/1                -- -K
      verification_note_fatal/3               -- +Model, +State, +Action  (a fatal transition)
      verification_note_dead_state/2          -- +Model, +State           (a terminal state)
      verification_fatal_here/3               -- +Model, +State, +Action   (exact memory)
      verification_fatal_count/3              -- +Model, +Action, -Count    (distinct states)
      verification_broadly_fatal/2            -- +Model, +Action           (>= threshold states)
      verification_dead_state/2               -- +Model, +State
      verification_predict_fatal/3            -- +Model, +State, +Action    (exact OR generalised)
      verification_partition/5                -- +Model,+State,+Actions,-Safe,-Risky
      verification_rank/4                     -- +Model,+State,+Actions,-Ranked (safe first)
      verification_lookahead_fatal/4          -- :StepModel,+Model,+State,+Action (plan-in-model)
      verification_choose_safe/5              -- :StepModel,+Model,+State,+Actions,-Best
*/

% Declare this module and its verify-before-act interface.
:- module(verification, [
    % verification_reset/0: clear the fatality model.
    verification_reset/0,
    % verification_set_threshold/1: set the broadly-fatal generalisation threshold.
    verification_set_threshold/1,
    % verification_threshold/1: read the current threshold.
    verification_threshold/1,
    % verification_note_fatal/3: record a (state, action) transition that ended a run.
    verification_note_fatal/3,
    % verification_note_dead_state/2: record a terminal (dead) state.
    verification_note_dead_state/2,
    % verification_fatal_here/3: the exact recorded-fatal test.
    verification_fatal_here/3,
    % verification_fatal_count/3: how many distinct states an action has been fatal in.
    verification_fatal_count/3,
    % verification_broadly_fatal/2: an action fatal in at least the threshold many states.
    verification_broadly_fatal/2,
    % verification_dead_state/2: a state known to be terminal.
    verification_dead_state/2,
    % verification_predict_fatal/3: the combined predictive check (exact or generalised).
    verification_predict_fatal/3,
    % verification_partition/5: split an action set into safe and predicted-fatal.
    verification_partition/5,
    % verification_rank/4: rank actions safe-first, predicted-fatal last.
    verification_rank/4,
    % verification_lookahead_fatal/4: plan one step in a caller's model and judge it fatal.
    verification_lookahead_fatal/4,
    % verification_choose_safe/5: the best action that neither predicts fatal nor simulates
    % into a dead state, with a least-risky fallback.
    verification_choose_safe/5
]).

% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2, append/3]).
% Import aggregation for the distinct-state count.
:- use_module(library(aggregate), [aggregate_all/3]).

% The lookahead predicate calls a caller-supplied transition model.
:- meta_predicate verification_lookahead_fatal(4, +, +, +).
% The safe-choice predicate likewise calls that caller-supplied model.
:- meta_predicate verification_choose_safe(4, +, +, +, -).

% ---------------------------------------------------------------------------
% THE FATALITY MODEL — learned from experience
% ---------------------------------------------------------------------------

% verification_fatal_/3: (Model, State, Action) — a transition observed to end a run.
:- dynamic verification_fatal_/3.
% verification_dead_/2: (Model, State) — a state observed to be terminal (dead).
:- dynamic verification_dead_/2.
% verification_threshold_/1: the broadly-fatal generalisation threshold.
:- dynamic verification_threshold_/1.

% verification_reset: clear the whole fatality model and restore the default threshold.
verification_reset :-
    % Forget every fatal transition.
    retractall(verification_fatal_(_, _, _)),
    % Forget every dead state.
    retractall(verification_dead_(_, _)),
    % Forget any stored threshold.
    retractall(verification_threshold_(_)),
    % Restore the default threshold of two.
    assertz(verification_threshold_(2)).

% verification_set_threshold(+K): set the number of distinct states an action must have been
% fatal in before it is generalised to broadly fatal. K must be a positive integer.
verification_set_threshold(K) :-
    % Only a sensible threshold is accepted.
    integer(K), K >= 1,
    % Forget the previous threshold.
    retractall(verification_threshold_(_)),
    % Store the new threshold.
    assertz(verification_threshold_(K)).

% verification_threshold(-K): the current threshold, defaulting to two.
verification_threshold(K) :-
    % Read the stored threshold, or default.
    ( verification_threshold_(K0) -> K = K0 ; K = 2 ).

% verification_note_fatal(+Model, +State, +Action): record that taking Action in State ended
% the run. Idempotent — the same transition is stored once.
verification_note_fatal(Model, State, Action) :-
    % Store it unless already known.
    ( verification_fatal_(Model, State, Action) -> true
    ; assertz(verification_fatal_(Model, State, Action)) ).

% verification_note_dead_state(+Model, +State): record that State is terminal (a run ended in
% it). Idempotent.
verification_note_dead_state(Model, State) :-
    % Store it unless already known.
    ( verification_dead_(Model, State) -> true
    ; assertz(verification_dead_(Model, State)) ).

% ---------------------------------------------------------------------------
% PREDICTION — exact memory and the generalisation beyond it
% ---------------------------------------------------------------------------

% verification_fatal_here(+Model, +State, +Action): the exact recorded-fatal test — this
% move has ended a run from this very state before.
verification_fatal_here(Model, State, Action) :-
    % A recorded fatal transition matches exactly.
    verification_fatal_(Model, State, Action).

% verification_fatal_count(+Model, +Action, -Count): how many DISTINCT states this action has
% ended a run in — the evidence that it is fatal as a kind of move, not just here.
verification_fatal_count(Model, Action, Count) :-
    % Count the distinct states.
    aggregate_all(count, distinct_fatal_state(Model, Action, _), Count).

% distinct_fatal_state(+Model, +Action, -State): one distinct fatal state (setof
% over the states this action was fatal in).
distinct_fatal_state(Model, Action, State) :-
    % The distinct states, enumerated one at a time.
    setof(S, verification_fatal_(Model, S, Action), States),
    % Yield each.
    member(State, States).

% verification_broadly_fatal(+Model, +Action): the action has ended a run in at least the
% threshold many distinct states, so it is judged fatal as a kind of move.
verification_broadly_fatal(Model, Action) :-
    % The generalisation threshold.
    verification_threshold(K),
    % The distinct-state count.
    verification_fatal_count(Model, Action, Count),
    % Enough distinct deaths to generalise.
    Count >= K.

% verification_dead_state(+Model, +State): a state known to be terminal.
verification_dead_state(Model, State) :-
    % A recorded dead state.
    verification_dead_(Model, State).

% verification_predict_fatal(+Model, +State, +Action): the combined predictive check — the
% action is predicted fatal in this state if it has ended a run from this exact
% state, OR it is broadly fatal (has killed in enough distinct states to
% generalise). This is the "verify before act" judgement.
verification_predict_fatal(Model, State, Action) :-
    % Exact memory of a death here.
    ( verification_fatal_here(Model, State, Action)
    % Or a generalisation from deaths elsewhere.
    ; verification_broadly_fatal(Model, Action)
    ),
    % One witness suffices.
    !.

% ---------------------------------------------------------------------------
% RANKING — deprioritise, do not forbid
% ---------------------------------------------------------------------------

% verification_partition(+Model, +State, +Actions, -Safe, -Risky): split the action set into
% those not predicted fatal and those predicted fatal, each keeping input order.
verification_partition(_, _, [], [], []).
% verification_partition/5 (step): place the head action, then recurse on the tail.
verification_partition(Model, State, [A | As], Safe, Risky) :-
    % Recurse on the rest.
    verification_partition(Model, State, As, Safe0, Risky0),
    % Place this action by the prediction.
    ( verification_predict_fatal(Model, State, A)
    ->  Safe = Safe0, Risky = [A | Risky0]
    ;   Safe = [A | Safe0], Risky = Risky0
    ).

% verification_rank(+Model, +State, +Actions, -Ranked): the actions with the safe ones first
% (in their original order) and the predicted-fatal ones last. Nothing is dropped,
% so if every option is risky the least-bad is still reachable.
verification_rank(Model, State, Actions, Ranked) :-
    % Split into safe and risky.
    verification_partition(Model, State, Actions, Safe, Risky),
    % Concatenate the safe ones ahead of the risky ones.
    append(Safe, Risky, Ranked).

% ---------------------------------------------------------------------------
% PLAN IN THE MODEL — simulate a step before spending a real action
% ---------------------------------------------------------------------------

% verification_lookahead_fatal(:StepModel, +Model, +State, +Action): simulate taking Action
% in State using the caller's transition model, and succeed if the move is fatal —
% either predicted fatal outright, or it leads (in the model) to a state already
% known to be dead. StepModel(State, Action, NextState) is the caller's model.
verification_lookahead_fatal(StepModel, Model, State, Action) :-
    % The action is fatal outright by prediction, or...
    ( verification_predict_fatal(Model, State, Action)
    -> true
    % ...simulating it lands in a state already known to be dead.
    ;  call(StepModel, State, Action, NextState),
       % The simulated next state is one already known to be dead.
       verification_dead_state(Model, NextState)
    ).

% verification_choose_safe(:StepModel, +Model, +State, +Actions, -Best): the first action
% that neither predicts fatal nor, in the model, leads into a dead state. If every
% action looks fatal, fall back to the least-risky by the safe-first ranking, so
% the caller always gets a choice rather than stalling.
verification_choose_safe(StepModel, Model, State, Actions, Best) :-
    % There must be something to choose.
    Actions \== [],
    % Prefer an action that survives the lookahead.
    (   member(Best, Actions),
        % ...that does not look fatal one step ahead.
        \+ verification_lookahead_fatal(StepModel, Model, State, Best)
    ->  true
    % Otherwise take the least-risky (safe-first) action.
    ;   verification_rank(Model, State, Actions, [Best | _])
    ).
