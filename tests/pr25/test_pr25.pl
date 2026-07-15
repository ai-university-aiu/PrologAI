/*  PrologAI — PR 25 Control-Goal Daydreaming Acceptance Tests
    (rehomed onto the imagination pack)

    The daydream pack was converged into the imagination pack by the
    unification program (absorb-and-supersede; no behaviour lost). The
    mind-wandering faculty is unchanged; only its home and the predicate
    names moved:
        daydream:pai_control_goal/2       -> imagination:imagination_control_goal/2
        daydream:pai_daydream_steer/2     -> imagination:imagination_daydream_steer/2
        daydream:pai_daydream_terminate/1 -> imagination:imagination_daydream_terminate/1
        daydream:pai_daydream_product/2   -> imagination:imagination_daydream_product/2
    The internal state predicates (active_daydream/3, daydream_product/3,
    daydream_id_counter/1) now live in the imagination module.

    AC-PR25-001: Given a failed episode with negative valence, when the daydream
                 is steered, then a reversal or rationalization daydream opens AND
                 post-daydream valence is not lower than before.
    AC-PR25-002: rationalization is selected when valence < -0.3 and outcome=failure.
    AC-PR25-003: reprisal_fantasy is selected when cause=other and outcome=failure.
    AC-PR25-004: preparation is selected when outcome=planned.
    AC-PR25-005: reprisal_fantasy product is tagged never_execute (not merged).
    AC-PR25-006: The worsen-emotion guard holds — a rationalization daydream never
                 leaves valence lower than the seed (kept product, or terminated).
    AC-PR25-007: imagination_daydream_product returns the product written back.
    AC-PR25-008: imagination_daydream_terminate removes the active daydream.
    AC-PR25-009: reversal is selected for a success episode.

    Run with the full library path:
        swipl $LIB -g "run_tests, halt" -t "halt(1)" tests/pr25/test_pr25.pl
*/

% Load the built-in PLUnit test framework so its predicates are available here.
:- use_module(library(plunit)).
% Load the converged imagination module, importing the mind-wandering predicates.
:- use_module(library(imagination), [
    % imagination_control_goal/2: choose a control goal for an episode.
    imagination_control_goal/2,
    % imagination_daydream_steer/2: open a daydream and produce a written-back product.
    imagination_daydream_steer/2,
    % imagination_daydream_terminate/1: close an active daydream by its id.
    imagination_daydream_terminate/1,
    % imagination_daydream_product/2: read back the product of a daydream by id.
    imagination_daydream_product/2
]).

% Open the PR-25 test block, resetting the daydream state before and after the run.
:- begin_tests(pr25, [setup(pr25_setup), cleanup(pr25_cleanup)]).

% Reset the imagination pack's daydream state to a clean slate before the suite.
pr25_setup :-
    % Forget every active daydream held in the imagination module.
    retractall(imagination:active_daydream(_, _, _)),
    % Forget every written-back daydream product held in the imagination module.
    retractall(imagination:daydream_product(_, _, _)),
    % Forget the daydream id counter so it can be seeded deterministically.
    retractall(imagination:daydream_id_counter(_)),
    % Seed the daydream id counter at zero.
    assertz(imagination:daydream_id_counter(0)).

% Tidy up the daydream state left behind after the suite has run.
pr25_cleanup :-
    % Forget every active daydream held in the imagination module.
    retractall(imagination:active_daydream(_, _, _)),
    % Forget every written-back daydream product held in the imagination module.
    retractall(imagination:daydream_product(_, _, _)).

%  AC-PR25-001: negative failure episode -> reversal or rationalization, valence not lower
% Define the test that a negative failure episode opens a mood-repairing daydream.
test(negative_failure_opens_daydream) :-
    % Seed a strongly negative, self-caused failure episode.
    Episode = episode(-0.7, 0.4, self, failure),
    % Steer a daydream from that episode, taking the first solution.
    once(imagination_daydream_steer(Episode, Result)),
    % Accept either a kept product or a guard-driven termination.
    once((
        % The result is a product carrying a control goal and a new valence.
        Result = product(_, CG, product(_, NewV, _)),
        % The control goal is one of the mood-repairing kinds.
        memberchk(CG, [reversal, rationalization]),
        % The new valence is not lower than the seed valence.
        NewV >= -0.7
    % Otherwise the daydream was terminated by the worsen-emotion guard.
    ;   Result = terminated(_, _)
    )).

