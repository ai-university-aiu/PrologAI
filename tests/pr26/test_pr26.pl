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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/appraisal/prolog'], AppPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, AppPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'appraisal' library so its predicates are available here.
:- use_module(library(appraisal), [
    % Supply 'pai_causal_model/1' as the next argument to the expression above.
    pai_causal_model/1,
    % Supply 'pai_appraise/3' as the next argument to the expression above.
    pai_appraise/3,
    % Supply 'pai_cope_select/3' as the next argument to the expression above.
    pai_cope_select/3,
    % Supply 'pai_emotion_from_appraisal/2' as the next argument to the expression above.
    pai_emotion_from_appraisal/2,
    % Supply 'pai_appraisal_decay/0' as the next argument to the expression above.
    pai_appraisal_decay/0
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr26, [setup(pr26_setup), cleanup(pr26_cleanup)]).
:- begin_tests(pr26, [setup(pr26_setup), cleanup(pr26_cleanup)]).

% Execute: pr26_setup :-.
pr26_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(appraisal:causal_event(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(appraisal:causal_link(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(appraisal:appraisal_record(_, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(appraisal:event_id_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(appraisal:event_id_counter(0)).

% Execute: pr26_cleanup :-.
pr26_cleanup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(appraisal:causal_event(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(appraisal:causal_link(_, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(appraisal:appraisal_record(_, _, _, _, _)).

%  AC-PR26-001: blocked objective, low controllability → emotion-focused coping
% Define a clause for 'test': succeed when the following conditions hold.
test(low_controllability_emotion_focused) :-
    % past event (uncontrollable = 0.2 < 0.5)
    % State a fact for 'pai causal model' with the arguments listed below.
    pai_causal_model(event(past, blocked_goal, 0.9)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_appraise(blocked_goal, [goal(blocked_goal, negative)], Appraisal)),
    % Check that 'Appraisal' is unifiable with 'appraisal(blocked_goal, _, _, _, C, _)'.
    Appraisal = appraisal(blocked_goal, _, _, _, C, _),
    % Check that 'C' is less than '0.5'.
    C < 0.5,
    % State a fact for 'once' with the arguments listed below.
    once(pai_cope_select(Appraisal, [], CopingStrategy)),
    % Check that 'CopingStrategy' is unifiable with 'emotion_focused(_)'.
    CopingStrategy = emotion_focused(_).

%  AC-PR26-002: future event + self-attribution → high controllability → problem-focused
% Define a clause for 'test': succeed when the following conditions hold.
test(high_controllability_problem_focused) :-
    % State a fact for 'pai causal model' with the arguments listed below.
    pai_causal_model(event(future, future_goal, 0.7)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_appraise(future_goal, [goal(future_goal, positive)], Appraisal)),
    % Check that 'Appraisal' is unifiable with 'appraisal(future_goal, _, _, self, C, _)'.
    Appraisal = appraisal(future_goal, _, _, self, C, _),
    % Check that 'C' is greater than or equal to '0.5'.
    C >= 0.5,
    % State a fact for 'once' with the arguments listed below.
    once(pai_cope_select(Appraisal, [], CopingStrategy)),
    % Check that 'CopingStrategy' is unifiable with 'problem_focused(_)'.
    CopingStrategy = problem_focused(_).

%  AC-PR26-003: desirable future event attributed to self → controllability = 0.8
% Define a clause for 'test': succeed when the following conditions hold.
test(future_self_high_controllability) :-
    % State a fact for 'pai causal model' with the arguments listed below.
    pai_causal_model(event(future, desired_outcome, 0.8)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_appraise(desired_outcome, [goal(desired_outcome, positive)], Appraisal)),
    % Check that 'Appraisal' is unifiable with 'appraisal(_, _, _, self, Ctrl, _)'.
    Appraisal = appraisal(_, _, _, self, Ctrl, _),
    % Check that 'Ctrl' is numerically equal to '0.8'.
    Ctrl =:= 0.8.

%  AC-PR26-004: negative desirability + self attribution → shame
% Define a clause for 'test': succeed when the following conditions hold.
test(shame_for_negative_self) :-
    % Check that 'Appraisal' is unifiable with 'appraisal(my_mistake, -1.0, 0.9, self, 0.2, 0.9)'.
    Appraisal = appraisal(my_mistake, -1.0, 0.9, self, 0.2, 0.9),
    % State a fact for 'once' with the arguments listed below.
    once(pai_emotion_from_appraisal(Appraisal, Emotion)),
    % Check that 'Emotion' is unifiable with 'shame(_)'.
    Emotion = shame(_).

%  AC-PR26-005: negative desirability + other attribution → anger
% Define a clause for 'test': succeed when the following conditions hold.
test(anger_for_negative_other) :-
    % Check that 'Appraisal' is unifiable with 'appraisal(others_act, -0.8, 0.7, other, 0.2, 0.56)'.
    Appraisal = appraisal(others_act, -0.8, 0.7, other, 0.2, 0.56),
    % State a fact for 'once' with the arguments listed below.
    once(pai_emotion_from_appraisal(Appraisal, Emotion)),
    % Check that 'Emotion' is unifiable with 'anger(_)'.
    Emotion = anger(_).

%  AC-PR26-006: intensity decays after a tick
% Define a clause for 'test': succeed when the following conditions hold.
test(appraisal_intensity_decays) :-
    % State a fact for 'pai causal model' with the arguments listed below.
    pai_causal_model(event(past, decay_event, 1.0)),
    % State a fact for 'once' with the arguments listed below.
    once(pai_appraise(decay_event, [goal(decay_event, negative)], Appraisal)),
    % Check that 'Appraisal' is unifiable with 'appraisal(_, _, _, _, _, I0)'.
    Appraisal = appraisal(_, _, _, _, _, I0),
    % Check that 'I0' is greater than '0.0'.
    I0 > 0.0,
    % Call the goal 'pai_appraisal_decay'.
    pai_appraisal_decay,
    % State a fact for 'once' with the arguments listed below.
    once(appraisal:appraisal_record(_, _, _, _, I1)),
    % Check that 'I1' is less than 'I0'.
    I1 < I0.

%  AC-PR26-007: safety_critical → adjust_desirability, not denial
% Define a clause for 'test': succeed when the following conditions hold.
test(safety_critical_adjust_not_deny) :-
    % Check that 'Appraisal' is unifiable with 'appraisal(critical_event, -0.9, 0.95, other, 0.2, 0.855)'.
    Appraisal = appraisal(critical_event, -0.9, 0.95, other, 0.2, 0.855),
    % State a fact for 'once' with the arguments listed below.
    once(pai_cope_select(Appraisal, [safety_critical(critical_event)], Strategy)),
    % Check that 'Strategy' is unifiable with 'emotion_focused(adjust_desirability(critical_event, _NewD))'.
    Strategy = emotion_focused(adjust_desirability(critical_event, _NewD)).

%  AC-PR26-008: pai_causal_model asserts into causal interpretation
% Define a clause for 'test': succeed when the following conditions hold.
test(causal_model_asserts_event) :-
    % State a fact for 'pai causal model' with the arguments listed below.
    pai_causal_model(event(past, some_happened, 0.9)),
    % State the fact: once(appraisal:causal_event(_, past, some_happened, 0.9)).
    once(appraisal:causal_event(_, past, some_happened, 0.9)).

%  AC-PR26-009: unknown event (no matching goal) → desirability = 0.0
% Define a clause for 'test': succeed when the following conditions hold.
test(unknown_event_neutral_desirability) :-
    % State a fact for 'once' with the arguments listed below.
    once(pai_appraise(completely_unknown_event_xyz, [], Appraisal)),
    % Check that 'Appraisal' is unifiable with 'appraisal(_, D, _, _, _, _)'.
    Appraisal = appraisal(_, D, _, _, _, _),
    % Check that 'D' is numerically equal to '0.0'.
    D =:= 0.0.

% Execute the compile-time directive: end_tests(pr26).
:- end_tests(pr26).
