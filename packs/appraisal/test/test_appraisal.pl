/*  PrologAI — Staged Appraisal and Coping (EMA) Test Suite  (PR 26)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/appraisal/test/test_appraisal.pl
*/

% Declare this file as a test module.
:- module(test_appraisal, []).
% Load the PLUnit framework.
:- use_module(library(plunit)).
% Load the module under test.
:- use_module(library(appraisal)).

% Reset the appraisal pack's internal dynamic state to a clean slate.
appraisal_test_reset :-
    % Drop every remembered causal event.
    retractall(appraisal:causal_event(_, _, _, _)),
    % Drop every remembered causal link.
    retractall(appraisal:causal_link(_, _)),
    % Drop every recorded appraisal (emotion intensity) row.
    retractall(appraisal:appraisal_record(_, _, _, _, _)),
    % Drop the event-id counter.
    retractall(appraisal:event_id_counter(_)),
    % Restart the event-id counter at zero.
    assertz(appraisal:event_id_counter(0)).

% Open the test block.
:- begin_tests(appraisal).

% appraisal_causal_model asserts a fresh event into the causal interpretation.
test(causal_model_asserts_event) :-
    % Start from a clean internal state.
    appraisal_test_reset,
    % Register a past event with a high likelihood.
    appraisal_causal_model(event(past, some_happened, 0.9)),
    % The event is now recorded with its type and likelihood.
    assertion(once(appraisal:causal_event(_, past, some_happened, 0.9))).

% A desirable future event attributed to self is highly controllable.
test(future_self_high_controllability) :-
    % Start from a clean internal state.
    appraisal_test_reset,
    % Register a future event the agent hopes to bring about.
    appraisal_causal_model(event(future, desired_outcome, 0.8)),
    % Appraise it against a positive goal for that outcome.
    once(appraisal_appraise(desired_outcome, [goal(desired_outcome, positive)], Appraisal)),
    % The appraisal attributes the future event to self.
    Appraisal = appraisal(desired_outcome, Des, _Lik, self, Ctrl, _Int),
    % A matched positive goal yields desirability +1.
    assertion(Des =:= 1.0),
    % Self-attributed future events carry controllability 0.8.
    assertion(Ctrl =:= 0.8).

% High controllability drives problem-focused coping (plan to change the world).
test(high_controllability_problem_focused) :-
    % Start from a clean internal state.
    appraisal_test_reset,
    % Register a controllable future goal.
    appraisal_causal_model(event(future, future_goal, 0.7)),
    % Appraise it against a positive goal.
    once(appraisal_appraise(future_goal, [goal(future_goal, positive)], Appraisal)),
    % Controllability clears the 0.5 threshold.
    Appraisal = appraisal(future_goal, _, _, self, C, _),
    % Confirm the appraisal is on the controllable side of the threshold.
    assertion(C >= 0.5),
    % Coping therefore selects a problem-focused strategy.
    once(appraisal_cope_select(Appraisal, [], CopingStrategy)),
    % The strategy is a concrete plan action for the event.
    assertion(CopingStrategy == problem_focused(plan_action(future_goal))).

% A blocked past goal has low controllability, forcing emotion-focused coping.
test(low_controllability_emotion_focused) :-
    % Start from a clean internal state.
    appraisal_test_reset,
    % Register a past (already-happened, uncontrollable) blocked goal.
    appraisal_causal_model(event(past, blocked_goal, 0.9)),
    % Appraise it against a negative goal.
    once(appraisal_appraise(blocked_goal, [goal(blocked_goal, negative)], Appraisal)),
    % Past events sit below the controllability threshold.
    Appraisal = appraisal(blocked_goal, _, _, _, C, _),
    % Confirm the appraisal is on the uncontrollable side of the threshold.
    assertion(C < 0.5),
    % Coping therefore selects an emotion-focused strategy.
    once(appraisal_cope_select(Appraisal, [], CopingStrategy)),
    % The strategy is a re-appraisal rather than a new plan.
    assertion(CopingStrategy = emotion_focused(_)).

% A safety-critical negative event is re-weighted, never denied.
test(safety_critical_adjust_not_deny) :-
    % A negative, other-caused, low-controllability appraisal.
    Appraisal = appraisal(critical_event, -0.9, 0.95, other, 0.2, 0.855),
    % Cope with the safety-critical flag set for that event.
    once(appraisal_cope_select(Appraisal, [safety_critical(critical_event)], Strategy)),
    % Coping adjusts the desirability magnitude but keeps the event.
    Strategy = emotion_focused(adjust_desirability(critical_event, NewD)),
    % The re-weighted desirability is the original scaled by 0.7.
    assertion(abs(NewD - (-0.63)) < 1.0e-9).

% Appraisal variables map to OCC-style emotion labels by sign and attribution.
test(emotion_mapping_by_sign_and_attribution) :-
    % Negative desirability attributed to self reads as shame.
    once(appraisal_emotion_from_appraisal(appraisal(my_mistake, -1.0, 0.9, self, 0.2, 0.9), E1)),
    % Confirm the shame label with its intensity.
    assertion(E1 = shame(_)),
    % Negative desirability attributed to another reads as anger.
    once(appraisal_emotion_from_appraisal(appraisal(others_act, -0.8, 0.7, other, 0.2, 0.56), E2)),
    % Confirm the anger label.
    assertion(E2 = anger(_)),
    % Positive desirability attributed to self reads as pride.
    once(appraisal_emotion_from_appraisal(appraisal(my_win, 1.0, 0.8, self, 0.8, 0.8), E3)),
    % Confirm the pride label carries the appraisal intensity.
    assertion(E3 == pride(0.8)).

% appraisal_appraisal_decay lowers recorded emotion intensity on each tick.
test(appraisal_intensity_decays) :-
    % Start from a clean internal state.
    appraisal_test_reset,
    % Register an emotionally loaded past event.
    appraisal_causal_model(event(past, decay_event, 1.0)),
    % Appraise it against a negative goal so an intensity is recorded.
    once(appraisal_appraise(decay_event, [goal(decay_event, negative)], Appraisal)),
    % The initial intensity is strictly positive.
    Appraisal = appraisal(_, _, _, _, _, I0),
    % Confirm there is a non-zero intensity to decay.
    assertion(I0 > 0.0),
    % Advance one decay tick.
    appraisal_appraisal_decay,
    % Read back the single recorded intensity after the tick.
    once(appraisal:appraisal_record(_, _, _, _, I1)),
    % The intensity has strictly decreased.
    assertion(I1 < I0).

% Close the test block.
:- end_tests(appraisal).
