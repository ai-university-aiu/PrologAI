/*  PrologAI — PR 24 Somatic Markers: Affective Pre-Selection Acceptance Tests

    AC-PR24-001: A causal_plan stamped 3× with strongly negative valence (-0.9)
                 is filtered out from deliberation candidates.
    AC-PR24-002: A plan stamped with strongly positive valence (+0.8) appears
                 at the front of the filtered candidate list.
    AC-PR24-003: A negatively marked plan with an explicit override is kept.
    AC-PR24-004: pai_marker_of returns neutral (0,0,0) for an unknown plan.
    AC-PR24-005: pai_marker_stamp updates the mean correctly after 3 stamps.
    AC-PR24-006: pai_marker_decay moves marker means toward 0.0.
    AC-PR24-007: Candidates with no marker pass through filter unchanged.
    AC-PR24-008: pai_marker_override registers correctly and suppresses prune.
    AC-PR24-009: min_count option prevents pruning when stamp count is below N.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/markers/prolog'], MarkersPath),
   assertz(file_search_path(library, MarkersPath)).

:- use_module(library(plunit)).
:- use_module(library(markers), [
    pai_marker_stamp/2,
    pai_marker_of/2,
    pai_marker_filter/3,
    pai_marker_decay/0,
    pai_marker_override/2
]).

:- begin_tests(pr24, [setup(pr24_setup), cleanup(pr24_cleanup)]).

pr24_setup :-
    retractall(markers:plan_marker(_, _, _, _)),
    retractall(markers:marker_override(_, _)).

pr24_cleanup :-
    retractall(markers:plan_marker(_, _, _, _)),
    retractall(markers:marker_override(_, _)).

%  AC-PR24-001: 3× negative stamps → plan pruned from candidates
test(negative_plan_pruned) :-
    forall(
        between(1, 3, _),
        pai_marker_stamp(bad_plan, episode(-0.9, 0.5))
    ),
    pai_marker_filter([bad_plan, good_plan], [], Filtered),
    \+ memberchk(bad_plan, Filtered),
    memberchk(good_plan, Filtered).

%  AC-PR24-002: positive plan appears first in filtered list
test(positive_plan_first) :-
    forall(
        between(1, 3, _),
        pai_marker_stamp(great_plan, episode(0.8, 0.6))
    ),
    pai_marker_filter([neutral_plan, great_plan], [], Filtered),
    Filtered = [great_plan | _].

%  AC-PR24-003: override keeps negatively marked plan
test(override_keeps_negative_plan) :-
    forall(
        between(1, 3, _),
        pai_marker_stamp(override_plan, episode(-0.9, 0.5))
    ),
    pai_marker_filter([override_plan], [override(override_plan)], Filtered),
    memberchk(override_plan, Filtered).

%  AC-PR24-004: unknown plan → neutral marker (0, 0, 0)
test(unknown_plan_neutral_marker) :-
    pai_marker_of(totally_unknown_plan_xyz, Marker),
    Marker = marker(0.0, 0.0, 0).

%  AC-PR24-005: stamp updates mean correctly
%  After stamping -1.0, -1.0, -1.0: mean should be -1.0
test(marker_stamp_updates_mean) :-
    forall(
        between(1, 3, _),
        pai_marker_stamp(stamp_test, episode(-1.0, 0.0))
    ),
    pai_marker_of(stamp_test, marker(MeanV, _, Count)),
    Count =:= 3,
    abs(MeanV - (-1.0)) < 0.001.

%  AC-PR24-006: decay moves marker toward 0.0
test(decay_moves_toward_neutral) :-
    pai_marker_stamp(decay_plan, episode(-0.8, 0.6)),
    pai_marker_of(decay_plan, marker(V0, _, _)),
    pai_marker_decay,
    pai_marker_of(decay_plan, marker(V1, _, _)),
    abs(V1) < abs(V0).

%  AC-PR24-007: candidates with no marker pass through unchanged
test(no_marker_passes_through) :-
    pai_marker_filter([plan_x, plan_y], [], Filtered),
    memberchk(plan_x, Filtered),
    memberchk(plan_y, Filtered).

%  AC-PR24-008: pai_marker_override registers and suppresses prune
test(marker_override_registered) :-
    forall(
        between(1, 3, _),
        pai_marker_stamp(reg_plan, episode(-0.9, 0.5))
    ),
    pai_marker_override(reg_plan, explicit_safety_evidence),
    pai_marker_filter([reg_plan], [], Filtered),
    memberchk(reg_plan, Filtered).

%  AC-PR24-009: min_count=5 prevents prune when only 3 stamps exist
test(min_count_prevents_premature_prune) :-
    forall(
        between(1, 3, _),
        pai_marker_stamp(few_stamp_plan, episode(-0.9, 0.5))
    ),
    pai_marker_filter([few_stamp_plan], [min_count(5)], Filtered),
    memberchk(few_stamp_plan, Filtered).

:- end_tests(pr24).
