/*  PrologAI — PR 29 Belief Structures and Propagators Acceptance Tests

    AC-PR29-001: A node_fact with all-supporting neighbors has higher coherence
                 than one with contradicting neighbors.
    AC-PR29-002: Likelihood propagator uses prior (never divides by zero).
    AC-PR29-003: beliefs_belief get/set round-trip for all fields.
    AC-PR29-004: beliefs_belief_update increments a field by delta (clamped).
    AC-PR29-005: arousal propagator blends neighbor arousal toward local value.
    AC-PR29-006: desirability propagator blends neighbor desirability.
    AC-PR29-007: beliefs_attempt records success and updates likelihood.
    AC-PR29-008: beliefs_belief_record returns a full scorecard.
    AC-PR29-009: Certainty clamped to [0,1]; desirability clamped to [-1,1].
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/beliefs/prolog'], BeliefsPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, BeliefsPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'beliefs' library so its predicates are available here.
:- use_module(library(beliefs), [
    % Supply 'beliefs_belief/3' as the next argument to the expression above.
    beliefs_belief/3,
    % Supply 'beliefs_belief_update/3' as the next argument to the expression above.
    beliefs_belief_update/3,
    % Supply 'beliefs_propagate/2' as the next argument to the expression above.
    beliefs_propagate/2,
    % Supply 'beliefs_belief_record/2' as the next argument to the expression above.
    beliefs_belief_record/2,
    % Supply 'beliefs_add_neighbor/2' as the next argument to the expression above.
    beliefs_add_neighbor/2,
    % Supply 'beliefs_attempt/2' as the next argument to the expression above.
    beliefs_attempt/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr29, [setup(pr29_setup), cleanup(pr29_cleanup)]).
:- begin_tests(pr29, [setup(pr29_setup), cleanup(pr29_cleanup)]).

% Execute: pr29_setup :-.
pr29_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(beliefs:belief_record(_, _, _, _, _, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(beliefs:neighbor_edge(_, _)).

% Execute: pr29_cleanup :-.
pr29_cleanup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(beliefs:belief_record(_, _, _, _, _, _, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(beliefs:neighbor_edge(_, _)).

%  AC-PR29-001: all-supporting neighbors → higher coherence than contradicting
% Define a clause for 'test': succeed when the following conditions hold.
test(supporting_neighbors_higher_coherence) :-
    % node_a has positive desirability, neighbors all positive → agree
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(node_a, desirability, 0.8),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(nbr1_a, desirability, 0.7),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(nbr2_a, desirability, 0.6),
    % State a fact for 'pai add neighbor' with the arguments listed below.
    beliefs_add_neighbor(node_a, nbr1_a),
    % State a fact for 'pai add neighbor' with the arguments listed below.
    beliefs_add_neighbor(node_a, nbr2_a),
    % State a fact for 'pai propagate' with the arguments listed below.
    beliefs_propagate(node_a, coherence),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(node_a, coherence, CoA),
    % node_b has positive desirability, neighbors all negative → contradict
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(node_b, desirability, 0.8),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(nbr1_b, desirability, -0.7),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(nbr2_b, desirability, -0.6),
    % State a fact for 'pai add neighbor' with the arguments listed below.
    beliefs_add_neighbor(node_b, nbr1_b),
    % State a fact for 'pai add neighbor' with the arguments listed below.
    beliefs_add_neighbor(node_b, nbr2_b),
    % State a fact for 'pai propagate' with the arguments listed below.
    beliefs_propagate(node_b, coherence),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(node_b, coherence, CoB),
    % Check that 'CoA' is greater than 'CoB'.
    CoA > CoB.

%  AC-PR29-002: likelihood with no attempts uses prior (no divide-by-zero)
% Define a clause for 'test': succeed when the following conditions hold.
test(likelihood_prior_no_zero_division) :-
    % State a fact for 'pai propagate' with the arguments listed below.
    beliefs_propagate(brand_new_node, likelihood),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(brand_new_node, likelihood, L),
    % Check that 'L' is greater than '0.0, L < 1.0'.
    L > 0.0, L < 1.0.

%  AC-PR29-003: get/set round-trip for certainty
% Define a clause for 'test': succeed when the following conditions hold.
test(belief_get_set_roundtrip) :-
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(rt_node, certainty, 0.75),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(rt_node, certainty, V),
    % Check that 'abs(V - 0.75)' is less than '0.001'.
    abs(V - 0.75) < 0.001.

%  AC-PR29-004: update increments certainty by delta, clamped
% Define a clause for 'test': succeed when the following conditions hold.
test(belief_update_delta) :-
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(upd_node, certainty, 0.5),
    % State a fact for 'pai belief update' with the arguments listed below.
    beliefs_belief_update(upd_node, certainty, 0.3),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(upd_node, certainty, V),
    % Check that 'abs(V - 0.8)' is less than '0.001'.
    abs(V - 0.8) < 0.001.

%  AC-PR29-005: arousal propagator blends neighbor arousal
% Define a clause for 'test': succeed when the following conditions hold.
test(arousal_propagator_blends) :-
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(center_node, arousal, 0.3),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(high_nbr, arousal, 0.9),
    % State a fact for 'pai add neighbor' with the arguments listed below.
    beliefs_add_neighbor(center_node, high_nbr),
    % State a fact for 'pai propagate' with the arguments listed below.
    beliefs_propagate(center_node, arousal),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(center_node, arousal, NewA),
    % Check that 'NewA' is greater than '0.3.   % moved toward neighbor's 0.9'.
    NewA > 0.3.   % moved toward neighbor's 0.9

%  AC-PR29-006: desirability propagator blends neighbor desirability
% Define a clause for 'test': succeed when the following conditions hold.
test(desirability_propagator_blends) :-
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(d_center, desirability, 0.0),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(d_nbr, desirability, 0.8),
    % State a fact for 'pai add neighbor' with the arguments listed below.
    beliefs_add_neighbor(d_center, d_nbr),
    % State a fact for 'pai propagate' with the arguments listed below.
    beliefs_propagate(d_center, desirability),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(d_center, desirability, NewD),
    % Check that 'NewD' is greater than '0.0'.
    NewD > 0.0.

%  AC-PR29-007: beliefs_attempt records success and updates likelihood
% Define a clause for 'test': succeed when the following conditions hold.
test(attempt_updates_likelihood) :-
    % State a fact for 'pai attempt' with the arguments listed below.
    beliefs_attempt(learn_action, success),
    % State a fact for 'pai attempt' with the arguments listed below.
    beliefs_attempt(learn_action, success),
    % State a fact for 'pai attempt' with the arguments listed below.
    beliefs_attempt(learn_action, failure),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(learn_action, likelihood, L),
    % 2 successes + 1 prior success = 3 su, 3 attempts + 2 prior = 5 at → L = 0.6
    % Check that 'L' is greater than '0.5'.
    L > 0.5.

%  AC-PR29-008: beliefs_belief_record returns full scorecard
% Define a clause for 'test': succeed when the following conditions hold.
test(belief_record_full_scorecard) :-
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(rec_node, certainty, 0.7),
    % State a fact for 'pai belief record' with the arguments listed below.
    beliefs_belief_record(rec_node, Record),
    % Check that 'Record' is unifiable with 'record(rec_node'.
    Record = record(rec_node,
        % Continue the multi-line expression started above.
        certainty(Ce), coherence(_), likelihood(_),
        % Continue the multi-line expression started above.
        desirability(_), valence(_), arousal(_),
        % Continue the multi-line expression started above.
        attempts(_), successes(_)),
    % Check that 'abs(Ce - 0.7)' is less than '0.001'.
    abs(Ce - 0.7) < 0.001.

%  AC-PR29-009: certainty clamped to [0,1]; desirability clamped to [-1,1]
% Define a clause for 'test': succeed when the following conditions hold.
test(field_clamping) :-
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(clamp_node, certainty, 5.0),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(clamp_node, certainty, C),
    % Check that 'C' is less than or equal to '1.0'.
    C =< 1.0,
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(clamp_node, desirability, -9.0),
    % State a fact for 'pai belief' with the arguments listed below.
    beliefs_belief(clamp_node, desirability, D),
    % Check that 'D' is greater than or equal to '-1.0'.
    D >= -1.0.

% Execute the compile-time directive: end_tests(pr29).
:- end_tests(pr29).
