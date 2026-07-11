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
      vb_reset/0                    clear the fatality model
      vb_set_threshold/1            -- +K   (broadly-fatal generalisation threshold)
      vb_threshold/1                -- -K
      vb_note_fatal/3               -- +Model, +State, +Action  (a fatal transition)
      vb_note_dead_state/2          -- +Model, +State           (a terminal state)
      vb_fatal_here/3               -- +Model, +State, +Action   (exact memory)
      vb_fatal_count/3              -- +Model, +Action, -Count    (distinct states)
      vb_broadly_fatal/2            -- +Model, +Action           (>= threshold states)
      vb_dead_state/2               -- +Model, +State
      vb_predict_fatal/3            -- +Model, +State, +Action    (exact OR generalised)
      vb_partition/5                -- +Model,+State,+Actions,-Safe,-Risky
      vb_rank/4                     -- +Model,+State,+Actions,-Ranked (safe first)
      vb_lookahead_fatal/4          -- :StepModel,+Model,+State,+Action (plan-in-model)
      vb_choose_safe/5              -- :StepModel,+Model,+State,+Actions,-Best
*/

% Declare this module and its verify-before-act interface.
:- module(co_verify, [
    % vb_reset/0: clear the fatality model.
    vb_reset/0,
    % vb_set_threshold/1: set the broadly-fatal generalisation threshold.
    vb_set_threshold/1,
    % vb_threshold/1: read the current threshold.
    vb_threshold/1,
    % vb_note_fatal/3: record a (state, action) transition that ended a run.
    vb_note_fatal/3,
    % vb_note_dead_state/2: record a terminal (dead) state.
    vb_note_dead_state/2,
    % vb_fatal_here/3: the exact recorded-fatal test.
    vb_fatal_here/3,
    % vb_fatal_count/3: how many distinct states an action has been fatal in.
    vb_fatal_count/3,
    % vb_broadly_fatal/2: an action fatal in at least the threshold many states.
    vb_broadly_fatal/2,
    % vb_dead_state/2: a state known to be terminal.
    vb_dead_state/2,
    % vb_predict_fatal/3: the combined predictive check (exact or generalised).
    vb_predict_fatal/3,
    % vb_partition/5: split an action set into safe and predicted-fatal.
    vb_partition/5,
    % vb_rank/4: rank actions safe-first, predicted-fatal last.
    vb_rank/4,
    % vb_lookahead_fatal/4: plan one step in a caller's model and judge it fatal.
    vb_lookahead_fatal/4,
    % vb_choose_safe/5: the best action that neither predicts fatal nor simulates
    % into a dead state, with a least-risky fallback.
    vb_choose_safe/5
]).

% Import list helpers.
:- use_module(library(lists), [member/2, memberchk/2, append/3]).
% Import aggregation for the distinct-state count.
:- use_module(library(aggregate), [aggregate_all/3]).

% The lookahead and choice predicates call a caller-supplied transition model.
:- meta_predicate vb_lookahead_fatal(4, +, +, +).
:- meta_predicate vb_choose_safe(4, +, +, +, -).

% ---------------------------------------------------------------------------
% THE FATALITY MODEL — learned from experience
% ---------------------------------------------------------------------------

% vb_fatal_/3: (Model, State, Action) — a transition observed to end a run.
:- dynamic vb_fatal_/3.
% vb_dead_/2: (Model, State) — a state observed to be terminal (dead).
:- dynamic vb_dead_/2.
% vb_threshold_/1: the broadly-fatal generalisation threshold.
:- dynamic vb_threshold_/1.

% vb_reset: clear the whole fatality model and restore the default threshold.
vb_reset :-
    % Forget every fatal transition.
    retractall(vb_fatal_(_, _, _)),
    % Forget every dead state.
    retractall(vb_dead_(_, _)),
    % Restore the default threshold.
    retractall(vb_threshold_(_)),
    assertz(vb_threshold_(2)).

% vb_set_threshold(+K): set the number of distinct states an action must have been
% fatal in before it is generalised to broadly fatal. K must be a positive integer.
vb_set_threshold(K) :-
    % Only a sensible threshold is accepted.
    integer(K), K >= 1,
    % Replace the stored threshold.
    retractall(vb_threshold_(_)),
    assertz(vb_threshold_(K)).

% vb_threshold(-K): the current threshold, defaulting to two.
vb_threshold(K) :-
    % Read the stored threshold, or default.
    ( vb_threshold_(K0) -> K = K0 ; K = 2 ).

% vb_note_fatal(+Model, +State, +Action): record that taking Action in State ended
% the run. Idempotent — the same transition is stored once.
vb_note_fatal(Model, State, Action) :-
    % Store it unless already known.
    ( vb_fatal_(Model, State, Action) -> true
    ; assertz(vb_fatal_(Model, State, Action)) ).

