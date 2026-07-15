/*  PrologAI — PR 24 Somatic Markers: Affective Pre-Selection Acceptance Tests

    AC-PR24-001: A causal_plan stamped 3× with strongly negative valence (-0.9)
                 is filtered out from deliberation candidates.
    AC-PR24-002: A plan stamped with strongly positive valence (+0.8) appears
                 at the front of the filtered candidate list.
    AC-PR24-003: A negatively marked plan with an explicit override is kept.
    AC-PR24-004: markers_marker_of returns neutral (0,0,0) for an unknown plan.
    AC-PR24-005: markers_marker_stamp updates the mean correctly after 3 stamps.
    AC-PR24-006: markers_marker_decay moves marker means toward 0.0.
    AC-PR24-007: Candidates with no marker pass through filter unchanged.
    AC-PR24-008: markers_marker_override registers correctly and suppresses prune.
    AC-PR24-009: min_count option prevents pruning when stamp count is below N.
*/

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/markers/prolog'], MarkersPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, MarkersPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'markers' library so its predicates are available here.
:- use_module(library(markers), [
    % Supply 'markers_marker_stamp/2' as the next argument to the expression above.
    markers_marker_stamp/2,
    % Supply 'markers_marker_of/2' as the next argument to the expression above.
    markers_marker_of/2,
    % Supply 'markers_marker_filter/3' as the next argument to the expression above.
    markers_marker_filter/3,
    % Supply 'markers_marker_decay/0' as the next argument to the expression above.
    markers_marker_decay/0,
    % Supply 'markers_marker_override/2' as the next argument to the expression above.
    markers_marker_override/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr24, [setup(pr24_setup), cleanup(pr24_cleanup)]).
:- begin_tests(pr24, [setup(pr24_setup), cleanup(pr24_cleanup)]).

% Execute: pr24_setup :-.
pr24_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(markers:plan_marker(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(markers:marker_override(_, _)).

% Execute: pr24_cleanup :-.
pr24_cleanup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(markers:plan_marker(_, _, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(markers:marker_override(_, _)).

%  AC-PR24-001: 3× negative stamps → plan pruned from candidates
% Define a clause for 'test': succeed when the following conditions hold.
test(negative_plan_pruned) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        markers_marker_stamp(bad_plan, episode(-0.9, 0.5))
    % Close the expression opened above.
    ),
    % State a fact for 'pai marker filter' with the arguments listed below.
    markers_marker_filter([bad_plan, good_plan], [], Filtered),
    % Succeed only if 'memberchk(bad_plan, Filtered' cannot be proved (negation as failure).
    \+ memberchk(bad_plan, Filtered),
    % State the fact: memberchk(good_plan, Filtered).
    memberchk(good_plan, Filtered).

%  AC-PR24-002: positive plan appears first in filtered list
% Define a clause for 'test': succeed when the following conditions hold.
test(positive_plan_first) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        markers_marker_stamp(great_plan, episode(0.8, 0.6))
    % Close the expression opened above.
    ),
    % State a fact for 'pai marker filter' with the arguments listed below.
    markers_marker_filter([neutral_plan, great_plan], [], Filtered),
    % Check that 'Filtered' is unifiable with '[great_plan | _]'.
    Filtered = [great_plan | _].

%  AC-PR24-003: override keeps negatively marked plan
% Define a clause for 'test': succeed when the following conditions hold.
test(override_keeps_negative_plan) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        markers_marker_stamp(override_plan, episode(-0.9, 0.5))
    % Close the expression opened above.
    ),
    % State a fact for 'pai marker filter' with the arguments listed below.
    markers_marker_filter([override_plan], [override(override_plan)], Filtered),
    % State the fact: memberchk(override_plan, Filtered).
    memberchk(override_plan, Filtered).

%  AC-PR24-004: unknown plan → neutral marker (0, 0, 0)
% Define a clause for 'test': succeed when the following conditions hold.
test(unknown_plan_neutral_marker) :-
    % State a fact for 'pai marker of' with the arguments listed below.
    markers_marker_of(totally_unknown_plan_xyz, Marker),
    % Check that 'Marker' is unifiable with 'marker(0.0, 0.0, 0)'.
    Marker = marker(0.0, 0.0, 0).

%  AC-PR24-005: stamp updates mean correctly
%  After stamping -1.0, -1.0, -1.0: mean should be -1.0
% Define a clause for 'test': succeed when the following conditions hold.
test(marker_stamp_updates_mean) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        markers_marker_stamp(stamp_test, episode(-1.0, 0.0))
    % Close the expression opened above.
    ),
    % State a fact for 'pai marker of' with the arguments listed below.
    markers_marker_of(stamp_test, marker(MeanV, _, Count)),
    % Check that 'Count' is numerically equal to '3'.
    Count =:= 3,
    % Check that 'abs(MeanV - (-1.0))' is less than '0.001'.
    abs(MeanV - (-1.0)) < 0.001.

%  AC-PR24-006: decay moves marker toward 0.0
% Define a clause for 'test': succeed when the following conditions hold.
test(decay_moves_toward_neutral) :-
    % State a fact for 'pai marker stamp' with the arguments listed below.
    markers_marker_stamp(decay_plan, episode(-0.8, 0.6)),
    % State a fact for 'pai marker of' with the arguments listed below.
    markers_marker_of(decay_plan, marker(V0, _, _)),
    % Call the goal 'markers_marker_decay'.
    markers_marker_decay,
    % State a fact for 'pai marker of' with the arguments listed below.
    markers_marker_of(decay_plan, marker(V1, _, _)),
    % Check that 'abs(V1)' is less than 'abs(V0)'.
    abs(V1) < abs(V0).

%  AC-PR24-007: candidates with no marker pass through unchanged
% Define a clause for 'test': succeed when the following conditions hold.
test(no_marker_passes_through) :-
    % State a fact for 'pai marker filter' with the arguments listed below.
    markers_marker_filter([plan_x, plan_y], [], Filtered),
    % State a fact for 'memberchk' with the arguments listed below.
    memberchk(plan_x, Filtered),
    % State the fact: memberchk(plan_y, Filtered).
    memberchk(plan_y, Filtered).

%  AC-PR24-008: markers_marker_override registers and suppresses prune
% Define a clause for 'test': succeed when the following conditions hold.
test(marker_override_registered) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        markers_marker_stamp(reg_plan, episode(-0.9, 0.5))
    % Close the expression opened above.
    ),
    % State a fact for 'pai marker override' with the arguments listed below.
    markers_marker_override(reg_plan, explicit_safety_evidence),
    % State a fact for 'pai marker filter' with the arguments listed below.
    markers_marker_filter([reg_plan], [], Filtered),
    % State the fact: memberchk(reg_plan, Filtered).
    memberchk(reg_plan, Filtered).

%  AC-PR24-009: min_count=5 prevents prune when only 3 stamps exist
% Define a clause for 'test': succeed when the following conditions hold.
test(min_count_prevents_premature_prune) :-
    % Verify that for every solution of the Condition, the Action also holds.
    forall(
        % Continue the multi-line expression started above.
        between(1, 3, _),
        % Continue the multi-line expression started above.
        markers_marker_stamp(few_stamp_plan, episode(-0.9, 0.5))
    % Close the expression opened above.
    ),
    % State a fact for 'pai marker filter' with the arguments listed below.
    markers_marker_filter([few_stamp_plan], [min_count(5)], Filtered),
    % State the fact: memberchk(few_stamp_plan, Filtered).
    memberchk(few_stamp_plan, Filtered).

% Execute the compile-time directive: end_tests(pr24).
:- end_tests(pr24).
