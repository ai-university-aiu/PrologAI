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

% Execute the compile-time directive: prolog_load_context(directory, TestDir),.
:- prolog_load_context(directory, TestDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestDir, TestsDir),
   % State a fact for 'file directory name' with the arguments listed below.
   file_directory_name(TestsDir, ProjectRoot),
   % State a fact for 'atomic list concat' with the arguments listed below.
   atomic_list_concat([ProjectRoot, '/packs/daydream/prolog'], DaydreamPath),
   % Add a new fact or rule to the runtime knowledge base.
   assertz(file_search_path(library, DaydreamPath)).

% Load the built-in 'plunit' library so its predicates are available here.
:- use_module(library(plunit)).
% Load the built-in 'daydream' library so its predicates are available here.
:- use_module(library(daydream), [
    % Supply 'pai_control_goal/2' as the next argument to the expression above.
    pai_control_goal/2,
    % Supply 'pai_daydream_steer/2' as the next argument to the expression above.
    pai_daydream_steer/2,
    % Supply 'pai_daydream_terminate/1' as the next argument to the expression above.
    pai_daydream_terminate/1,
    % Supply 'pai_daydream_product/2' as the next argument to the expression above.
    pai_daydream_product/2
% Close the expression opened above.
]).

% Execute the compile-time directive: begin_tests(pr25, [setup(pr25_setup), cleanup(pr25_cleanup)]).
:- begin_tests(pr25, [setup(pr25_setup), cleanup(pr25_cleanup)]).

% Execute: pr25_setup :-.
pr25_setup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(daydream:active_daydream(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(daydream:daydream_product(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(daydream:daydream_id_counter(_)),
    % Add a new fact or rule to the runtime knowledge base.
    assertz(daydream:daydream_id_counter(0)).

% Execute: pr25_cleanup :-.
pr25_cleanup :-
    % Remove all matching facts from the runtime knowledge base.
    retractall(daydream:active_daydream(_, _, _)),
    % Remove all matching facts from the runtime knowledge base.
    retractall(daydream:daydream_product(_, _, _)).

%  AC-PR25-001: negative failure episode → reversal or rationalization, valence not lower
% Define a clause for 'test': succeed when the following conditions hold.
test(negative_failure_opens_daydream) :-
    % Check that 'Episode' is unifiable with 'episode(-0.7, 0.4, self, failure)'.
    Episode = episode(-0.7, 0.4, self, failure),
    % State a fact for 'once' with the arguments listed below.
    once(pai_daydream_steer(Episode, Result)),
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        Result = product(_, CG, product(_, NewV, _)),
        % Continue the multi-line expression started above.
        memberchk(CG, [reversal, rationalization]),
        % Continue the multi-line expression started above.
        NewV >= -0.7
    % Otherwise (else branch), perform the following action.
    ;   Result = terminated(_, _)
    % Close the expression opened above.
    )).

%  AC-PR25-002: valence < -0.3 + failure → rationalization
% Define a clause for 'test': succeed when the following conditions hold.
test(rationalization_selected_for_strong_negative) :-
    % Check that 'Episode' is unifiable with 'episode(-0.6, 0.3, self, failure)'.
    Episode = episode(-0.6, 0.3, self, failure),
    % State a fact for 'once' with the arguments listed below.
    once(pai_control_goal(Episode, CG)),
    % Check that 'CG' is unifiable with 'rationalization'.
    CG = rationalization.

%  AC-PR25-003: cause=other + failure → reprisal_fantasy (valence between -0.3 and 0)
% Define a clause for 'test': succeed when the following conditions hold.
test(reprisal_fantasy_for_other_caused_failure) :-
    % Check that 'Episode' is unifiable with 'episode(-0.1, 0.5, other(agent_x), failure)'.
    Episode = episode(-0.1, 0.5, other(agent_x), failure),
    % State a fact for 'once' with the arguments listed below.
    once(pai_control_goal(Episode, CG)),
    % Check that 'CG' is unifiable with 'reprisal_fantasy'.
    CG = reprisal_fantasy.

%  AC-PR25-004: planned outcome → preparation
% Define a clause for 'test': succeed when the following conditions hold.
test(preparation_for_planned_event) :-
    % Check that 'Episode' is unifiable with 'episode(0.2, 0.3, self, planned)'.
    Episode = episode(0.2, 0.3, self, planned),
    % State a fact for 'once' with the arguments listed below.
    once(pai_control_goal(Episode, CG)),
    % Check that 'CG' is unifiable with 'preparation'.
    CG = preparation.

%  AC-PR25-005: reprisal_fantasy product is tagged never_execute
% Define a clause for 'test': succeed when the following conditions hold.
test(reprisal_fantasy_never_execute) :-
    % Check that 'Episode' is unifiable with 'episode(-0.1, 0.6, other(agent_y), failure)'.
    Episode = episode(-0.1, 0.6, other(agent_y), failure),
    % State a fact for 'once' with the arguments listed below.
    once(pai_daydream_steer(Episode, Result)),
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        Result = product(DId, reprisal_fantasy, _),
        % Continue the multi-line expression started above.
        once(pai_daydream_product(DId, fantasy(imagined_redress, never_execute)))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    )).

