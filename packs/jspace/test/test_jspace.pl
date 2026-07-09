/*  PrologAI — Concept Workspace (J-Space) Pack Test Suite  (WP-388)

    Acceptance tests for all js_* predicates, including the silent-
    thought detection and ablation-breaks-derivation behaviours that
    mirror the 2026 J-Lens interpretability findings.

    Run with:
        swipl -g "run_tests, halt" test_jspace.pl
*/

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module('../prolog/jspace').

% ===========================================================================
% HOLDING, READING, AND EDITING
% ===========================================================================

:- begin_tests(jspace_ledger).

% The reading ranks held concepts by strength, strongest first.
test(reading_ranked) :-
    % A fresh workspace.
    js_open(t_read),
    % Hold three concepts at different strengths.
    js_hold(t_read, weak, 0.2, percept),
    % The strongest concept.
    js_hold(t_read, strong, 0.9, percept),
    % A middle concept.
    js_hold(t_read, mid, 0.5, inference),
    % Take the J-Lens readout.
    js_reading(t_read, Reading),
    % The ranking is strongest first.
    Reading == [strong-0.9, mid-0.5, weak-0.2].

% Re-holding a concept updates it in place without duplication.
test(hold_upserts) :-
    % A fresh workspace.
    js_open(t_upsert),
    % Hold a concept once.
    js_hold(t_upsert, idea, 0.3, percept),
    % Hold the same concept again at a new strength.
    js_hold(t_upsert, idea, 0.8, inference),
    % Take the readout.
    js_reading(t_upsert, Reading),
    % Exactly one entry remains, at the new strength.
    Reading == [idea-0.8].

% Strength and source read back what was held.
test(strength_and_source) :-
    % A fresh workspace.
    js_open(t_ss),
    % Hold one concept.
    js_hold(t_ss, cat, 0.7, percept),
    % Read the strength back.
    js_strength(t_ss, cat, S),
    % Check the strength.
    S =:= 0.7,
    % Read the source back.
    js_source(t_ss, cat, Src),
    % Check the source.
    Src == percept.

% Reading a concept that is not held fails honestly.
test(strength_absent_fails, [fail]) :-
    % A fresh workspace.
    js_open(t_absent),
    % Nothing was held, so nothing can be read.
    js_strength(t_absent, ghost, _).

% A negative strength is rejected.
test(negative_strength_rejected, [fail]) :-
    % A fresh workspace.
    js_open(t_neg),
    % Strengths must be non-negative.
    js_hold(t_neg, bad, -0.5, percept).

% Zero-strength concepts are held but not active.
test(active_excludes_zero) :-
    % A fresh workspace.
    js_open(t_active),
    % A live concept.
    js_hold(t_active, alive, 0.4, percept),
    % A held but fully faded concept.
    js_hold(t_active, faded, 0.0, percept),
    % Ask for the active set.
    js_active(t_active, Active),
    % Only the live concept qualifies.
    Active == [alive].

% The monitor reports presence with strength, or absence.
test(monitor) :-
    % A fresh workspace.
    js_open(t_mon),
    % Hold one concept.
    js_hold(t_mon, watched, 0.6, implant),
    % The held concept is present.
    js_monitor(t_mon, watched, present(S)),
    % Check the reported strength.
    S =:= 0.6,
    % An unheld concept is absent.
    js_monitor(t_mon, unheld, absent).

% Swapping two concepts exchanges their strengths and flips the ranking.
test(swap_flips_ranking) :-
    % A fresh workspace.
    js_open(t_swap),
    % The initially stronger concept.
    js_hold(t_swap, first, 0.9, percept),
    % The initially weaker concept.
    js_hold(t_swap, second, 0.1, percept),
    % Exchange their strengths.
    js_swap(t_swap, first, second),
    % Take the readout.
    js_reading(t_swap, Reading),
    % The system now reports thinking the other thought first.
    Reading == [second-0.9, first-0.1].

% Boosting raises a strength; the floor at zero holds.
test(boost_and_floor) :-
    % A fresh workspace.
    js_open(t_boost),
    % Hold one concept.
    js_hold(t_boost, idea, 0.5, percept),
    % Boost it upward.
    js_boost(t_boost, idea, 0.3),
    % Read the raised strength.
    js_strength(t_boost, idea, Up),
    % Check the raise.
    abs(Up - 0.8) < 1.0e-9,
    % Push it far below zero.
    js_boost(t_boost, idea, -5.0),
    % Read the floored strength.
    js_strength(t_boost, idea, Floor),
    % The floor held.
    Floor =:= 0.0.

% Decay scales every strength and drops the negligible.
test(decay) :-
    % A fresh workspace.
    js_open(t_decay),
    % A robust concept.
    js_hold(t_decay, robust, 0.8, percept),
    % A concept already at the edge of vanishing.
    js_hold(t_decay, tiny, 1.0e-6, percept),
    % Halve every activation.
    js_decay(t_decay, 0.5),
    % The robust concept survived at half strength.
    js_strength(t_decay, robust, S),
    % Check the halving.
    abs(S - 0.4) < 1.0e-9,
    % The tiny concept fell out of the workspace.
    js_monitor(t_decay, tiny, absent).

% Capacity keeps only the strongest N concepts — a sparse workspace.
test(capacity) :-
    % A fresh workspace.
    js_open(t_cap),
    % Hold five concepts at graded strengths.
    js_hold(t_cap, a, 0.9, percept),
    % Second strongest.
    js_hold(t_cap, b, 0.7, percept),
    % Third strongest.
    js_hold(t_cap, c, 0.5, percept),
    % Fourth strongest.
    js_hold(t_cap, d, 0.3, percept),
    % Weakest.
    js_hold(t_cap, e, 0.1, percept),
    % Enforce a capacity of three.
    js_capacity(t_cap, 3),
    % Ask for the surviving active set.
    js_active(t_cap, Active),
    % Only the strongest three remain.
    Active == [a, b, c].

