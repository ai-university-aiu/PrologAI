/*  Tests for hierarchical_planning — Hierarchical Planning (WP-404, Layer 379)

    A standard PLUnit suite. Run with the full library path so co_core and
    co_plan (which hierarchical_planning requires) resolve:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" packs/hierarchical_planning/test/test_hierarchical_planning.pl
*/

% Declare this file as a test module.
:- module(test_hierarchical_planning, []).
% Load the PLUnit test framework.
:- use_module(library(plunit)).
% Load the module under test from the library path.
:- use_module(library(hierarchical_planning)).
% Load the CRO core, used to read the reified plan back out of the graph.
:- use_module(library(co_core)).
% List helpers used inside the tests.
:- use_module(library(lists), [member/2, memberchk/2]).

% Open the test block for hierarchical_planning.
:- begin_tests(hierarchical_planning).

% The six OODA-style phase names come back in their canonical order.
test(ooda_phases_in_order) :-
    % Read the phase list.
    hierarchical_planning_ooda_phases(Phases),
    % It is exactly the six phases, in order.
    assertion(Phases == [see, observe, orient, decide, act, reobserve_update]).

% Each phase decomposes into concrete, named operations.
test(phase_ops_concrete) :-
    % The observe phase reads meters, locates the avatar, and diffs the frame.
    hierarchical_planning_phase_ops(observe, ObsOps),
    assertion(ObsOps == [read_meters, locate_avatar, diff_frame]),
    % With no game actions, the act phase keeps its generic operation.
    hierarchical_planning_phase_ops(act, ActOps),
    assertion(ActOps == [perform_chosen_action]).

% The top of the plan is Win Game, decomposing to a single OODA-loop node
% that holds the six phases in order.
test(win_plan_shape) :-
    % A small concrete action set for a game.
    Actions = [action(1), action(2), select(x, y)],
    % Build the three-level plan tree.
    hierarchical_planning_win_plan(ls20, Actions, Tree),
    % The top is win(ls20) with one ooda_loop child.
    assertion(Tree = hnode(win(ls20), strategy, [hnode(ooda_loop, cycle, _)])),
    % The loop node holds the six phases in order.
    Tree = hnode(_, _, [hnode(ooda_loop, _, Phases)]),
    findall(P, member(hnode(phase(P), _, _), Phases), Ps),
    assertion(Ps == [see, observe, orient, decide, act, reobserve_update]).

% The act phase's leaves are the game's real controls when actions are given.
test(act_leaves_are_controls) :-
    % Build a plan with a concrete control set.
    Actions = [action(1), action(2), select(x, y)],
    hierarchical_planning_win_plan(ls20, Actions, Tree),
    % Reach into the act phase and check its leaves.
    Tree = hnode(_, _, [hnode(_, _, Phases)]),
    once(member(hnode(phase(act), _, ActLeaves), Phases)),
    assertion(memberchk(hnode(control(action(1)), primitive, []), ActLeaves)),
    assertion(memberchk(hnode(control(select(x, y)), primitive, []), ActLeaves)).

% Reifying the tree creates a root CRO carrying a mechanism sub-graph.
test(reify_builds_mechanism) :-
    % Start from a clean CRO store and a clean plan.
    co_core_reset, hierarchical_planning_reset,
    % Build and reify a plan.
    hierarchical_planning_win_plan(ls20, [action(1), action(2), select(x, y)], Tree),
    hierarchical_planning_reify(Tree, RootId),
    % The root has a non-empty mechanism sub-graph.
    co_mechanism(RootId, Subs),
    assertion(Subs \== []).

% The plan can be read back PURELY from the CRO graph, and the reconstructed
% top goal and its six ordered phases match the original.
test(plan_from_cros_roundtrip) :-
    % A clean slate, then build and reify.
    co_core_reset, hierarchical_planning_reset,
    hierarchical_planning_win_plan(ls20, [action(1), action(2), select(x, y)], Tree),
    hierarchical_planning_reify(Tree, Root),
    % Rebuild the tree from the causal graph alone.
    hierarchical_planning_plan_from_cros(Root, Rebuilt),
    % The reconstructed top goal is win(ls20).
    assertion(Rebuilt = hnode(win(ls20), reified, _)),
    % The same six phases appear in the same order.
    Rebuilt = hnode(_, _, [hnode(ooda_loop, _, RPhases)]),
    findall(P, member(hnode(phase(P), _, _), RPhases), RPs),
    assertion(RPs == [see, observe, orient, decide, act, reobserve_update]).

% The whole reified hierarchy is causally consistent — every coarse relation
% agrees with the composition of its mechanism.
test(reified_hierarchy_consistent) :-
    % A clean slate, then build and reify.
    co_core_reset, hierarchical_planning_reset,
    hierarchical_planning_win_plan(ls20, [action(1), action(2), select(x, y)], Tree),
    hierarchical_planning_reify(Tree, Root),
    % Consistency holds across the whole hierarchy.
    assertion(hierarchical_planning_consistent(Root)).

% The indented text rendering shows the nested levels of the plan.
test(render_shows_levels) :-
    % Build a plan and render it to lines.
    hierarchical_planning_win_plan(ls20, [action(1), action(2), select(x, y)], Tree),
    hierarchical_planning_render(Tree, Lines),
    % The top goal, the loop, and a deep leaf all appear.
    assertion(( member(L1, Lines), sub_atom(L1, _, _, _, 'Win Game') )),
    assertion(( member(L2, Lines), sub_atom(L2, _, _, _, 'OODA') )),
    assertion(( member(L3, Lines), sub_atom(L3, _, _, _, 'perceive the whole grid') )).

% The JSON rendering is a nested dict whose loop node holds six phase dicts.
test(render_json_nested) :-
    % Build a plan and render it to a nested dict.
    hierarchical_planning_win_plan(ls20, [action(1), action(2), select(x, y)], Tree),
    hierarchical_planning_render_json(Tree, Dict),
    % The single child is the loop; its children are the six phases.
    get_dict(children, Dict, [OodaDict]),
    get_dict(children, OodaDict, PhaseDicts),
    assertion(length(PhaseDicts, 6)).

% A solo choice basis is located within the plan as an OODA phase plus a leaf,
% with a total default for unknown bases.
test(classify_basis) :-
    % Causal-change ranking is deciding by predicted effect.
    assertion(hierarchical_planning_classify_basis(explore(causal), decide, op(predict_causal_change))),
    % Object-targeted curiosity is acting toward the object.
    assertion(hierarchical_planning_classify_basis(explore(object(pos(1,2))), act, op(go_to_object))),
    % Replaying a known winning path is acting on a settled plan.
    assertion(hierarchical_planning_classify_basis(replay(win), act, control(replay_winning_path))),
    % Any unrecognised basis defaults to a plain decision.
    assertion(hierarchical_planning_classify_basis(anything_unknown, decide, op(choose_action))).

% Close the test block for hierarchical_planning.
:- end_tests(hierarchical_planning).