% vb_note_dead_state(+Model, +State): record that State is terminal (a run ended in
% it). Idempotent.
vb_note_dead_state(Model, State) :-
    % Store it unless already known.
    ( vb_dead_(Model, State) -> true
    ; assertz(vb_dead_(Model, State)) ).

% ---------------------------------------------------------------------------
% PREDICTION — exact memory and the generalisation beyond it
% ---------------------------------------------------------------------------

% vb_fatal_here(+Model, +State, +Action): the exact recorded-fatal test — this
% move has ended a run from this very state before.
vb_fatal_here(Model, State, Action) :-
    % A recorded fatal transition matches exactly.
    vb_fatal_(Model, State, Action).

% vb_fatal_count(+Model, +Action, -Count): how many DISTINCT states this action has
% ended a run in — the evidence that it is fatal as a kind of move, not just here.
vb_fatal_count(Model, Action, Count) :-
    % Count the distinct states.
    aggregate_all(count, distinct_fatal_state(Model, Action, _), Count).

% distinct_fatal_state(+Model, +Action, -State): one distinct fatal state (setof
% over the states this action was fatal in).
distinct_fatal_state(Model, Action, State) :-
    % The distinct states, enumerated one at a time.
    setof(S, vb_fatal_(Model, S, Action), States),
    % Yield each.
    member(State, States).

% vb_broadly_fatal(+Model, +Action): the action has ended a run in at least the
% threshold many distinct states, so it is judged fatal as a kind of move.
vb_broadly_fatal(Model, Action) :-
    % The generalisation threshold.
    vb_threshold(K),
    % The distinct-state count.
    vb_fatal_count(Model, Action, Count),
    % Enough distinct deaths to generalise.
    Count >= K.

% vb_dead_state(+Model, +State): a state known to be terminal.
vb_dead_state(Model, State) :-
    % A recorded dead state.
    vb_dead_(Model, State).

% vb_predict_fatal(+Model, +State, +Action): the combined predictive check — the
% action is predicted fatal in this state if it has ended a run from this exact
% state, OR it is broadly fatal (has killed in enough distinct states to
% generalise). This is the "verify before act" judgement.
vb_predict_fatal(Model, State, Action) :-
    % Exact memory of a death here.
    ( vb_fatal_here(Model, State, Action)
    % Or a generalisation from deaths elsewhere.
    ; vb_broadly_fatal(Model, Action)
    ),
    % One witness suffices.
    !.

% ---------------------------------------------------------------------------
% RANKING — deprioritise, do not forbid
% ---------------------------------------------------------------------------

% vb_partition(+Model, +State, +Actions, -Safe, -Risky): split the action set into
% those not predicted fatal and those predicted fatal, each keeping input order.
vb_partition(_, _, [], [], []).
vb_partition(Model, State, [A | As], Safe, Risky) :-
    % Recurse on the rest.
    vb_partition(Model, State, As, Safe0, Risky0),
    % Place this action by the prediction.
    ( vb_predict_fatal(Model, State, A)
    ->  Safe = Safe0, Risky = [A | Risky0]
    ;   Safe = [A | Safe0], Risky = Risky0
    ).

% vb_rank(+Model, +State, +Actions, -Ranked): the actions with the safe ones first
% (in their original order) and the predicted-fatal ones last. Nothing is dropped,
% so if every option is risky the least-bad is still reachable.
vb_rank(Model, State, Actions, Ranked) :-
    % Split, then concatenate safe ahead of risky.
    vb_partition(Model, State, Actions, Safe, Risky),
    append(Safe, Risky, Ranked).

% ---------------------------------------------------------------------------
% PLAN IN THE MODEL — simulate a step before spending a real action
% ---------------------------------------------------------------------------

% vb_lookahead_fatal(:StepModel, +Model, +State, +Action): simulate taking Action
% in State using the caller's transition model, and succeed if the move is fatal —
% either predicted fatal outright, or it leads (in the model) to a state already
% known to be dead. StepModel(State, Action, NextState) is the caller's model.
vb_lookahead_fatal(StepModel, Model, State, Action) :-
    % The action is fatal outright by prediction, or...
    ( vb_predict_fatal(Model, State, Action)
    -> true
    % ...simulating it lands in a state already known to be dead.
    ;  call(StepModel, State, Action, NextState),
       vb_dead_state(Model, NextState)
    ).

% vb_choose_safe(:StepModel, +Model, +State, +Actions, -Best): the first action
% that neither predicts fatal nor, in the model, leads into a dead state. If every
% action looks fatal, fall back to the least-risky by the safe-first ranking, so
% the caller always gets a choice rather than stalling.
vb_choose_safe(StepModel, Model, State, Actions, Best) :-
    % There must be something to choose.
    Actions \== [],
    % Prefer an action that survives the lookahead.
    (   member(Best, Actions),
        \+ vb_lookahead_fatal(StepModel, Model, State, Best)
    ->  true
    % Otherwise take the least-risky (safe-first) action.
    ;   vb_rank(Model, State, Actions, [Best | _])
    ).
