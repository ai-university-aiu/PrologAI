/*  Round-trip tests for the cognitive-pack snapshot/restore exports.

    Proves that co_wm, co_hypo, and co_goalinfer can each serialise their learned
    state out to a ground term and rebuild an identical state from it — the property
    Mentova relies on to persist a play session's cognition to disk and share it
    across the solo, human-guided, and AI-guided players.
*/

% Load the three packs under test from their pack directories.
:- use_module('../prolog/co_wm').
:- use_module('../../co_hypo/prolog/co_hypo').
:- use_module('../../co_goalinfer/prolog/co_goalinfer').

% Announce a passing check.
ok(Name) :- format("PASS ~w~n", [Name]).
% Announce and count a failing check.
bad(Name) :- format("FAIL ~w~n", [Name]), nb_setval(fails, 1).

% ===========================================================================
% co_wm — a model's transitions survive a snapshot/restore round-trip.
% ===========================================================================
test_wm :-
    wm_reset,
    % Teach a small model two transitions for game g1 and one for g2.
    wm_observe(g1, ctxA, act1, moved),
    wm_observe(g1, ctxA, act1, moved),
    wm_observe(g1, ctxB, act2, blocked),
    wm_observe(g2, ctxA, act1, spun),
    % Snapshot g1 only.
    wm_snapshot(g1, Snap),
    ( Snap == [obs(ctxA, act1, moved, 2), obs(ctxB, act2, blocked, 1)]
    -> ok('WM-001 snapshot captures exactly g1 with counts')
    ;  bad('WM-001'), format("   got ~q~n", [Snap]) ),
    % Wipe g1, then restore it from the snapshot.
    wm_reset,
    wm_restore(g1, Snap),
    ( wm_predict(g1, ctxA, act1, moved, _), wm_predict(g1, ctxB, act2, blocked, _)
    -> ok('WM-002 restored model predicts as before')
    ;  bad('WM-002') ),
    % Restore is idempotent: loading twice does not double the counts.
    wm_restore(g1, Snap),
    ( wm_snapshot(g1, Snap) -> ok('WM-003 restore is idempotent') ; bad('WM-003') ).

% ===========================================================================
% co_hypo — a model's hypotheses and commitment survive the round-trip.
% ===========================================================================
test_hypo :-
    hy_reset,
    % Build strong support for one hypothesis so it commits.
    forall(between(1, 8, _), hy_support(g1, productive(act1))),
    hy_contradict(g1, productive(act2)),
    hy_update_commitment(g1),
    ( hy_committed(g1, productive(act1))
    -> ok('HY-001 committed the well-supported hypothesis')
    ;  bad('HY-001') ),
    % Snapshot, wipe, restore.
    hy_snapshot(g1, Snap),
    hy_reset,
    hy_restore(g1, Snap),
    ( hy_committed(g1, productive(act1))
    -> ok('HY-002 restored commitment survives')
    ;  bad('HY-002') ),
    ( hy_score(g1, productive(act1), Sc), Sc > 0.8
    -> ok('HY-003 restored evidence yields the same high score')
    ;  bad('HY-003') ).

% ===========================================================================
% co_goalinfer — accumulated goal evidence survives the round-trip.
% ===========================================================================
test_goalinfer :-
    cgi_reset,
    % Two wins that both light colour 4, and one loss on colour 7.
    cgi_observe([changed(1, 1, 0, 4)], win),
    cgi_observe([changed(2, 2, 0, 4)], win),
    cgi_observe([changed(3, 3, 0, 7)], game_over),
    ( cgi_hypothesise_goal(reach_colour(4))
    -> ok('GI-001 inferred the winning colour')
    ;  bad('GI-001') ),
    cgi_snapshot(Snap),
    cgi_reset,
    cgi_restore(Snap),
    ( cgi_hypothesise_goal(reach_colour(4)), cgi_win_count(2)
    -> ok('GI-002 restored goal inference and win count survive')
    ;  bad('GI-002') ).

% Run all three suites and exit non-zero on any failure.
run :-
    nb_setval(fails, 0),
    test_wm, test_hypo, test_goalinfer,
    nb_getval(fails, F),
    ( F =:= 0 -> format("~nALL SNAPSHOT/RESTORE TESTS PASSED~n"), halt(0)
    ; format("~nSOME TESTS FAILED~n"), halt(1) ).

:- initialization(run).