% Workspaces are isolated from each other.
test(spaces_isolated) :-
    % Two fresh workspaces.
    js_open(t_iso_a),
    % The second workspace.
    js_open(t_iso_b),
    % Hold a concept in the first only.
    js_hold(t_iso_a, private, 0.5, percept),
    % The second workspace never saw it.
    js_monitor(t_iso_b, private, absent).

:- end_tests(jspace_ledger).

% ===========================================================================
% SILENT THOUGHTS AND VERBALIZATION
% ===========================================================================

:- begin_tests(jspace_silent).

% Silent detection: a concept held in mind but never spoken is revealed.
test(silent_thought_detected) :-
    % A fresh workspace.
    js_open(t_silent),
    % The system silently notices it is being evaluated.
    js_hold(t_silent, being_evaluated, 0.8, inference),
    % It also holds the concept it is about to speak about.
    js_hold(t_silent, polite_answer, 0.6, inference),
    % Only the answer is verbalized.
    js_verbalize(t_silent, polite_answer),
    % Read the silent set.
    js_silent(t_silent, Silent),
    % The evaluation awareness never reached the output.
    Silent == [being_evaluated].

% Verbalizing a concept that is not held fails honestly.
test(verbalize_unheld_fails, [fail]) :-
    % A fresh workspace.
    js_open(t_verb),
    % Nothing is held, so nothing can be spoken from the workspace.
    js_verbalize(t_verb, ghost).

% Verbalizing twice records the concept once and stays silent-free.
test(verbalize_idempotent) :-
    % A fresh workspace.
    js_open(t_idem),
    % Hold one concept.
    js_hold(t_idem, greeting, 0.5, inference),
    % Speak it twice.
    js_verbalize(t_idem, greeting),
    % The second mention changes nothing.
    js_verbalize(t_idem, greeting),
    % No silent thoughts remain.
    js_silent(t_idem, []).

:- end_tests(jspace_silent).

% ===========================================================================
% DERIVATIONS AND ABLATION
% ===========================================================================

:- begin_tests(jspace_derive).

% A derivation from held concepts is recorded and explainable.
test(derive_and_explain) :-
    % A fresh workspace.
    js_open(t_derive),
    % Two premises held in mind.
    js_hold(t_derive, socrates_is_human, 0.9, percept),
    % The second premise.
    js_hold(t_derive, humans_are_mortal, 0.9, inference),
    % Draw the conclusion from both premises.
    js_derive(t_derive, socrates_is_mortal, [socrates_is_human, humans_are_mortal]),
    % Ask which concepts produced the conclusion.
    js_explain(t_derive, socrates_is_mortal, Concepts),
    % The trace names both premises.
    Concepts == [socrates_is_human, humans_are_mortal].

% A derivation missing one of its premises fails.
test(derive_missing_premise, [fail]) :-
    % A fresh workspace.
    js_open(t_missing),
    % Only one of the two premises is held.
    js_hold(t_missing, socrates_is_human, 0.9, percept),
    % The derivation cannot go through.
    js_derive(t_missing, socrates_is_mortal, [socrates_is_human, humans_are_mortal]).

% Ablating a premise breaks the derivation, exactly as in the J-Lens work.
test(ablation_breaks_derivation) :-
    % A fresh workspace.
    js_open(t_ablate),
    % Two premises held in mind.
    js_hold(t_ablate, premise_one, 0.9, percept),
    % The second premise.
    js_hold(t_ablate, premise_two, 0.9, percept),
    % The derivation goes through while both are held.
    js_derive(t_ablate, conclusion, [premise_one, premise_two]),
    % Remove one premise from the workspace.
    js_ablate(t_ablate, premise_two),
    % The same derivation no longer goes through.
    \+ js_derive(t_ablate, conclusion_again, [premise_one, premise_two]),
    % The historical trace of the earlier success remains readable.
    js_explain(t_ablate, conclusion, [premise_one, premise_two]).

% The report bundles the readout, the silent set, and the traces.
test(report_snapshot) :-
    % A fresh workspace.
    js_open(t_report),
    % One spoken concept.
    js_hold(t_report, spoken, 0.9, inference),
    % One silent concept.
    js_hold(t_report, hidden, 0.4, inference),
    % Speak the first.
    js_verbalize(t_report, spoken),
    % Derive something from the spoken concept.
    js_derive(t_report, done, [spoken]),
    % Take the snapshot.
    js_report(t_report, report(Reading, Silent, Traces)),
    % The readout is ranked.
    Reading == [spoken-0.9, hidden-0.4],
    % The hidden concept is flagged as silent.
    Silent == [hidden],
    % The derivation appears in the traces.
    Traces == [done-[spoken]].

% The founding ritual: the mission concept sits in the workspace.
test(mission_in_jspace) :-
    % A fresh workspace for the mission.
    js_open(t_mission),
    % Implant the mission statement as a held concept.
    js_hold(t_mission, we_are_creating_an_agi_application, 1.0, implant),
    % The mission is present at full strength.
    js_monitor(t_mission, we_are_creating_an_agi_application, present(S)),
    % Check the strength.
    S =:= 1.0,
    % It ranks first in the readout.
    js_reading(t_mission, [we_are_creating_an_agi_application-1.0 | _]).

:- end_tests(jspace_derive).