%  AC-PR25-002: valence < -0.3 + failure -> rationalization
% Define the test that a strong-negative failure selects rationalization.
test(rationalization_selected_for_strong_negative) :-
    % Seed a strongly negative, self-caused failure episode.
    Episode = episode(-0.6, 0.3, self, failure),
    % Ask which control goal the episode selects, taking the first solution.
    once(imagination_control_goal(Episode, CG)),
    % Confirm the selected control goal is rationalization.
    CG = rationalization.

%  AC-PR25-003: cause=other + failure -> reprisal_fantasy
% Define the test that an other-caused failure selects reprisal_fantasy.
test(reprisal_fantasy_for_other_caused_failure) :-
    % Seed a mildly negative failure blamed on another agent.
    Episode = episode(-0.1, 0.5, other(agent_x), failure),
    % Ask which control goal the episode selects, taking the first solution.
    once(imagination_control_goal(Episode, CG)),
    % Confirm the selected control goal is reprisal_fantasy.
    CG = reprisal_fantasy.

%  AC-PR25-004: planned outcome -> preparation
% Define the test that a planned outcome selects preparation.
test(preparation_for_planned_event) :-
    % Seed a mildly positive, self-caused planned episode.
    Episode = episode(0.2, 0.3, self, planned),
    % Ask which control goal the episode selects, taking the first solution.
    once(imagination_control_goal(Episode, CG)),
    % Confirm the selected control goal is preparation.
    CG = preparation.

%  AC-PR25-005: reprisal_fantasy product is tagged never_execute
% Define the test that a reprisal fantasy is written back tagged never_execute.
test(reprisal_fantasy_never_execute) :-
    % Seed a mildly negative failure blamed on another agent.
    Episode = episode(-0.1, 0.6, other(agent_y), failure),
    % Steer a daydream from that episode, taking the first solution.
    once(imagination_daydream_steer(Episode, Result)),
    % The result is a reprisal_fantasy product carrying its daydream id.
    Result = product(DId, reprisal_fantasy, _),
    % The written-back product for that id is the imagined redress marked never_execute.
    once(imagination_daydream_product(DId, fantasy(imagined_redress, never_execute))).

%  AC-PR25-006: worsen-emotion guard — a rationalization daydream never lowers valence
% Define the test that the worsen-emotion guard keeps valence at or above the seed.
test(worsen_emotion_guard) :-
    % Seed a negative, self-caused failure that selects rationalization.
    Episode = episode(-0.4, 0.3, self, failure),
    % Confirm this episode really does select rationalization.
    once(imagination_control_goal(Episode, CG)),
    % The selected control goal must be rationalization for this guard test.
    CG == rationalization,
    % Steer the daydream from that episode, taking the first solution.
    once(imagination_daydream_steer(Episode, Result)),
    % The guard either keeps a product whose valence is not lower, or terminates.
    once((
        % A kept rationalization product carries a new valence.
        Result = product(_, rationalization, product(_, NewV, _)),
        % That new valence is not lower than the seed valence.
        NewV >= -0.4
    % Otherwise the guard terminated the daydream for worsening emotion.
    ;   Result = terminated(_, worsened_emotion)
    )).

%  AC-PR25-007: imagination_daydream_product returns the written-back product
% Define the test that a steered daydream's product can be read back by id.
test(daydream_product_returned) :-
    % Seed a negative, self-caused failure episode.
    Episode = episode(-0.5, 0.4, self, failure),
    % Steer a daydream from that episode, taking the first solution.
    once(imagination_daydream_steer(Episode, Result)),
    % The result is a product carrying its daydream id.
    Result = product(DId, _CG, _),
    % A product for that id was written back and can be retrieved.
    once(imagination_daydream_product(DId, _SomeProduct)).

%  AC-PR25-008: imagination_daydream_terminate removes the active daydream
% Define the test that terminating a daydream removes its active record.
test(terminate_removes_active) :-
    % Seed a negative, self-caused failure episode.
    Episode = episode(-0.4, 0.5, self, failure),
    % Steer a daydream from that episode, taking the first solution.
    once(imagination_daydream_steer(Episode, Result)),
    % The result is a product carrying its daydream id.
    Result = product(DId, _, _),
    % Terminate the daydream by that id.
    imagination_daydream_terminate(DId),
    % Confirm no active daydream remains under that id.
    \+ imagination:active_daydream(DId, _, _).

%  AC-PR25-009: reversal is selected for a success episode
% Define the test that a success episode selects reversal.
test(reversal_for_success) :-
    % Seed a positive, self-caused success episode.
    Episode = episode(0.5, 0.2, self, success),
    % Ask which control goal the episode selects, taking the first solution.
    once(imagination_control_goal(Episode, CG)),
    % Confirm the selected control goal is reversal.
    CG = reversal.

% Close the PR-25 test block.
:- end_tests(pr25).
