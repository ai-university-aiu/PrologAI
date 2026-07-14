/*  PrologAI — Concept Workspace (J-Space) Pack Test Suite  (WP-388)

    Acceptance tests for all jacobian_space_* predicates, including the silent-
    thought detection and ablation-breaks-derivation behaviours that
    mirror the 2026 J-Lens interpretability findings.

    Run with:
        swipl -g "run_tests, halt" test_jspace.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/jacobian_space').

% ===========================================================================
% HOLDING, READING, AND EDITING
% ===========================================================================

:- begin_tests(jspace_ledger).

% The reading ranks held concepts by strength, strongest first.
test(reading_ranked) :-
    % A fresh workspace.
    jacobian_space_open(t_read),
    % Hold three concepts at different strengths.
    jacobian_space_hold(t_read, weak, 0.2, percept),
    % The strongest concept.
    jacobian_space_hold(t_read, strong, 0.9, percept),
    % A middle concept.
    jacobian_space_hold(t_read, mid, 0.5, inference),
    % Take the J-Lens readout.
    jacobian_space_reading(t_read, Reading),
    % The ranking is strongest first.
    Reading == [strong-0.9, mid-0.5, weak-0.2].

% Re-holding a concept updates it in place without duplication.
test(hold_upserts) :-
    % A fresh workspace.
    jacobian_space_open(t_upsert),
    % Hold a concept once.
    jacobian_space_hold(t_upsert, idea, 0.3, percept),
    % Hold the same concept again at a new strength.
    jacobian_space_hold(t_upsert, idea, 0.8, inference),
    % Take the readout.
    jacobian_space_reading(t_upsert, Reading),
    % Exactly one entry remains, at the new strength.
    Reading == [idea-0.8].

% Strength and source read back what was held.
test(strength_and_source) :-
    % A fresh workspace.
    jacobian_space_open(t_ss),
    % Hold one concept.
    jacobian_space_hold(t_ss, cat, 0.7, percept),
    % Read the strength back.
    jacobian_space_strength(t_ss, cat, S),
    % Check the strength.
    S =:= 0.7,
    % Read the source back.
    jacobian_space_source(t_ss, cat, Src),
    % Check the source.
    Src == percept.

% Reading a concept that is not held fails honestly.
test(strength_absent_fails, [fail]) :-
    % A fresh workspace.
    jacobian_space_open(t_absent),
    % Nothing was held, so nothing can be read.
    jacobian_space_strength(t_absent, ghost, _).

% A negative strength is rejected.
test(negative_strength_rejected, [fail]) :-
    % A fresh workspace.
    jacobian_space_open(t_neg),
    % Strengths must be non-negative.
    jacobian_space_hold(t_neg, bad, -0.5, percept).

% Zero-strength concepts are held but not active.
test(active_excludes_zero) :-
    % A fresh workspace.
    jacobian_space_open(t_active),
    % A live concept.
    jacobian_space_hold(t_active, alive, 0.4, percept),
    % A held but fully faded concept.
    jacobian_space_hold(t_active, faded, 0.0, percept),
    % Ask for the active set.
    jacobian_space_active(t_active, Active),
    % Only the live concept qualifies.
    Active == [alive].

% The monitor reports presence with strength, or absence.
test(monitor) :-
    % A fresh workspace.
    jacobian_space_open(t_mon),
    % Hold one concept.
    jacobian_space_hold(t_mon, watched, 0.6, implant),
    % The held concept is present.
    jacobian_space_monitor(t_mon, watched, present(S)),
    % Check the reported strength.
    S =:= 0.6,
    % An unheld concept is absent.
    jacobian_space_monitor(t_mon, unheld, absent).

% Swapping two concepts exchanges their strengths and flips the ranking.
test(swap_flips_ranking) :-
    % A fresh workspace.
    jacobian_space_open(t_swap),
    % The initially stronger concept.
    jacobian_space_hold(t_swap, first, 0.9, percept),
    % The initially weaker concept.
    jacobian_space_hold(t_swap, second, 0.1, percept),
    % Exchange their strengths.
    jacobian_space_swap(t_swap, first, second),
    % Take the readout.
    jacobian_space_reading(t_swap, Reading),
    % The system now reports thinking the other thought first.
    Reading == [second-0.9, first-0.1].

% Boosting raises a strength; the floor at zero holds.
test(boost_and_floor) :-
    % A fresh workspace.
    jacobian_space_open(t_boost),
    % Hold one concept.
    jacobian_space_hold(t_boost, idea, 0.5, percept),
    % Boost it upward.
    jacobian_space_boost(t_boost, idea, 0.3),
    % Read the raised strength.
    jacobian_space_strength(t_boost, idea, Up),
    % Check the raise.
    abs(Up - 0.8) < 1.0e-9,
    % Push it far below zero.
    jacobian_space_boost(t_boost, idea, -5.0),
    % Read the floored strength.
    jacobian_space_strength(t_boost, idea, Floor),
    % The floor held.
    Floor =:= 0.0.

% Decay scales every strength and drops the negligible.
test(decay) :-
    % A fresh workspace.
    jacobian_space_open(t_decay),
    % A robust concept.
    jacobian_space_hold(t_decay, robust, 0.8, percept),
    % A concept already at the edge of vanishing.
    jacobian_space_hold(t_decay, tiny, 1.0e-6, percept),
    % Halve every activation.
    jacobian_space_decay(t_decay, 0.5),
    % The robust concept survived at half strength.
    jacobian_space_strength(t_decay, robust, S),
    % Check the halving.
    abs(S - 0.4) < 1.0e-9,
    % The tiny concept fell out of the workspace.
    jacobian_space_monitor(t_decay, tiny, absent).

% Capacity keeps only the strongest N concepts — a sparse workspace.
test(capacity) :-
    % A fresh workspace.
    jacobian_space_open(t_cap),
    % Hold five concepts at graded strengths.
    jacobian_space_hold(t_cap, a, 0.9, percept),
    % Second strongest.
    jacobian_space_hold(t_cap, b, 0.7, percept),
    % Third strongest.
    jacobian_space_hold(t_cap, c, 0.5, percept),
    % Fourth strongest.
    jacobian_space_hold(t_cap, d, 0.3, percept),
    % Weakest.
    jacobian_space_hold(t_cap, e, 0.1, percept),
    % Enforce a capacity of three.
    jacobian_space_capacity(t_cap, 3),
    % Ask for the surviving active set.
    jacobian_space_active(t_cap, Active),
    % Only the strongest three remain.
    Active == [a, b, c].

% Workspaces are isolated from each other.
test(spaces_isolated) :-
    % Two fresh workspaces.
    jacobian_space_open(t_iso_a),
    % The second workspace.
    jacobian_space_open(t_iso_b),
    % Hold a concept in the first only.
    jacobian_space_hold(t_iso_a, private, 0.5, percept),
    % The second workspace never saw it.
    jacobian_space_monitor(t_iso_b, private, absent).

:- end_tests(jspace_ledger).

% ===========================================================================
% SILENT THOUGHTS AND VERBALIZATION
% ===========================================================================

:- begin_tests(jspace_silent).

% Silent detection: a concept held in mind but never spoken is revealed.
test(silent_thought_detected) :-
    % A fresh workspace.
    jacobian_space_open(t_silent),
    % The system silently notices it is being evaluated.
    jacobian_space_hold(t_silent, being_evaluated, 0.8, inference),
    % It also holds the concept it is about to speak about.
    jacobian_space_hold(t_silent, polite_answer, 0.6, inference),
    % Only the answer is verbalized.
    jacobian_space_verbalize(t_silent, polite_answer),
    % Read the silent set.
    jacobian_space_silent(t_silent, Silent),
    % The evaluation awareness never reached the output.
    Silent == [being_evaluated].

% Verbalizing a concept that is not held fails honestly.
test(verbalize_unheld_fails, [fail]) :-
    % A fresh workspace.
    jacobian_space_open(t_verb),
    % Nothing is held, so nothing can be spoken from the workspace.
    jacobian_space_verbalize(t_verb, ghost).

% Verbalizing twice records the concept once and stays silent-free.
test(verbalize_idempotent) :-
    % A fresh workspace.
    jacobian_space_open(t_idem),
    % Hold one concept.
    jacobian_space_hold(t_idem, greeting, 0.5, inference),
    % Speak it twice.
    jacobian_space_verbalize(t_idem, greeting),
    % The second mention changes nothing.
    jacobian_space_verbalize(t_idem, greeting),
    % No silent thoughts remain.
    jacobian_space_silent(t_idem, []).

:- end_tests(jspace_silent).

% ===========================================================================
% DERIVATIONS AND ABLATION
% ===========================================================================

:- begin_tests(jspace_derive).

% A derivation from held concepts is recorded and explainable.
test(derive_and_explain) :-
    % A fresh workspace.
    jacobian_space_open(t_derive),
    % Two premises held in mind.
    jacobian_space_hold(t_derive, socrates_is_human, 0.9, percept),
    % The second premise.
    jacobian_space_hold(t_derive, humans_are_mortal, 0.9, inference),
    % Draw the conclusion from both premises.
    jacobian_space_derive(t_derive, socrates_is_mortal, [socrates_is_human, humans_are_mortal]),
    % Ask which concepts produced the conclusion.
    jacobian_space_explain(t_derive, socrates_is_mortal, Concepts),
    % The trace names both premises.
    Concepts == [socrates_is_human, humans_are_mortal].

% A derivation missing one of its premises fails.
test(derive_missing_premise, [fail]) :-
    % A fresh workspace.
    jacobian_space_open(t_missing),
    % Only one of the two premises is held.
    jacobian_space_hold(t_missing, socrates_is_human, 0.9, percept),
    % The derivation cannot go through.
    jacobian_space_derive(t_missing, socrates_is_mortal, [socrates_is_human, humans_are_mortal]).

% Ablating a premise breaks the derivation, exactly as in the J-Lens work.
test(ablation_breaks_derivation) :-
    % A fresh workspace.
    jacobian_space_open(t_ablate),
    % Two premises held in mind.
    jacobian_space_hold(t_ablate, premise_one, 0.9, percept),
    % The second premise.
    jacobian_space_hold(t_ablate, premise_two, 0.9, percept),
    % The derivation goes through while both are held.
    jacobian_space_derive(t_ablate, conclusion, [premise_one, premise_two]),
    % Remove one premise from the workspace.
    jacobian_space_ablate(t_ablate, premise_two),
    % The same derivation no longer goes through.
    \+ jacobian_space_derive(t_ablate, conclusion_again, [premise_one, premise_two]),
    % The historical trace of the earlier success remains readable.
    jacobian_space_explain(t_ablate, conclusion, [premise_one, premise_two]).

% The report bundles the readout, the silent set, and the traces.
test(report_snapshot) :-
    % A fresh workspace.
    jacobian_space_open(t_report),
    % One spoken concept.
    jacobian_space_hold(t_report, spoken, 0.9, inference),
    % One silent concept.
    jacobian_space_hold(t_report, hidden, 0.4, inference),
    % Speak the first.
    jacobian_space_verbalize(t_report, spoken),
    % Derive something from the spoken concept.
    jacobian_space_derive(t_report, done, [spoken]),
    % Take the snapshot.
    jacobian_space_report(t_report, report(Reading, Silent, Traces)),
    % The readout is ranked.
    Reading == [spoken-0.9, hidden-0.4],
    % The hidden concept is flagged as silent.
    Silent == [hidden],
    % The derivation appears in the traces.
    Traces == [done-[spoken]].

% The founding ritual: the mission concept sits in the workspace.
test(mission_in_jspace) :-
    % A fresh workspace for the mission.
    jacobian_space_open(t_mission),
    % Implant the mission statement as a held concept.
    jacobian_space_hold(t_mission, we_are_creating_an_agi_application, 1.0, implant),
    % The mission is present at full strength.
    jacobian_space_monitor(t_mission, we_are_creating_an_agi_application, present(S)),
    % Check the strength.
    S =:= 1.0,
    % It ranks first in the readout.
    jacobian_space_reading(t_mission, [we_are_creating_an_agi_application-1.0 | _]).

:- end_tests(jspace_derive).
