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
:- use_module(library(noun_backbone)).
% Load the hinge for the cross-layer acceptance query.
:- use_module(library(realizable_hinge)).

% ===========================================================================
% THE causal_relation_object — validation, prediction, strengthening
% ===========================================================================

:- begin_tests(co_core_causal_relation_object).

% A lawful causal_relation_object round-trips with its full payload.
test(causal_relation_object_roundtrip) :-
    % A fresh verb layer.
    causal_core_reset,
    % Assert the canonical example relation.
    causal_core_causal_relation_object_assert(causal_relation_object(c1, [press(b_red)], [light(red, on)],
                      temporal(0, 0, instant), sufficient, 0.7, [],
                      prov(agent, learned_by_intervention, 0.7))),
    % Fetch it whole.
    causal_core_the_causal_relation_object(c1, causal_relation_object(c1, [press(b_red)], [light(red, on)], _, sufficient, 0.7, _, _)).

% An unlawful modality is refused.
test(bad_modality_refused, [fail]) :-
    % A fresh verb layer.
    causal_core_reset,
    % The modality must be one of the four.
    causal_core_causal_relation_object_assert(causal_relation_object(c1, [a], [b], temporal(0, 0, instant), maybe, 0.5, [],
                      prov(kb, asserted, 0.5))).

% A strength outside the unit interval is refused.
test(bad_strength_refused, [fail]) :-
    % A fresh verb layer.
    causal_core_reset,
    % Strength is a fraction.
    causal_core_causal_relation_object_assert(causal_relation_object(c1, [a], [b], temporal(0, 0, instant), sufficient, 1.5, [],
                      prov(kb, asserted, 0.5))).

% A disordered temporal window is refused: the window is the mechanism.
test(bad_window_refused, [fail]) :-
    % A fresh verb layer.
    causal_core_reset,
    % The minimum delay cannot exceed the maximum.
    causal_core_causal_relation_object_assert(causal_relation_object(c1, [a], [b], temporal(6, 1, hours), sufficient, 0.5, [],
                      prov(kb, asserted, 0.5))).

% Confirmation raises strength, capped at 0.99.
test(strengthen_capped) :-
    % A fresh verb layer.
    causal_core_reset,
    % A relation at 0.7.
    causal_core_new_causal_relation_object([a], [b], temporal(0, 0, instant), sufficient, 0.7, [],
               prov(agent, learned_by_intervention, 0.7), Id),
    % One confirmation.
    causal_core_strengthen(Id, 0.2),
    % Read back the raised strength.
    causal_core_causal_relation_object(Id, _, _, _, _, S1, _, _),
    % It rose by the delta.
    abs(S1 - 0.9) < 1.0e-9,
    % Confirm twice more to hit the cap.
    causal_core_strengthen(Id, 0.2),
    % And once more.
    causal_core_strengthen(Id, 0.2),
    % Read back the capped strength.
    causal_core_causal_relation_object(Id, _, _, _, _, S2, _, _),
    % Capped at 0.99.
    abs(S2 - 0.99) < 1.0e-9.

% Prediction reads effects from relations, never preventive ones.
test(predict_excludes_preventive, [nondet]) :-
    % A fresh verb layer.
    causal_core_reset,
    % A productive relation.
    causal_core_new_causal_relation_object([press(b)], [light(on)], temporal(0, 0, instant), sufficient,
               0.7, [], prov(agent, learned_by_intervention, 0.7), _),
    % A preventive relation.
    causal_core_new_causal_relation_object([touch(spike)], [penalty], temporal(0, 0, instant), preventive,
               0.9, [], prov(agent, learned_by_intervention, 0.9), Pid),
    % The productive effect is predicted.
    causal_core_predict(press(b), light(on)),
    % The hazard is not a prediction.
    \+ causal_core_predict(touch(spike), penalty),
    % But it is queryable as preventive.
    causal_core_preventive(Pid).

