/*  PrologAI — Causalontology Core Test Suite  (WP-393)

    Includes the specification's cross-layer acceptance query (Section 3.5):
    an object bears a realizable that is realized in a process that
    participates in a causal relation, answered across all three layers.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/causal_core/test/test_co_core.pl
*/

% Declare this file as a test module.
:- module(test_co_core, []).

% Load the PLUnit test framework.
:- use_module(library(plunit)).

% Load the module under test.
:- use_module(library(causal_core)).
% Load the noun layer for the cross-layer acceptance query.
:- use_module(library(co_noun)).
% Load the hinge for the cross-layer acceptance query.
:- use_module(library(co_hinge)).

% ===========================================================================
% THE CRO — validation, prediction, strengthening
% ===========================================================================

:- begin_tests(co_core_cro).

% A lawful CRO round-trips with its full payload.
test(cro_roundtrip) :-
    % A fresh verb layer.
    causal_core_reset,
    % Assert the canonical example relation.
    causal_core_cro_assert(cro(c1, [press(b_red)], [light(red, on)],
                      temporal(0, 0, instant), sufficient, 0.7, [],
                      prov(agent, learned_by_intervention, 0.7))),
    % Fetch it whole.
    causal_core_the_cro(c1, cro(c1, [press(b_red)], [light(red, on)], _, sufficient, 0.7, _, _)).

% An unlawful modality is refused.
test(bad_modality_refused, [fail]) :-
    % A fresh verb layer.
    causal_core_reset,
    % The modality must be one of the four.
    causal_core_cro_assert(cro(c1, [a], [b], temporal(0, 0, instant), maybe, 0.5, [],
                      prov(kb, asserted, 0.5))).

% A strength outside the unit interval is refused.
test(bad_strength_refused, [fail]) :-
    % A fresh verb layer.
    causal_core_reset,
    % Strength is a fraction.
    causal_core_cro_assert(cro(c1, [a], [b], temporal(0, 0, instant), sufficient, 1.5, [],
                      prov(kb, asserted, 0.5))).

% A disordered temporal window is refused: the window is the mechanism.
test(bad_window_refused, [fail]) :-
    % A fresh verb layer.
    causal_core_reset,
    % The minimum delay cannot exceed the maximum.
    causal_core_cro_assert(cro(c1, [a], [b], temporal(6, 1, hours), sufficient, 0.5, [],
                      prov(kb, asserted, 0.5))).

% Confirmation raises strength, capped at 0.99.
test(strengthen_capped) :-
    % A fresh verb layer.
    causal_core_reset,
    % A relation at 0.7.
    causal_core_new_cro([a], [b], temporal(0, 0, instant), sufficient, 0.7, [],
               prov(agent, learned_by_intervention, 0.7), Id),
    % One confirmation.
    causal_core_strengthen(Id, 0.2),
    % Read back the raised strength.
    causal_core_cro(Id, _, _, _, _, S1, _, _),
    % It rose by the delta.
    abs(S1 - 0.9) < 1.0e-9,
    % Confirm twice more to hit the cap.
    causal_core_strengthen(Id, 0.2),
    % And once more.
    causal_core_strengthen(Id, 0.2),
    % Read back the capped strength.
    causal_core_cro(Id, _, _, _, _, S2, _, _),
    % Capped at 0.99.
    abs(S2 - 0.99) < 1.0e-9.

% Prediction reads effects from relations, never preventive ones.
test(predict_excludes_preventive, [nondet]) :-
    % A fresh verb layer.
    causal_core_reset,
    % A productive relation.
    causal_core_new_cro([press(b)], [light(on)], temporal(0, 0, instant), sufficient,
               0.7, [], prov(agent, learned_by_intervention, 0.7), _),
    % A preventive relation.
    causal_core_new_cro([touch(spike)], [penalty], temporal(0, 0, instant), preventive,
               0.9, [], prov(agent, learned_by_intervention, 0.9), Pid),
    % The productive effect is predicted.
    causal_core_predict(press(b), light(on)),
    % The hazard is not a prediction.
    \+ causal_core_predict(touch(spike), penalty),
    % But it is queryable as preventive.
    causal_core_preventive(Pid).

