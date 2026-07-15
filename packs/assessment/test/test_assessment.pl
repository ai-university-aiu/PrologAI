/*  PrologAI — Intelligence Assessment Test Suite  (PR 12)

    Run with the full library path:
        LIB=""; for d in packs/*/prolog; do LIB="$LIB -p library=$d"; done
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/assessment/test/test_assessment.pl

    Exercises the four exported predicates against a live Lattice nexus:
      assess_piaget/3, assess_bayley/2, assess_chc/2, assess_all/2.
*/

% Declare this file as a test module with no exports.
:- module(test_assessment, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(assessment)).
% Load lattice open/close so the tests can stand up a nexus to assess.
:- use_module(library(lattice),    [lattice_open/2, lattice_close/1]).
% Load node_facts helpers to set the default nexus and inscribe proxy evidence.
:- use_module(library(node_facts), [set_default_nexus/1, anchor_node/4]).

% Open the test block for the assessment pack, opening a shared nexus first.
:- begin_tests(assessment, [setup(assessment_setup), cleanup(assessment_cleanup)]).

% Stand up a fresh Lattice nexus and make it the default for read-only tests.
assessment_setup :-
    % Open a dedicated test nexus at a locus address.
    lattice_open('locus://localhost/assessment_pack_test', N),
    % Remember the nexus reference so cleanup and restores can find it.
    nb_setval(assessment_nexus_ref, N),
    % Route the pack's default_nexus/1 at this nexus.
    set_default_nexus(N).

% Tear the shared nexus down after the suite finishes.
assessment_cleanup :-
    % Recover the shared nexus reference stored during setup.
    nb_getval(assessment_nexus_ref, N),
    % Close the shared nexus.
    lattice_close(N).

% assess_bayley/2 returns a bayley_report dict carrying the mind id and numeric DQ areas.
test(bayley_report_shape) :-
    % Assess a named mind on the shared nexus.
    assess_bayley(mind_a, Report),
    % The mind field echoes the requested mind id.
    assertion(get_dict(mind, Report, mind_a)),
    % Read the cognitive developmental-quotient area.
    get_dict(cognitive_dq, Report, Cog),
    % The cognitive DQ is a number capped at one hundred.
    assertion((number(Cog), Cog >= 0.0, Cog =< 100.0)),
    % Read the language developmental-quotient area.
    get_dict(language_dq, Report, Lang),
    % The language DQ is a number in the same range.
    assertion((number(Lang), Lang >= 0.0, Lang =< 100.0)),
    % Read the motor developmental-quotient area.
    get_dict(motor_dq, Report, Motor),
    % The motor DQ is a number in the same range.
    assertion((number(Motor), Motor >= 0.0, Motor =< 100.0)),
    % Read the adaptive developmental-quotient area.
    get_dict(adaptive_dq, Report, Adapt),
    % The adaptive DQ is a number in the same range.
    assertion((number(Adapt), Adapt >= 0.0, Adapt =< 100.0)).

% assess_chc/2 returns a chc_report dict with the six broad abilities and a deterministic visual field.
test(chc_report_shape) :-
    % Assess a named mind against the Cattell-Horn-Carroll model.
    assess_chc(mind_b, Report),
    % The mind field echoes the requested mind id.
    assertion(get_dict(mind, Report, mind_b)),
    % Fluid reasoning is measured by relation-type diversity, a non-negative integer.
    get_dict(fluid_reasoning, Report, Fluid),
    % The fluid-reasoning proxy is a non-negative integer.
    assertion((integer(Fluid), Fluid >= 0)),
    % Short-term memory counts the live node_facts, a non-negative integer.
    get_dict(short_term_memory, Report, Stm),
    % The short-term-memory proxy is a non-negative integer.
    assertion((integer(Stm), Stm >= 0)),
    % Crystallized knowledge is a non-negative number.
    get_dict(crystallized_knowledge, Report, Cryst),
    % The crystallized-knowledge proxy is a non-negative number.
    assertion((number(Cryst), Cryst >= 0.0)),
    % Visual processing has no proxy and is hard-coded to zero.
    assertion(get_dict(visual_processing, Report, 0)).

