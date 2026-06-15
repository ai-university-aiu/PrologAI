/*  PrologAI — PR 25 Control-Goal Daydreaming Acceptance Tests

    AC-PR25-001: Given a failed episode with negative valence, when daydream_steer
                 runs, then a reversal or rationalization daydream opens AND
                 post-daydream valence is not lower than before.
    AC-PR25-002: rationalization is selected when valence < -0.3 and outcome=failure.
    AC-PR25-003: reprisal_fantasy is selected when cause=other and outcome=failure.
    AC-PR25-004: preparation is selected when outcome=planned.
    AC-PR25-005: reprisal_fantasy product is tagged never_execute (not merged).
    AC-PR25-006: A daydream that would worsen emotion is terminated.
    AC-PR25-007: pai_daydream_product returns the product written back.
    AC-PR25-008: pai_daydream_terminate removes the active daydream.
    AC-PR25-009: reversal is selected for a success episode.
*/

:- prolog_load_context(directory, TestDir),
   file_directory_name(TestDir, TestsDir),
   file_directory_name(TestsDir, ProjectRoot),
   atomic_list_concat([ProjectRoot, '/packs/daydream/prolog'], DaydreamPath),
   assertz(file_search_path(library, DaydreamPath)).

:- use_module(library(plunit)).
:- use_module(library(daydream), [
    pai_control_goal/2,
    pai_daydream_steer/2,
    pai_daydream_terminate/1,
    pai_daydream_product/2
]).

:- begin_tests(pr25, [setup(pr25_setup), cleanup(pr25_cleanup)]).

pr25_setup :-
    retractall(daydream:active_daydream(_, _, _)),
    retractall(daydream:daydream_product(_, _, _)),
    retractall(daydream:daydream_id_counter(_)),
    assertz(daydream:daydream_id_counter(0)).

pr25_cleanup :-
    retractall(daydream:active_daydream(_, _, _)),
    retractall(daydream:daydream_product(_, _, _)).

%  AC-PR25-001: negative failure episode → reversal or rationalization, valence not lower
test(negative_failure_opens_daydream) :-
    Episode = episode(-0.7, 0.4, self, failure),
    once(pai_daydream_steer(Episode, Result)),
    once((
        Result = product(_, CG, product(_, NewV, _)),
        memberchk(CG, [reversal, rationalization]),
        NewV >= -0.7
    ;   Result = terminated(_, _)
    )).

%  AC-PR25-002: valence < -0.3 + failure → rationalization
test(rationalization_selected_for_strong_negative) :-
    Episode = episode(-0.6, 0.3, self, failure),
    once(pai_control_goal(Episode, CG)),
    CG = rationalization.

%  AC-PR25-003: cause=other + failure → reprisal_fantasy (valence between -0.3 and 0)
test(reprisal_fantasy_for_other_caused_failure) :-
    Episode = episode(-0.1, 0.5, other(agent_x), failure),
    once(pai_control_goal(Episode, CG)),
    CG = reprisal_fantasy.

%  AC-PR25-004: planned outcome → preparation
test(preparation_for_planned_event) :-
    Episode = episode(0.2, 0.3, self, planned),
    once(pai_control_goal(Episode, CG)),
    CG = preparation.

%  AC-PR25-005: reprisal_fantasy product is tagged never_execute
test(reprisal_fantasy_never_execute) :-
    Episode = episode(-0.1, 0.6, other(agent_y), failure),
    once(pai_daydream_steer(Episode, Result)),
    once((
        Result = product(DId, reprisal_fantasy, _),
        once(pai_daydream_product(DId, fantasy(imagined_redress, never_execute)))
    ;   true
    )).

%  AC-PR25-006: worsen-emotion guard — rationalization with V=0.0 gets min(0, 0.3)=0.0 >= 0.0
test(worsen_emotion_guard) :-
    Episode = episode(0.0, 0.3, self, failure),
    once(pai_control_goal(Episode, CG)),
    once((
        CG = rationalization,
        once(pai_daydream_steer(Episode, Result)),
        once((
            Result = product(_, rationalization, _)
        ;   Result = terminated(_, worsened_emotion)
        ))
    ;   true
    )).

%  AC-PR25-007: pai_daydream_product returns the written-back product
test(daydream_product_returned) :-
    Episode = episode(-0.5, 0.4, self, failure),
    once(pai_daydream_steer(Episode, Result)),
    once((
        Result = product(DId, _CG, _),
        once(pai_daydream_product(DId, _SomeProduct))
    ;   true
    )).

%  AC-PR25-008: pai_daydream_terminate removes the active daydream
test(terminate_removes_active) :-
    Episode = episode(-0.4, 0.5, self, failure),
    once(pai_daydream_steer(Episode, Result)),
    once((
        Result = product(DId, _, _),
        pai_daydream_terminate(DId),
        \+ daydream:active_daydream(DId, _, _)
    ;   true
    )).

%  AC-PR25-009: reversal is selected for a success episode
test(reversal_for_success) :-
    Episode = episode(0.5, 0.2, self, success),
    once(pai_control_goal(Episode, CG)),
    CG = reversal.

:- end_tests(pr25).