:- end_tests(co_core_cro).

% ===========================================================================
% TEMPORAL VERSUS CAUSAL SUCCESSION, AND TIMING AS MECHANISM
% ===========================================================================

:- begin_tests(co_core_temporal).

% Mere sequence is never read as production.
test(after_is_not_because) :-
    % A fresh verb layer.
    causal_core_reset,
    % The rooster crows before the sunrise.
    causal_core_precedes_add(rooster_crow, sunrise),
    % The succession is recorded.
    causal_core_precedes(rooster_crow, sunrise),
    % But no relation produces the sunrise from the crow.
    \+ causal_core_causally_linked(rooster_crow, sunrise),
    % The discipline is queryable directly.
    causal_core_after_but_not_because(rooster_crow, sunrise).

% The clinician's question: a cause is excluded purely on timing.
test(temporal_abduction_gate, [nondet]) :-
    % A fresh verb layer.
    causal_core_reset,
    % Spoiled shellfish acts within one to six hours.
    causal_core_new_cro([ate(spoiled_shellfish)], [state(gastroenteritis)],
               temporal(1, 6, hours), contributory, 0.7, [],
               prov(kb, asserted, 0.7), _),
    % Undercooked poultry acts within six to seventy-two hours.
    causal_core_new_cro([ate(undercooked_poultry)], [state(gastroenteritis)],
               temporal(6, 72, hours), contributory, 0.6, [],
               prov(kb, asserted, 0.6), _),
    % Two recent meals: shellfish three hours ago, poultry two hours ago.
    causal_core_temporal_abduction(state(gastroenteritis),
                          [ate(spoiled_shellfish)-elapsed(3, hours),
                           ate(undercooked_poultry)-elapsed(2, hours)],
                          Ranked),
    % The shellfish is admitted: three hours is inside one-to-six.
    memberchk(0.7-ate(spoiled_shellfish), Ranked),
    % The poultry is excluded purely on timing: two hours is before six.
    \+ memberchk(_-ate(undercooked_poultry), Ranked),
    % The gate is also queryable one candidate at a time.
    causal_core_temporal_admissible(ate(spoiled_shellfish), state(gastroenteritis),
                           elapsed(3, hours)),
    % And it refuses the too-early candidate.
    \+ causal_core_temporal_admissible(ate(undercooked_poultry), state(gastroenteritis),
                              elapsed(2, hours)).

:- end_tests(co_core_temporal).

% ===========================================================================
% HIERARCHY, SUBSUMPTION IMPORT, AND THE GLASS BOX
% ===========================================================================

:- begin_tests(co_core_hierarchy).

% A coarse relation is consistent with the composition of its parts.
test(hierarchy_consistent, [nondet]) :-
    % A fresh verb layer.
    causal_core_reset,
    % The coarse relation: fuel burns to motion.
    causal_core_new_cro([ignite], [motion], temporal(0, 1, seconds), sufficient, 0.8,
               [], prov(kb, asserted, 0.8), Parent),
    % Fine step one: ignition to combustion.
    causal_core_new_cro([ignite], [combustion], temporal(0, 0, instant), sufficient,
               0.9, [], prov(kb, asserted, 0.9), S1),
    % Fine step two: combustion to expansion.
    causal_core_new_cro([combustion], [expansion], temporal(0, 0, instant), sufficient,
               0.9, [], prov(kb, asserted, 0.9), S2),
    % Fine step three: expansion to motion.
    causal_core_new_cro([expansion], [motion], temporal(0, 0, instant), sufficient,
               0.9, [], prov(kb, asserted, 0.9), S3),
    % Attach the mechanism sub-graph.
    causal_core_decompose_add(Parent, [S1, S2, S3]),
    % Read it back.
    causal_core_mechanism(Parent, [S1, S2, S3]),
    % The parts chain from the parent's cause to its effect.
    causal_core_hierarchy_consistent(Parent).