:- end_tests(co_core_causal_relation_object).

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
    causal_core_new_causal_relation_object([ate(spoiled_shellfish)], [state(gastroenteritis)],
               temporal(1, 6, hours), contributory, 0.7, [],
               prov(kb, asserted, 0.7), _),
    % Undercooked poultry acts within six to seventy-two hours.
    causal_core_new_causal_relation_object([ate(undercooked_poultry)], [state(gastroenteritis)],
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
    causal_core_new_causal_relation_object([ignite], [motion], temporal(0, 1, seconds), sufficient, 0.8,
               [], prov(kb, asserted, 0.8), Parent),
    % Fine step one: ignition to combustion.
    causal_core_new_causal_relation_object([ignite], [combustion], temporal(0, 0, instant), sufficient,
               0.9, [], prov(kb, asserted, 0.9), S1),
    % Fine step two: combustion to expansion.
    causal_core_new_causal_relation_object([combustion], [expansion], temporal(0, 0, instant), sufficient,
               0.9, [], prov(kb, asserted, 0.9), S2),
    % Fine step three: expansion to motion.
    causal_core_new_causal_relation_object([expansion], [motion], temporal(0, 0, instant), sufficient,
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
    causal_core_new_causal_relation_object([ignite], [motion], temporal(0, 1, seconds), sufficient, 0.8,
               [], prov(kb, asserted, 0.8), Parent),
    % A fine step that never reaches the parent's effect.
    causal_core_new_causal_relation_object([ignite], [smoke], temporal(0, 0, instant), sufficient, 0.9,
               [], prov(kb, asserted, 0.9), S1),
    % Attach the broken mechanism.
    causal_core_decompose_add(Parent, [S1]),
    % The composition cannot reach motion.
    causal_core_hierarchy_consistent(Parent).

% The subsumption argument: import a degenerate external verb, then refine.
test(import_and_refine) :-
    % A fresh verb layer.
    causal_core_reset,
    % ConceptNet's bare "Causes" becomes a provisional degenerate causal_relation_object.
    causal_core_import_external(conceptnet, smoking, cancer, Id),
    % It is flagged provisional.
    causal_core_provisional(Id),
    % Its unspecified window is open-ended.
    causal_core_causal_relation_object(Id, [smoking], [cancer], temporal(0, unspecified, unspecified),
           contributory, 0.5, _, prov(conceptnet, imported_external, _)),
    % Refinement fills the payload the import omitted.
    causal_core_refine_import(Id, temporal(3650, unspecified, days), contributory, 0.8),
    % The relation is now owned and no longer provisional.
    \+ causal_core_provisional(Id),
    % And strictly more expressive than the bare import.
    causal_core_causal_relation_object(Id, [smoking], [cancer], temporal(3650, unspecified, days),
           contributory, 0.8, _, prov(conceptnet, refined_after_import, _)).

% The glass-box why returns the full story of a relation.
test(why_full_story) :-
    % A fresh verb layer.
    causal_core_reset,
    % One relation.
    causal_core_new_causal_relation_object([press(b)], [light(on)], temporal(0, 0, instant), sufficient,
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
    noun_backbone_reset,
    % Fresh hinge.
    realizable_hinge_reset,
    % NOUN: the button is an object.
    noun_backbone_continuant_add(b_red, object),
    % HINGE: the button bears a pressable disposition.
    realizable_hinge_realizable_add(d1, disposition, b_red),
    % SEAM: the disposition is realized in pressing.
    realizable_hinge_realized_in_add(d1, press(b_red)),
    % VERB: pressing participates as cause in a causal relation.
    causal_core_new_causal_relation_object([press(b_red)], [light(red, on)], temporal(0, 0, instant),
               sufficient, 0.7, [], prov(agent, learned_by_intervention, 0.7), _),
    % THE CROSS-LAYER QUERY: from the object, through its realizable and its
    % realizing occurrent, to the effect that occurrent produces.
    noun_backbone_continuant(Object, object),
    % The object bears a realizable.
    realizable_hinge_realizable(D, disposition, Object),
    % The realizable is realized in an occurrent.
    realizable_hinge_realized_in(D, Occurrent),
    % That occurrent causes an effect.
    causal_core_predict(Occurrent, Effect),
    % The traversal lands exactly where it should.
    Object == b_red,
    % Through the pressing occurrent.
    Occurrent == press(b_red),
    % To the light coming on.
    Effect == light(red, on).

:- end_tests(co_core_hierarchy).

% ===========================================================================
% CAUSALONTOLOGY 4.0.0 — the three new kinds (attitude, predicted_occurrence,
% prediction_error). These exercise causal_core 1.1.0's additive identity rows
% (causal_core_identity_fields/2) and Rule 24 semantics; the eighteen 3.0.0
% kinds and their thirteen tests above are untouched.
% ===========================================================================

:- begin_tests(co_core_causalontology_4_0_0).

% A 64-character lowercase-hex digest stand-in for the id-bearing references.
test_co_hex64("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef").

% An attitude identifies under the attitude scheme (id prefix correct).
test(attitude_identify_roundtrip) :-
    % The digest used for the holder and content references.
    test_co_hex64(H),
    % A believing agent's attitude toward a state assertion.
    atom_concat('token_individual:', H, Holder),
    % The believed content, a state assertion by identity.
    atom_concat('state_assertion:', H, Content),
    % Build the attitude dict with its explicit type field.
    Att = _{type:"attitude", holder:Holder, attitude_type:"believes", content:Content},
    % Identify it under its inferred kind.
    causal_core_identify(Att, _, Id),
    % The identifier is minted under the whole-word attitude scheme.
    atom_string(IdA, Id),
    % The prefix is exactly the attitude scheme.
    sub_atom(IdA, 0, _, _, 'attitude:').

% A predicted_occurrence identifies under the predicted_occurrence scheme.
test(predicted_occurrence_identify_roundtrip) :-
    % The digest used for the instantiated occurrent and the predictor.
    test_co_hex64(H),
    % The occurrent type predicted to occur.
    atom_concat('occurrent:', H, Occ),
    % The predicting agent.
    atom_concat('token_individual:', H, Predictor),
    % A tick-windowed prediction.
    P = _{type:"predicted_occurrence", instantiates:Occ,
          interval:_{start_tick:3, end_tick:8}, predictor:Predictor},
    % Identify it under its inferred kind.
    causal_core_identify(P, _, Id),
    % The identifier is minted under the whole-word predicted_occurrence scheme.
    atom_string(IdA, Id),
    % The prefix is exactly the predicted_occurrence scheme.
    sub_atom(IdA, 0, _, _, 'predicted_occurrence:').

% A prediction_error identifies under the prediction_error scheme.
test(prediction_error_identify_roundtrip) :-
    % The digest used for the graded prediction reference.
    test_co_hex64(H),
    % The prediction this error grades.
    atom_concat('predicted_occurrence:', H, Pred),
    % An unfulfilled prediction: a negative discrepancy, no observed occurrence.
    Err = _{type:"prediction_error", predicted:Pred, discrepancy:(-1.0)},
    % Identify it under its inferred kind.
    causal_core_identify(Err, _, Id),
    % The identifier is minted under the whole-word prediction_error scheme.
    atom_string(IdA, Id),
    % The prefix is exactly the prediction_error scheme.
    sub_atom(IdA, 0, _, _, 'prediction_error:').

% The optional strength is identity-bearing: present versus absent differ.
test(predicted_occurrence_strength_identity_bearing) :-
    % The digest used for the references.
    test_co_hex64(H),
    % The occurrent type predicted to occur.
    atom_concat('occurrent:', H, Occ),
    % The predicting agent.
    atom_concat('token_individual:', H, Predictor),
    % A wall-clock window shared by both predictions.
    Window = _{start:"2026-07-23T00:00:00Z", end:"2026-07-24T00:00:00Z"},
    % One prediction carrying an explicit strength.
    WithStrength = _{type:"predicted_occurrence", instantiates:Occ,
                     interval:Window, predictor:Predictor, strength:0.8},
    % One prediction omitting the strength entirely.
    Without = _{type:"predicted_occurrence", instantiates:Occ,
                interval:Window, predictor:Predictor},
    % Identify each.
    causal_core_identify(WithStrength, _, IdWith),
    % And the strength-free sibling.
    causal_core_identify(Without, _, IdWithout),
    % The strength changes the identity, so the two ids differ.
    IdWith \== IdWithout.

% A nested attitude (content = another attitude id) identifies and differs.
test(nested_attitude_identifies) :-
    % The digest used for the references.
    test_co_hex64(H),
    % A believing agent for the inner attitude.
    atom_concat('token_individual:', H, HolderB),
    % A believing agent for the outer attitude.
    atom_concat('continuant:', H, HolderA),
    % The inner attitude's content, a state assertion.
    atom_concat('state_assertion:', H, Content),
    % The inner attitude: B believes a state assertion.
    Inner = _{type:"attitude", holder:HolderB, attitude_type:"believes", content:Content},
    % Identify the inner attitude.
    causal_core_identify(Inner, _, InnerId),
    % The outer attitude's content is the inner attitude id (nesting).
    Outer = _{type:"attitude", holder:HolderA, attitude_type:"believes", content:InnerId},
    % Identify the outer attitude.
    causal_core_identify(Outer, _, OuterId),
    % The outer identifier is minted under the attitude scheme.
    atom_string(OuterA, OuterId),
    % Its prefix is exactly the attitude scheme.
    sub_atom(OuterA, 0, _, _, 'attitude:'),
    % The nested attitudes have distinct identities.
    OuterId \== InnerId.

% Rule 24: an interval carrying BOTH dimensions raises dimension_conflict.
test(predicted_occurrence_dimension_conflict_raises) :-
    % The digest used for the references.
    test_co_hex64(H),
    % The occurrent type predicted to occur.
    atom_concat('occurrent:', H, Occ),
    % The predicting agent.
    atom_concat('token_individual:', H, Predictor),
    % An interval that illegally carries a wall-clock start AND an ordinal start_tick.
    Bad = _{type:"predicted_occurrence", instantiates:Occ,
            interval:_{start:"2026-07-23T00:00:00Z", start_tick:3}, predictor:Predictor},
    % Validate the local semantics for the predicted_occurrence kind.
    causal_core_validate_semantics(Bad, predicted_occurrence, Reasons),
    % Some reason names the dimension conflict (once: a single witness suffices).
    once((
        % Some reason string mentions the conflict.
        member(R, Reasons),
        % Cast the reason to a string for the substring test.
        ( string(R) -> RS = R ; atom_string(R, RS) ),
        % The dimension_conflict wording is present.
        sub_string(RS, _, _, _, "dimension_conflict")
    )).

:- end_tests(co_core_causalontology_4_0_0).