% assess_all/2 stitches together all four frameworks plus consciousness indicators.
test(assess_all_sections) :-
    % Run the full assessment on a named mind.
    assess_all(mind_c, Report),
    % The bayley sub-report is present.
    assertion(get_dict(bayley, Report, _)),
    % The chc sub-report is present.
    assertion(get_dict(chc, Report, _)),
    % Read the Piagetian milestone results.
    get_dict(piaget_milestones, Report, Piaget),
    % Exactly eight milestones are reported, one per developmental level.
    assertion(length(Piaget, 8)),
    % Read the consciousness-indicator results.
    get_dict(consciousness_indicators, Report, CI),
    % Four consciousness indicators are reported.
    assertion(length(CI, 4)).

% assess_all/2 persists its result as an 'assessment' node_fact in the Lattice.
test(assess_all_stores_node_fact) :-
    % Run the full assessment for a distinctly named mind.
    assess_all(mind_stored, _),
    % A matching assessment node_fact was inscribed with the mind id and 'all' tag.
    assertion(node_facts:lattice_node_fact(_, _, assessment, [mind_stored, all, _], [])).

% For a mind whose Lattice never broadcast, the workspace_ignition indicator is absent.
test(consciousness_workspace_ignition_absent) :-
    % Run the full assessment on a fresh named mind.
    assess_all(mind_ci, Report),
    % Read the consciousness-indicator pair list.
    get_dict(consciousness_indicators, Report, CI),
    % No workspace broadcast exists, so the ignition indicator reports absent.
    assertion(memberchk(workspace_ignition-absent, CI)).

% assess_piaget/3 reports every milestone unachieved for a mind with no proxy evidence.
test(piaget_fresh_mind_not_achieved) :-
    % Open a separate pristine nexus with no inscribed evidence.
    lattice_open('locus://localhost/assessment_fresh', FN),
    % Make the pristine nexus the default for this test.
    set_default_nexus(FN),
    % Every one of the eight levels evaluates to milestone_not_achieved.
    assertion(forall(between(1, 8, L), assess_piaget(mind_fresh, L, milestone_not_achieved))),
    % Close the pristine nexus.
    lattice_close(FN),
    % Restore the shared nexus as the default.
    nb_getval(assessment_nexus_ref, N),
    % Route default_nexus/1 back at the shared nexus.
    set_default_nexus(N).

% assess_piaget/3 flips level 1 to milestone_achieved once its percept_signal proxy evidence exists.
test(piaget_achieved_after_evidence) :-
    % Open a separate nexus so the inscribed evidence does not leak into other tests.
    lattice_open('locus://localhost/assessment_evidence', EN),
    % Make the evidence nexus the default.
    set_default_nexus(EN),
    % Level 1 (reflex_coordination) is not yet achieved on the empty nexus.
    assess_piaget(mind_ev, 1, Before),
    % Confirm the pre-evidence result.
    assertion(Before == milestone_not_achieved),
    % Inscribe the level-1 proxy evidence: a percept_signal node_fact.
    anchor_node(percept_signal, [herald_test, visual_data], [], _),
    % Re-assess level 1 now that the evidence is present.
    assess_piaget(mind_ev, 1, After),
    % The milestone now reads as achieved.
    assertion(After == milestone_achieved),
    % Close the evidence nexus.
    lattice_close(EN),
    % Restore the shared nexus as the default.
    nb_getval(assessment_nexus_ref, N),
    % Route default_nexus/1 back at the shared nexus.
    set_default_nexus(N).

% assess_piaget/3 fails outright for a level outside the one-to-eight range.
test(piaget_out_of_range_fails, [fail]) :-
    % Level 9 is out of range, so the guard rejects it and the call fails.
    assess_piaget(mind_a, 9, _).

% Close the test block for the assessment pack.
:- end_tests(assessment).