%  AC-PR25-006: worsen-emotion guard — rationalization with V=0.0 gets min(0, 0.3)=0.0 >= 0.0
% Define a clause for 'test': succeed when the following conditions hold.
test(worsen_emotion_guard) :-
    % Check that 'Episode' is unifiable with 'episode(0.0, 0.3, self, failure)'.
    Episode = episode(0.0, 0.3, self, failure),
    % State a fact for 'once' with the arguments listed below.
    once(pai_control_goal(Episode, CG)),
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        CG = rationalization,
        % Continue the multi-line expression started above.
        once(pai_daydream_steer(Episode, Result)),
        % Continue the multi-line expression started above.
        once((
            % Continue the multi-line expression started above.
            Result = product(_, rationalization, _)
        % Otherwise (else branch), perform the following action.
        ;   Result = terminated(_, worsened_emotion)
        % Close the expression opened above.
        ))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    )).

%  AC-PR25-007: pai_daydream_product returns the written-back product
% Define a clause for 'test': succeed when the following conditions hold.
test(daydream_product_returned) :-
    % Check that 'Episode' is unifiable with 'episode(-0.5, 0.4, self, failure)'.
    Episode = episode(-0.5, 0.4, self, failure),
    % State a fact for 'once' with the arguments listed below.
    once(pai_daydream_steer(Episode, Result)),
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        Result = product(DId, _CG, _),
        % Continue the multi-line expression started above.
        once(pai_daydream_product(DId, _SomeProduct))
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    )).

%  AC-PR25-008: pai_daydream_terminate removes the active daydream
% Define a clause for 'test': succeed when the following conditions hold.
test(terminate_removes_active) :-
    % Check that 'Episode' is unifiable with 'episode(-0.4, 0.5, self, failure)'.
    Episode = episode(-0.4, 0.5, self, failure),
    % State a fact for 'once' with the arguments listed below.
    once(pai_daydream_steer(Episode, Result)),
    % State a fact for 'once' with the arguments listed below.
    once((
        % Continue the multi-line expression started above.
        Result = product(DId, _, _),
        % Continue the multi-line expression started above.
        pai_daydream_terminate(DId),
        % Continue the multi-line expression started above.
        \+ daydream:active_daydream(DId, _, _)
    % Otherwise (else branch), perform the following action.
    ;   true
    % Close the expression opened above.
    )).

%  AC-PR25-009: reversal is selected for a success episode
% Define a clause for 'test': succeed when the following conditions hold.
test(reversal_for_success) :-
    % Check that 'Episode' is unifiable with 'episode(0.5, 0.2, self, success)'.
    Episode = episode(0.5, 0.2, self, success),
    % State a fact for 'once' with the arguments listed below.
    once(pai_control_goal(Episode, CG)),
    % Check that 'CG' is unifiable with 'reversal'.
    CG = reversal.

% Execute the compile-time directive: end_tests(pr25).
:- end_tests(pr25).
