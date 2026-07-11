/*  Tests for co_wm — World Model (WP-407)
    Run: swipl -p library=packs/co_wm/prolog -g run_tests -t halt packs/co_wm/test/test_co_wm.pl
*/
:- use_module('../prolog/co_wm').
:- use_module(library(lists), [member/2]).

report(Id, Goal) :-
    ( catch(Goal, E, (format("  error: ~q~n",[E]), fail)) -> V='PASS' ; V='FAIL' ),
    format("~w: ~w~n", [Id, V]).

run_tests :-
    format("~n=== co_wm — World Model ===~n~n", []),
    wm_reset, M = game,

    % AC-WM-001: after observing a transition, the model predicts it.
    report('AC-WM-001',
        ( wm_observe(M, any, right, move_east),
          wm_predict(M, any, right, E), E == move_east )),

    % AC-WM-002: the majority effect wins, with a confidence share.
    report('AC-WM-002',
        ( wm_observe(M, any, right, move_east), wm_observe(M, any, right, move_east),
          wm_observe(M, any, right, blocked),
          wm_predict(M, any, right, E2, C), E2 == move_east, C > 0.6 )),

    % AC-WM-003: a context-specific effect overrides the general one.
    report('AC-WM-003',
        ( wm_observe(M, on_ice, right, slide_far),
          wm_observe(M, on_ice, right, slide_far),
          wm_predict(M, on_ice, right, E3), E3 == slide_far )),

    % AC-WM-004: an UNSEEN context falls back to the action-general rule.
    report('AC-WM-004',
        ( wm_predict(M, brand_new_context, right, E4), E4 == move_east )),

    % AC-WM-005: verify reports a match when reality agrees with the prediction.
    report('AC-WM-005',
        ( wm_verify(M, any, right, move_east, R), R == match )),

    % AC-WM-006: verify reports a mismatch (the repair signal) when it disagrees.
    report('AC-WM-006',
        ( wm_verify(M, any, right, teleport, R2), R2 = mismatch(move_east, teleport) )),

    % AC-WM-007: repair folds the truth in; enough repairs flip the prediction.
    report('AC-WM-007',
        ( forall(between(1,10,_), wm_repair(M, any, right, teleport)),
          wm_predict(M, any, right, E7), E7 == teleport )),

    % AC-WM-008: rollout predicts a whole action sequence (plan-in-model).
    report('AC-WM-008',
        ( wm_reset, wm_observe(M, any, a, x), wm_observe(M, any, b, y),
          wm_rollout(M, any, [a,b,a], Effects), Effects == [x,y,x] )),

    % AC-WM-009: a context-free action is surfaced as a general LAW; a context-
    % dependent one is not.
    report('AC-WM-009',
        ( wm_reset,
          wm_observe(M, c1, up, jump), wm_observe(M, c2, up, jump),
          wm_observe(M, c1, down, fall), wm_observe(M, c2, down, sink),
          wm_law(M, up, jump), \+ wm_law(M, down, _) )),

    format("~n", []).

:- use_module(library(lists), [between/3]).
