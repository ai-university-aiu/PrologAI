/*  PrologAI — Belief Structures and Propagators Test Suite  (PR 29)

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/beliefs/test/test_beliefs.pl

    Each test uses its own node ids so no cross-test state leaks; the
    pack auto-creates a default scorecard for any unseen node id.
*/

% Declare this file as a test module.
:- module(test_beliefs, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(beliefs)).

% Open the test block for beliefs.
:- begin_tests(beliefs).

% AC-001: setting then reading a field round-trips the clamped value.
test(belief_get_set_roundtrip) :-
    % Set certainty on a fresh node to 0.75.
    beliefs_belief(rt_node, certainty, 0.75),
    % Read the certainty back into V.
    beliefs_belief(rt_node, certainty, V),
    % The value returned matches what was set.
    assertion(abs(V - 0.75) < 0.001).

% AC-002: an update adds the delta to the current field value.
test(belief_update_delta) :-
    % Seed certainty at 0.5.
    beliefs_belief(upd_node, certainty, 0.5),
    % Add 0.3 to the certainty field.
    beliefs_belief_update(upd_node, certainty, 0.3),
    % Read the updated certainty.
    beliefs_belief(upd_node, certainty, V),
    % The field now holds the summed value 0.8.
    assertion(abs(V - 0.8) < 0.001).

% AC-003: fields are clamped to their legal range on write.
test(field_clamping) :-
    % Try to set certainty above its ceiling of 1.0.
    beliefs_belief(clamp_node, certainty, 5.0),
    % Read the stored certainty.
    beliefs_belief(clamp_node, certainty, C),
    % Certainty is capped at 1.0.
    assertion(C =< 1.0),
    % Try to set desirability below its floor of -1.0.
    beliefs_belief(clamp_node, desirability, -9.0),
    % Read the stored desirability.
    beliefs_belief(clamp_node, desirability, D),
    % Desirability is floored at -1.0.
    assertion(D >= -1.0).

% AC-004: recording attempts drives the likelihood propagator with a prior.
test(attempt_updates_likelihood) :-
    % Two successes and one failure on a learned action.
    beliefs_attempt(learn_action, success),
    beliefs_attempt(learn_action, success),
    beliefs_attempt(learn_action, failure),
    % Read the resulting likelihood.
    beliefs_belief(learn_action, likelihood, L),
    % With the Laplace prior (3 of 5) the likelihood exceeds one half.
    assertion(L > 0.5).

% AC-005: the likelihood propagator never divides by zero on a brand-new node.
test(likelihood_prior_no_zero_division) :-
    % Propagate likelihood on a node with no attempts recorded.
    beliefs_propagate(brand_new_node, likelihood),
    % Read the likelihood.
    beliefs_belief(brand_new_node, likelihood, L),
    % The prior yields a strictly interior probability.
    assertion(L > 0.0),
    assertion(L < 1.0).

% AC-006: coherence is higher with supporting neighbors than contradicting ones.
test(supporting_neighbors_higher_coherence) :-
    % A node whose neighbors all share its positive desirability.
    beliefs_belief(node_a, desirability, 0.8),
    beliefs_belief(nbr1_a, desirability, 0.7),
    beliefs_belief(nbr2_a, desirability, 0.6),
    beliefs_add_neighbor(node_a, nbr1_a),
    beliefs_add_neighbor(node_a, nbr2_a),
    % Compute its coherence from neighbor agreement.
    beliefs_propagate(node_a, coherence),
    beliefs_belief(node_a, coherence, CoA),
    % A node whose neighbors all oppose its positive desirability.
    beliefs_belief(node_b, desirability, 0.8),
    beliefs_belief(nbr1_b, desirability, -0.7),
    beliefs_belief(nbr2_b, desirability, -0.6),
    beliefs_add_neighbor(node_b, nbr1_b),
    beliefs_add_neighbor(node_b, nbr2_b),
    % Compute its coherence from neighbor disagreement.
    beliefs_propagate(node_b, coherence),
    beliefs_belief(node_b, coherence, CoB),
    % Agreement yields strictly higher coherence than disagreement.
    assertion(CoA > CoB).

% AC-007: the arousal propagator blends a node toward its neighbor's arousal.
test(arousal_propagator_blends) :-
    % A calm node next to a highly aroused neighbor.
    beliefs_belief(center_node, arousal, 0.3),
    beliefs_belief(high_nbr, arousal, 0.9),
    beliefs_add_neighbor(center_node, high_nbr),
    % Blend the node's arousal toward its neighbors.
    beliefs_propagate(center_node, arousal),
    % Read the blended arousal.
    beliefs_belief(center_node, arousal, NewA),
    % The node has moved upward toward the neighbor's 0.9.
    assertion(NewA > 0.3).

% AC-008: the full scorecard is returned as a record term.
test(belief_record_full_scorecard) :-
    % Seed certainty on a node to 0.7.
    beliefs_belief(rec_node, certainty, 0.7),
    % Retrieve the complete belief record.
    beliefs_belief_record(rec_node, Record),
    % The record carries every scorecard field, keyed by name.
    Record = record(rec_node,
                    certainty(Ce), coherence(_), likelihood(_),
                    desirability(_), valence(_), arousal(_),
                    attempts(_), successes(_)),
    % The certainty slot holds the value that was set.
    assertion(abs(Ce - 0.7) < 0.001).

% Close the test block for beliefs.
:- end_tests(beliefs).
