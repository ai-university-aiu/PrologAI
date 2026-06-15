/*  PrologAI — PR 26 Staged Appraisal and Coping (EMA) Acceptance Tests

    AC-PR26-001: Given a blocked objective with low controllability, when
                 coping runs, an emotion-focused strategy is applied and
                 desirability/priority is adjusted (not a new plan).
    AC-PR26-002: High controllability → problem-focused coping.
    AC-PR26-003: Desirable future event attributed to self → high controllability.
    AC-PR26-004: pai_emotion_from_appraisal maps negative+self → shame.
    AC-PR26-005: pai_emotion_from_appraisal maps negative+other → anger.
    AC-PR26-006: pai_appraisal_decay reduces intensity over ticks.
    AC-PR26-007: safety_critical event gets desirability adjusted, not denied.
    AC-PR26-008: pai_causal_model asserts an event into the causal model.
    AC-PR26-009: Unknown event (no goal match) has desirability = 0.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/appraisal/prolog'], AppPath),
   assertz(file_search_path(library, AppPath)).

:- use_module(library(plunit)).
:- use_module(library(appraisal), [
    pai_causal_model/1,
    pai_appraise/3,
    pai_cope_select/3,
    pai_emotion_from_appraisal/2,
    pai_appraisal_decay/0
]).

:- begin_tests(pr26, [setup(pr26_setup), cleanup(pr26_cleanup)]).

pr26_setup :-
    retractall(appraisal:causal_event(_, _, _, _)),
    retractall(appraisal:causal_link(_, _)),
    retractall(appraisal:appraisal_record(_, _, _, _, _)),
    retractall(appraisal:event_id_counter(_)),
    assertz(appraisal:event_id_counter(0)).

pr26_cleanup :-
    retractall(appraisal:causal_event(_, _, _, _)),
    retractall(appraisal:causal_link(_, _)),
    retractall(appraisal:appraisal_record(_, _, _, _, _)).

%  AC-PR26-001: blocked objective, low controllability → emotion-focused coping
test(low_controllability_emotion_focused) :-
    % past event (uncontrollable = 0.2 < 0.5)
    pai_causal_model(event(past, blocked_goal, 0.9)),
    once(pai_appraise(blocked_goal, [goal(blocked_goal, negative)], Appraisal)),
    Appraisal = appraisal(blocked_goal, _, _, _, C, _),
    C < 0.5,
    once(pai_cope_select(Appraisal, [], CopingStrategy)),
    CopingStrategy = emotion_focused(_).

%  AC-PR26-002: future event + self-attribution → high controllability → problem-focused
test(high_controllability_problem_focused) :-
    pai_causal_model(event(future, future_goal, 0.7)),
    once(pai_appraise(future_goal, [goal(future_goal, positive)], Appraisal)),
    Appraisal = appraisal(future_goal, _, _, self, C, _),
    C >= 0.5,
    once(pai_cope_select(Appraisal, [], CopingStrategy)),
    CopingStrategy = problem_focused(_).

%  AC-PR26-003: desirable future event attributed to self → controllability = 0.8
test(future_self_high_controllability) :-
    pai_causal_model(event(future, desired_outcome, 0.8)),
    once(pai_appraise(desired_outcome, [goal(desired_outcome, positive)], Appraisal)),
    Appraisal = appraisal(_, _, _, self, Ctrl, _),
    Ctrl =:= 0.8.

%  AC-PR26-004: negative desirability + self attribution → shame
test(shame_for_negative_self) :-
    Appraisal = appraisal(my_mistake, -1.0, 0.9, self, 0.2, 0.9),
    once(pai_emotion_from_appraisal(Appraisal, Emotion)),
    Emotion = shame(_).

%  AC-PR26-005: negative desirability + other attribution → anger
test(anger_for_negative_other) :-
    Appraisal = appraisal(others_act, -0.8, 0.7, other, 0.2, 0.56),
    once(pai_emotion_from_appraisal(Appraisal, Emotion)),
    Emotion = anger(_).

%  AC-PR26-006: intensity decays after a tick
test(appraisal_intensity_decays) :-
    pai_causal_model(event(past, decay_event, 1.0)),
    once(pai_appraise(decay_event, [goal(decay_event, negative)], Appraisal)),
    Appraisal = appraisal(_, _, _, _, _, I0),
    I0 > 0.0,
    pai_appraisal_decay,
    once(appraisal:appraisal_record(_, _, _, _, I1)),
    I1 < I0.

%  AC-PR26-007: safety_critical → adjust_desirability, not denial
test(safety_critical_adjust_not_deny) :-
    Appraisal = appraisal(critical_event, -0.9, 0.95, other, 0.2, 0.855),
    once(pai_cope_select(Appraisal, [safety_critical(critical_event)], Strategy)),
    Strategy = emotion_focused(adjust_desirability(critical_event, _NewD)).

%  AC-PR26-008: pai_causal_model asserts into causal interpretation
test(causal_model_asserts_event) :-
    pai_causal_model(event(past, some_happened, 0.9)),
    once(appraisal:causal_event(_, past, some_happened, 0.9)).

%  AC-PR26-009: unknown event (no matching goal) → desirability = 0.0
test(unknown_event_neutral_desirability) :-
    once(pai_appraise(completely_unknown_event_xyz, [], Appraisal)),
    Appraisal = appraisal(_, D, _, _, _, _),
    D =:= 0.0.

:- end_tests(pr26).
