/*  PrologAI — Causalontology World Model  (WP-407, Layer 382)

    The single architecture the ARC-AGI-3 winners share is an EXECUTABLE world
    model: a runnable description of the environment's dynamics that the agent
    learns from observed transitions, VERIFIES against the history, REPAIRS when a
    prediction is contradicted, and PLANS INSIDE by rolling forward candidate action
    sequences — so it pays real actions only to test the model, not to grope. This
    pack is that model, built the Causalontology way: from observed cause-effect,
    with a simplicity bias toward the most general law that fits.

    A transition is keyed by a state CONTEXT and an ACTION and maps to an EFFECT.
    The context is whatever coarse feature the caller thinks matters (a colour under
    the avatar, a mode flag, or the atom `any` when the effect looks context-free).
    The model tallies how often each effect followed each (context, action), so
    prediction is the majority effect and confidence is its share. Because a good
    law is usually context-free, wm_predict falls back from the specific context to
    the action-general rule, and wm_law surfaces the actions whose effect is the
    same everywhere — the compressed, transferable core of the model.

    Predicates:
      wm_reset/0                    forget the model
      wm_observe/4                  -- +Model, +Context, +Action, +Effect
      wm_predict/4                  -- +Model, +Context, +Action, -Effect
      wm_predict/5                  -- +Model, +Context, +Action, -Effect, -Confidence
      wm_known/3                    -- +Model, +Context, +Action  (any observation?)
      wm_verify/5                   -- +Model, +Context, +Action, +Observed, -Result
      wm_repair/4                   -- +Model, +Context, +Action, +Observed
      wm_rollout/4                  -- +Model, +Context, +ActionSeq, -PredictedEffects
      wm_law/3                      -- +Model, ?Action, ?Effect   (context-free laws)
      wm_stats/2                    -- +Model, -stats(Contexts, Transitions)
*/

% Declare this module and its world-model interface.
:- module(co_wm, [
    % wm_reset/0: forget the whole model.
    wm_reset/0,
    % wm_observe/4: record one observed transition.
    wm_observe/4,
    % wm_predict/4: the predicted effect of an action in a context.
    wm_predict/4,
    % wm_predict/5: the predicted effect and the model's confidence in it.
    wm_predict/5,
    % wm_known/3: whether the model has ever seen this (context, action).
    wm_known/3,
    % wm_verify/5: compare a prediction with what was observed.
    wm_verify/5,
    % wm_repair/4: fold a contradicting observation into the model.
    wm_repair/4,
    % wm_rollout/4: predict the effects of an action sequence (plan-in-model).
    wm_rollout/4,
    % wm_law/3: an action whose effect is context-free — a general law.
    wm_law/3,
    % wm_stats/2: a summary of the model.
    wm_stats/2,
    % wm_snapshot/2: the model's learned transitions for a model, for persistence.
    wm_snapshot/2,
    % wm_restore/2: reload a model's learned transitions from a snapshot.
    wm_restore/2
]).

% List and aggregate helpers.
:- use_module(library(lists), [member/2, max_member/2]).
:- use_module(library(aggregate), [aggregate_all/3]).

% ---------------------------------------------------------------------------
% STATE
% ---------------------------------------------------------------------------

% wm_obs_/5: (Model, Context, Action, Effect, Count) — how often Effect followed
% Action in Context.
:- dynamic wm_obs_/5.

% wm_reset: forget the whole model.
wm_reset :- retractall(wm_obs_(_, _, _, _, _)).

% wm_observe(+Model, +Context, +Action, +Effect): record one observed transition,
% incrementing its tally.
wm_observe(Model, Context, Action, Effect) :-
    ( retract(wm_obs_(Model, Context, Action, Effect, N)) -> true ; N = 0 ),
    N1 is N + 1,
    assertz(wm_obs_(Model, Context, Action, Effect, N1)).

% ---------------------------------------------------------------------------
% PREDICTION — the majority effect, with a fall-back to the general law
% ---------------------------------------------------------------------------

% wm_predict(+Model, +Context, +Action, -Effect): the predicted effect.
wm_predict(Model, Context, Action, Effect) :-
    wm_predict(Model, Context, Action, Effect, _Conf).

% wm_predict(+Model, +Context, +Action, -Effect, -Confidence): the effect the model
% expects and how strongly. It first uses transitions seen in exactly this context;
% if the context has never been observed with this action, it falls back to the
% action-general rule aggregated over every context (the simplicity bias — a law
% that holds regardless of context is preferred and is what transfers).
wm_predict(Model, Context, Action, Effect, Confidence) :-
    (   wm_obs_(Model, Context, Action, _, _)
    % Context-specific prediction.
    ->  wm_majority(Model, Context, Action, Effect, Confidence)
    % No data for this context: the action-general rule over all contexts.
    ;   wm_majority(Model, any_context, Action, Effect, Confidence)
    ).

% wm_majority(+Model, +Scope, +Action, -Effect, -Confidence): the most-frequent
% effect and its share. Scope is a specific context, or any_context to aggregate
% across every context the action was seen in.
wm_majority(Model, Scope, Action, Effect, Confidence) :-
    % Total effect-counts for the scope.
    findall(Count - Eff, wm_scope_count(Model, Scope, Action, Eff, Count), Pairs),
    Pairs \== [],
    % The total number of observations.
    aggregate_all(sum(N), member(N - _, Pairs), Total),
    Total > 0,
    % The most frequent effect.
    max_member(Best - Effect, Pairs),
    % Its share of the observations.
    Confidence is Best / Total.

