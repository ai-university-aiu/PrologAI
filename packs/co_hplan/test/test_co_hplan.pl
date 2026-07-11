/*  Tests for co_hplan — Hierarchical Planning (WP-404, Layer 379)

    Each acceptance criterion prints PASS or FAIL.

    Run with the co_core, co_plan, co_learn, and co_hplan prolog dirs on the path:
      swipl -p library=... -g run_tests -t halt packs/co_hplan/test/test_co_hplan.pl
*/

% Load the pack under test.
:- use_module('../prolog/co_hplan').
% Load the CRO core, to read the reified plan back.
:- use_module(library(co_core)).
% List helpers.
:- use_module(library(lists), [member/2, memberchk/2, flatten/2]).

% report(+Id, +Goal): print PASS or FAIL for one criterion.
report(Id, Goal) :-
    ( catch(Goal, E, (format("  error: ~q~n", [E]), fail))
    -> V = 'PASS' ; V = 'FAIL' ),
    format("~w: ~w~n", [Id, V]).

% run_tests: exercise the hierarchical planner and its Causalontology mesh.
run_tests :-
    % Announce.
    format("~n=== co_hplan — Hierarchical Planning ===~n~n", []),
    % A clean slate.
    co_core_reset, hp_reset,
    % A small concrete action set for a game.
    Actions = [action(1), action(2), select(x, y)],
    % Build the plan tree for a game.
    hp_win_plan(ls20, Actions, Tree),

    % AC-HP-001: the top is Win Game, decomposing to a single OODA-loop node.
    report('AC-HP-001',
        ( Tree = hnode(win(ls20), strategy, [hnode(ooda_loop, cycle, _)]) )),

    % AC-HP-002: the OODA node holds the six phases, in order.
    report('AC-HP-002',
        ( Tree = hnode(_, _, [hnode(ooda_loop, _, Phases)]),
          findall(P, member(hnode(phase(P), _, _), Phases), Ps),
          Ps == [see, observe, orient, decide, act, reobserve_update] )),

    % AC-HP-003: the act phase's leaves are the game's real controls.
    report('AC-HP-003',
        ( Tree = hnode(_, _, [hnode(_, _, Phases2)]),
          member(hnode(phase(act), _, ActLeaves), Phases2),
          memberchk(hnode(control(action(1)), primitive, []), ActLeaves),
          memberchk(hnode(control(select(x, y)), primitive, []), ActLeaves) )),

    % AC-HP-004: reifying the tree creates a root CRO with a mechanism sub-graph.
    report('AC-HP-004',
        ( hp_reify(Tree, RootId),
          co_mechanism(RootId, Subs), Subs \== [] )),

    % Reify once for the reads below.
    ( hp_reify(Tree, Root) -> true ; Root = none ),

    % AC-HP-005: the plan can be read back PURELY from the CRO graph, and the
    % reconstructed top goal is win(ls20).
    report('AC-HP-005',
        ( hp_plan_from_cros(Root, Rebuilt),
          Rebuilt = hnode(win(ls20), reified, _) )),

    % AC-HP-006: the reconstructed plan has the same six phases in order.
    report('AC-HP-006',
        ( hp_plan_from_cros(Root, Rebuilt2),
          Rebuilt2 = hnode(_, _, [hnode(ooda_loop, _, RPhases)]),
          findall(P, member(hnode(phase(P), _, _), RPhases), RPs),
          RPs == [see, observe, orient, decide, act, reobserve_update] )),

    % AC-HP-007: the whole reified hierarchy is causally consistent — every coarse
    % relation agrees with the composition of its mechanism (the mesh is coherent).
    report('AC-HP-007', hp_consistent(Root)),

    % AC-HP-008: the text rendering shows the nested levels.
    report('AC-HP-008',
        ( hp_render(Tree, Lines),
          ( member(L1, Lines), sub_atom(L1, _, _, _, 'Win Game') ),
          ( member(L2, Lines), sub_atom(L2, _, _, _, 'OODA') ),
          ( member(L3, Lines), sub_atom(L3, _, _, _, 'perceive the whole grid') ) )),

    % AC-HP-009: the JSON rendering is a nested dict with children.
    report('AC-HP-009',
        ( hp_render_json(Tree, Dict),
          get_dict(children, Dict, [OodaDict]),
          get_dict(children, OodaDict, PhaseDicts),
          length(PhaseDicts, 6) )),

    % AC-HP-010: a solo choice basis is located within the plan (OODA phase + leaf).
    report('AC-HP-010',
        ( hp_classify_basis(explore(causal), decide, op(predict_causal_change)),
          hp_classify_basis(explore(object(pos(1,2))), act, op(go_to_object)) )),

    % Show the plan as the glass box renders it.
    ( hp_render(Tree, Show) -> true ; Show = [] ),
    format("~nThe plan tree:~n", []),
    forall(member(Ln, Show), format("  ~w~n", [Ln])),
    format("~n", []).
