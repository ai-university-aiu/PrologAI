/*  PrologAI — PR 29 Belief Structures and Propagators Acceptance Tests

    AC-PR29-001: A node_fact with all-supporting neighbors has higher coherence
                 than one with contradicting neighbors.
    AC-PR29-002: Likelihood propagator uses prior (never divides by zero).
    AC-PR29-003: pai_belief get/set round-trip for all fields.
    AC-PR29-004: pai_belief_update increments a field by delta (clamped).
    AC-PR29-005: arousal propagator blends neighbor arousal toward local value.
    AC-PR29-006: desirability propagator blends neighbor desirability.
    AC-PR29-007: pai_attempt records success and updates likelihood.
    AC-PR29-008: pai_belief_record returns a full scorecard.
    AC-PR29-009: Certainty clamped to [0,1]; desirability clamped to [-1,1].
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/beliefs/prolog'], BeliefsPath),
   assertz(file_search_path(library, BeliefsPath)).

:- use_module(library(plunit)).
:- use_module(library(beliefs), [
    pai_belief/3,
    pai_belief_update/3,
    pai_propagate/2,
    pai_belief_record/2,
    pai_add_neighbor/2,
    pai_attempt/2
]).

:- begin_tests(pr29, [setup(pr29_setup), cleanup(pr29_cleanup)]).

pr29_setup :-
    retractall(beliefs:belief_record(_, _, _, _, _, _, _, _, _)),
    retractall(beliefs:neighbor_edge(_, _)).

pr29_cleanup :-
    retractall(beliefs:belief_record(_, _, _, _, _, _, _, _, _)),
    retractall(beliefs:neighbor_edge(_, _)).

%  AC-PR29-001: all-supporting neighbors → higher coherence than contradicting
test(supporting_neighbors_higher_coherence) :-
    % node_a has positive desirability, neighbors all positive → agree
    pai_belief(node_a, desirability, 0.8),
    pai_belief(nbr1_a, desirability, 0.7),
    pai_belief(nbr2_a, desirability, 0.6),
    pai_add_neighbor(node_a, nbr1_a),
    pai_add_neighbor(node_a, nbr2_a),
    pai_propagate(node_a, coherence),
    pai_belief(node_a, coherence, CoA),
    % node_b has positive desirability, neighbors all negative → contradict
    pai_belief(node_b, desirability, 0.8),
    pai_belief(nbr1_b, desirability, -0.7),
    pai_belief(nbr2_b, desirability, -0.6),
    pai_add_neighbor(node_b, nbr1_b),
    pai_add_neighbor(node_b, nbr2_b),
    pai_propagate(node_b, coherence),
    pai_belief(node_b, coherence, CoB),
    CoA > CoB.

%  AC-PR29-002: likelihood with no attempts uses prior (no divide-by-zero)
test(likelihood_prior_no_zero_division) :-
    pai_propagate(brand_new_node, likelihood),
    pai_belief(brand_new_node, likelihood, L),
    L > 0.0, L < 1.0.

%  AC-PR29-003: get/set round-trip for certainty
test(belief_get_set_roundtrip) :-
    pai_belief(rt_node, certainty, 0.75),
    pai_belief(rt_node, certainty, V),
    abs(V - 0.75) < 0.001.

%  AC-PR29-004: update increments certainty by delta, clamped
test(belief_update_delta) :-
    pai_belief(upd_node, certainty, 0.5),
    pai_belief_update(upd_node, certainty, 0.3),
    pai_belief(upd_node, certainty, V),
    abs(V - 0.8) < 0.001.

%  AC-PR29-005: arousal propagator blends neighbor arousal
test(arousal_propagator_blends) :-
    pai_belief(center_node, arousal, 0.3),
    pai_belief(high_nbr, arousal, 0.9),
    pai_add_neighbor(center_node, high_nbr),
    pai_propagate(center_node, arousal),
    pai_belief(center_node, arousal, NewA),
    NewA > 0.3.   % moved toward neighbor's 0.9

%  AC-PR29-006: desirability propagator blends neighbor desirability
test(desirability_propagator_blends) :-
    pai_belief(d_center, desirability, 0.0),
    pai_belief(d_nbr, desirability, 0.8),
    pai_add_neighbor(d_center, d_nbr),
    pai_propagate(d_center, desirability),
    pai_belief(d_center, desirability, NewD),
    NewD > 0.0.

%  AC-PR29-007: pai_attempt records success and updates likelihood
test(attempt_updates_likelihood) :-
    pai_attempt(learn_action, success),
    pai_attempt(learn_action, success),
    pai_attempt(learn_action, failure),
    pai_belief(learn_action, likelihood, L),
    % 2 successes + 1 prior success = 3 su, 3 attempts + 2 prior = 5 at → L = 0.6
    L > 0.5.

%  AC-PR29-008: pai_belief_record returns full scorecard
test(belief_record_full_scorecard) :-
    pai_belief(rec_node, certainty, 0.7),
    pai_belief_record(rec_node, Record),
    Record = record(rec_node,
        certainty(Ce), coherence(_), likelihood(_),
        desirability(_), valence(_), arousal(_),
        attempts(_), successes(_)),
    abs(Ce - 0.7) < 0.001.

%  AC-PR29-009: certainty clamped to [0,1]; desirability clamped to [-1,1]
test(field_clamping) :-
    pai_belief(clamp_node, certainty, 5.0),
    pai_belief(clamp_node, certainty, C),
    C =< 1.0,
    pai_belief(clamp_node, desirability, -9.0),
    pai_belief(clamp_node, desirability, D),
    D >= -1.0.

:- end_tests(pr29).