% wm_scope_count(+Model, +Scope, +Action, -Effect, -Count): effect counts within a
% scope. A specific context reads its own tallies; any_context sums across contexts.
wm_scope_count(Model, any_context, Action, Effect, Count) :-
    !,
    % Distinct effects for the action anywhere.
    setof(E, Cx^N^wm_obs_(Model, Cx, Action, E, N), Effects),
    member(Effect, Effects),
    aggregate_all(sum(N), wm_obs_(Model, _, Action, Effect, N), Count).
wm_scope_count(Model, Context, Action, Effect, Count) :-
    wm_obs_(Model, Context, Action, Effect, Count).

% wm_known(+Model, +Context, +Action): the model has seen this action in this exact
% context, or (fall-back) anywhere.
wm_known(Model, Context, Action) :-
    ( wm_obs_(Model, Context, Action, _, _) -> true
    ; wm_obs_(Model, _, Action, _, _) ).

% ---------------------------------------------------------------------------
% VERIFICATION AND REPAIR — the loop that keeps the model honest
% ---------------------------------------------------------------------------

% wm_verify(+Model, +Context, +Action, +Observed, -Result): compare what the model
% predicted with what actually happened. Result is match, mismatch(Predicted,
% Observed), or novel when the model had no prediction to test.
wm_verify(Model, Context, Action, Observed, Result) :-
    (   wm_predict(Model, Context, Action, Predicted, _)
    ->  ( Predicted == Observed -> Result = match
        ; Result = mismatch(Predicted, Observed) )
    ;   Result = novel
    ).

% wm_repair(+Model, +Context, +Action, +Observed): fold a (possibly contradicting)
% observation into the model. Prediction self-corrects as the majority shifts, so
% repair is simply recording the truth — the model is never argued with, only
% shown more evidence.
wm_repair(Model, Context, Action, Observed) :-
    wm_observe(Model, Context, Action, Observed).

% ---------------------------------------------------------------------------
% PLAN IN THE MODEL — roll a candidate sequence forward before acting
% ---------------------------------------------------------------------------

% wm_rollout(+Model, +Context, +ActionSeq, -PredictedEffects): predict the effect of
% each action in a sequence, so a caller can score a plan inside the model without
% spending real actions. The context is held fixed across the rollout unless the
% caller threads a changing one; each step predicts under the current context.
wm_rollout(_, _, [], []).
wm_rollout(Model, Context, [Action | As], [Effect | Es]) :-
    ( wm_predict(Model, Context, Action, Effect, _) -> true ; Effect = unknown ),
    wm_rollout(Model, Context, As, Es).

% ---------------------------------------------------------------------------
% LAWS — the compressed, transferable core (simplicity / MDL)
% ---------------------------------------------------------------------------

% wm_law(+Model, ?Action, ?Effect): an action whose effect is context-free — the
% SAME majority effect was observed in every context it appeared in, with no
% contradicting effect. These are the general laws worth transferring to a new
% level or a new game, the minimum-description-length core of the model.
wm_law(Model, Action, Effect) :-
    % An action the model has seen.
    setof(A, Cx^E^N^wm_obs_(Model, Cx, A, E, N), Actions),
    member(Action, Actions),
    % The distinct effects ever seen for it.
    setof(E, Cx^N^wm_obs_(Model, Cx, Action, E, N), Effects),
    % A law holds only when exactly one effect was ever observed.
    Effects = [Effect].

% ---------------------------------------------------------------------------
% SUMMARY
% ---------------------------------------------------------------------------

% wm_stats(+Model, -stats(Contexts, Transitions)): how many distinct contexts and
% (context, action, effect) transitions the model holds.
wm_stats(Model, stats(Contexts, Transitions)) :-
    ( setof(Cx, A^E^N^wm_obs_(Model, Cx, A, E, N), Cs) -> length(Cs, Contexts) ; Contexts = 0 ),
    aggregate_all(count, wm_obs_(Model, _, _, _, _), Transitions).

% ---------------------------------------------------------------------------
% PERSISTENCE — snapshot the learned model out, and restore it back in
% ---------------------------------------------------------------------------

% wm_snapshot(+Model, -Obs): the model's learned transitions as a ground list of
% obs(Context, Action, Effect, Count) terms — a serialisable copy of everything the
% model has learned for this Model, so a caller can write it to disk and later
% restore it. Empty list when the model holds nothing.
wm_snapshot(Model, Obs) :-
    findall(obs(Context, Action, Effect, Count),
        wm_obs_(Model, Context, Action, Effect, Count),
        Obs).

% wm_restore(+Model, +Obs): replace this Model's transitions with the snapshot. The
% Model's existing observations are dropped first so restore is idempotent (loading
% the same snapshot twice yields the same model, not doubled counts).
wm_restore(Model, Obs) :-
    retractall(wm_obs_(Model, _, _, _, _)),
    forall(member(obs(Context, Action, Effect, Count), Obs),
        assertz(wm_obs_(Model, Context, Action, Effect, Count))).