% An incoherent decomposition fails the consistency check.
test(hierarchy_inconsistent, [fail]) :-
    % A fresh verb layer.
    causal_core_reset,
    % The coarse relation.
    causal_core_new_cro([ignite], [motion], temporal(0, 1, seconds), sufficient, 0.8,
               [], prov(kb, asserted, 0.8), Parent),
    % A fine step that never reaches the parent's effect.
    causal_core_new_cro([ignite], [smoke], temporal(0, 0, instant), sufficient, 0.9,
               [], prov(kb, asserted, 0.9), S1),
    % Attach the broken mechanism.
    causal_core_decompose_add(Parent, [S1]),
    % The composition cannot reach motion.
    causal_core_hierarchy_consistent(Parent).

% The subsumption argument: import a degenerate external verb, then refine.
test(import_and_refine) :-
    % A fresh verb layer.
    causal_core_reset,
    % ConceptNet's bare "Causes" becomes a provisional degenerate CRO.
    causal_core_import_external(conceptnet, smoking, cancer, Id),
    % It is flagged provisional.
    causal_core_provisional(Id),
    % Its unspecified window is open-ended.
    causal_core_cro(Id, [smoking], [cancer], temporal(0, unspecified, unspecified),
           contributory, 0.5, _, prov(conceptnet, imported_external, _)),
    % Refinement fills the payload the import omitted.
    causal_core_refine_import(Id, temporal(3650, unspecified, days), contributory, 0.8),
    % The relation is now owned and no longer provisional.
    \+ causal_core_provisional(Id),
    % And strictly more expressive than the bare import.
    causal_core_cro(Id, [smoking], [cancer], temporal(3650, unspecified, days),
           contributory, 0.8, _, prov(conceptnet, refined_after_import, _)).

% The glass-box why returns the full story of a relation.
test(why_full_story) :-
    % A fresh verb layer.
    causal_core_reset,
    % One relation.
    causal_core_new_cro([press(b)], [light(on)], temporal(0, 0, instant), sufficient,
               0.7, [], prov(agent, learned_by_intervention, 0.7), Id),
    % Ask why.
    causal_core_why(Id, Why),
    % The story carries every field.
    Why = why(Id, causes([press(b)]), effects([light(on)]), window(_),
              modality(sufficient), strength(0.7), context([]),
              provenance(prov(agent, learned_by_intervention, 0.7)),
              mechanism([])).

% The cross-layer acceptance query of Section 3.5: an object bears a
% realizable realized in a process that participates in a causal relation.
test(cross_layer_acceptance, [nondet]) :-
    % Fresh layers.
    causal_core_reset,
    % Fresh noun layer.
    co_noun_reset,
    % Fresh hinge.
    co_hinge_reset,
    % NOUN: the button is an object.
    co_continuant_add(b_red, object),
    % HINGE: the button bears a pressable disposition.
    co_realizable_add(d1, disposition, b_red),
    % SEAM: the disposition is realized in pressing.
    co_realized_in_add(d1, press(b_red)),
    % VERB: pressing participates as cause in a causal relation.
    causal_core_new_cro([press(b_red)], [light(red, on)], temporal(0, 0, instant),
               sufficient, 0.7, [], prov(agent, learned_by_intervention, 0.7), _),
    % THE CROSS-LAYER QUERY: from the object, through its realizable and its
    % realizing occurrent, to the effect that occurrent produces.
    co_continuant(Object, object),
    % The object bears a realizable.
    co_realizable(D, disposition, Object),
    % The realizable is realized in an occurrent.
    co_realized_in(D, Occurrent),
    % That occurrent causes an effect.
    causal_core_predict(Occurrent, Effect),
    % The traversal lands exactly where it should.
    Object == b_red,
    % Through the pressing occurrent.
    Occurrent == press(b_red),
    % To the light coming on.
    Effect == light(red, on).

:- end_tests(co_core_hierarchy).
